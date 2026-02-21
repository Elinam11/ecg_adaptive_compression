----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/12/2026 06:41:03 PM
-- Design Name: 
-- Module Name: kEstimator - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity kEstimator2 is
  Port ( Counter: in integer;
         Clock: in std_logic; 
         K_ready: out std_logic; 
         K: out integer range 0  to 15;
         bram_addr_in : in STD_LOGIC_VECTOR(16 downto 0);
         bram_data_out : out STD_LOGIC_VECTOR(15 downto 0);
         bram_ena_in : in std_logic);
end kEstimator2;

architecture Behavioral of kEstimator2 is
    COMPONENT bram_ecg IS
      PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        clkb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addrb : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
        dinb : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
      );
    END COMPONENT bram_ecg;

    
    component mappingToUnsigned is
        Port ( A : in signed (15 downto 0);
               Z : out unsigned (15 downto 0));
    end component mappingToUnsigned;
    
-- function to get log2 value

function first_one (vec: std_logic_vector)  return integer is
begin   
    for i in vec'high downto vec'low loop   
        if vec(i) = '1' then 
            return i;
        end if; 
     end loop;
     return 0;
end function; 

    function pos_value (error: signed)  return unsigned is
       
        variable M_n_interimf : signed(16 downto 0);
        variable Z_interimf : unsigned(16 downto 0);
        variable v_M_n_posf : unsigned(16 downto 0);
        begin
        M_n_interimf := resize(error,17);
        if (M_n_interimf  >= 0) then
            Z_interimf := unsigned(shift_left(M_n_interimf,1)); -- positive no
        
        else  
            Z_interimf := unsigned(shift_left(-M_n_interimf,1)-1);  -- neg no
        
        end if;
    
        v_M_n_posf := resize(Z_interimf,16);
        return v_M_n_posf;
    end function;
    
-- BRAM signals A 
signal  dina_1, douta_1 : std_logic_vector (15 downto 0);
signal wea_1: std_logic_vector(0 DOWNTO 0):= "0";
signal addra_1: STD_LOGIC_VECTOR (16 downto 0):=(others => '0');
signal  E: std_logic:= '0';

-- BRAM signals B
signal  dinb_1, doutb_1 : std_logic_vector (15 downto 0);
signal web_1: std_logic_vector(0 DOWNTO 0):= "0";
signal addrb_1: STD_LOGIC_VECTOR (16 downto 0):=(others => '0');
signal  E_b: std_logic:= '0';

-- internal computation
signal K_reg: integer range 0  to 15 := 0;
signal avg: unsigned (25 downto 0):=(others => '0');
signal predictedO : signed(15 downto 0);
 signal sampleShifted: signed(15 downto 0) ;
signal  M_n_pos : unsigned(15 downto 0);
signal  M_n : signed(15 downto 0);
    
-- for storing past 2 samples
type b16array3 is array(2 downto 0) of std_logic_vector(15 downto 0);
signal temp_buffer:  b16array3;

-- state machine for k estimation
type state_type is (IDLE, READY, ACCUMULATE, COMPUTE, DONE);
signal state: state_type := IDLE;

-- address counter for iterating through BRAM
signal addr_count: unsigned (16 downto 0):=(others => '0');
signal sum_sig:unsigned(25 downto 0) := (others => '0');


signal valid_pipe: std_logic_vector(2 downto 0):= (others => '0');

begin
    ram: bram_ecg port map(clka=>Clock,
                        wea => wea_1,
                        ena => E,
                        addra => addra_1,
                        dina => dina_1,
                        douta => douta_1,
                        clkb => Clock,
                        enb => E_b,
                        web => web_1,
                        addrb => addrb_1,
                        dinb => dinb_1,
                        doutb => doutb_1);
     Positive_num: mappingToUnsigned port map( A => M_n,
                                              Z => M_n_pos);
                                              
     K <= K_reg;
     
     process(Clock)
        variable sum_abs_errors : unsigned(25 downto 0) := (others => '0');
        variable abs_error : unsigned(15 downto 0);
        variable read_addr : unsigned(16 downto 0)  := (others => '0');
        variable write_addr : unsigned(16 downto 0)  := (others => '0');
        variable cycle_count : integer range  0 to 1100 := 0;
        variable v_sampleShifted: signed(15 downto 0);
        variable v_predictedO: signed(15 downto 0);
        variable v_M_n: signed(16 downto 0);
        variable v_M_n_pos: unsigned(15 downto 0);
        variable M_n_interim : signed(16 downto 0);
        variable Z_interim : unsigned(16 downto 0);
        variable v_current : signed(15 downto 0);
        variable v_predicted : signed(15 downto 0);
        variable v_error : signed(16 downto 0);
        
        begin
        
        if rising_edge(Clock) then
            case state is
                 when IDLE =>
                     E <= '0'; -- bram not enable
                     E_b <= '0';
                     web_1 <= "0";
                     K_ready <= '0';
                     temp_buffer <= (others =>(others => '0')) ;
                     dinb_1 <= (others => '0');
                     read_addr := (others => '0');
                     write_addr := (others => '0');
                     cycle_count:= 0;
                     sum_abs_errors := (others => '0');
                     valid_pipe <= (others => '0');
                     
                     if Counter = 0 then    
                        state <= READY;
                     end if;
                 
                 when READY =>
                    E <= '1'; -- read enable
                    E_b <= '0';
                    web_1 <= "0";
                    K_ready <= '0';
                    
                    addra_1 <= std_logic_vector(read_addr);
                    -- ADD THIS:
  report "READY: reading addr=" & integer'image(to_integer(read_addr))
    severity note;
    
                    if read_addr < 1023 then
                        read_addr:= read_addr + 1;
                    end if;
                    
                    cycle_count := cycle_count + 1;    

                    if cycle_count >= 4 then
                        state <= COMPUTE;
                    end if;
                
                when COMPUTE =>
                
                cycle_count := cycle_count + 1;  -- 2
              
    
                if read_addr <= 1023 then  -- Changed < to <=
                    E <= '1';
                    wea_1 <= "0";
                    addra_1 <= std_logic_vector(read_addr);
                    
                    if read_addr < 1023 then
                        read_addr := read_addr + 1;
                    end if;
                else
                    E <= '0';  -- Stop reading
                    wea_1 <= "0";
                end if;
                 
                if cycle_count >= 5 and write_addr < 15 then
                    report "WRITE: addr=" & integer'image(to_integer(write_addr)) & 
                           " data=" & integer'image(to_integer(v_M_n_pos)) &
                           " E_b=" & std_logic'image(E_b) &
                           " web=" & std_logic'image(web_1(0)) severity note;
                end if;
                
                valid_pipe <= valid_pipe(1 downto 0) & '1'; 
                
               if valid_pipe(2) = '1' and write_addr < 10 then
    report "===== ADDR CHECK =====" severity note;
    report "write_addr=" & integer'image(to_integer(write_addr)) severity note;
    report "read_addr=" & integer'image(to_integer(read_addr)) severity note;
    report "v_current=" & integer'image(to_integer(v_current)) severity note;
    report "Expected from COE:" severity note;
    case to_integer(write_addr) is
        when 0 => report "  Should be -428 (0xFE54)" severity note;
        when 1 => report "  Should be -379 (0xFE85)" severity note;
        when 2 => report "  Should be -333 (0xFEB3)" severity note;
        when 3 => report "  Should be -289 (0xFEDF)" severity note;
        when 4 => report "  Should be -249 (0xFF07)" severity note;
        when others => null;
    end case;
end if;

                 
                 if valid_pipe(2) = '1' then  
                -- Linear 2nd Order Predictor       
                    -- pass into predictor
                     v_current := signed(douta_1);
                     
                     -- Debug what we're reading
  report "write_addr=" & integer'image(to_integer(write_addr)) & 
         " v_current=" & integer'image(to_integer(v_current))
    severity note;
    
                    if write_addr < 2 then
                    v_M_n_pos:= pos_value(resize(v_current, 17));
                    temp_buffer(to_integer(write_addr)) <= std_logic_vector(v_current);
                    
                    else
                    v_sampleShifted := shift_left(signed(temp_buffer(2)),1);
                    v_predictedO := v_sampleShifted - signed(temp_buffer(1));
                    -- calculate error from predicted and current
                    v_M_n := resize(v_current, 17) - resize(v_predictedO, 17);
               report "PREDICT[" & integer'image(to_integer(write_addr)) & 
               "] current=" & integer'image(to_integer(v_current)) &
               " predicted=" & integer'image(to_integer(v_predictedO)) &
               " error=" & integer'image(to_integer(v_M_n))
          severity note;
          
                    temp_buffer(0) <= temp_buffer(1);
                    temp_buffer(1) <= temp_buffer(2); 
                    temp_buffer(2) <= std_logic_vector(v_current) ;
    
                    end if;
                    
                    
                    
       
                    -- map to unsigned
                    M_n_interim := resize(v_M_n,17);
                    if (M_n_interim  >= 0) then
                        Z_interim := unsigned(shift_left(M_n_interim,1)); -- positive no
                    
                    else  
                        Z_interim := unsigned(shift_left(-M_n_interim,1)-1);  -- neg no
                    
                    end if;
                
                    v_M_n_pos := resize(Z_interim,16);
                    report "  mapped=" & integer'image(to_integer(v_M_n_pos))
          severity note;
          

 
                -- write back to memory 
                E_b <= '1'; -- bram not enable
                web_1 <= "1";
               
                addrb_1 <= std_logic_vector(write_addr);
                dinb_1 <= std_logic_vector(v_M_n_pos);
            
                -- done pointer for first k calculation
            
                sum_abs_errors := sum_abs_errors + v_M_n_pos;
                
                if write_addr < 1023 then
                write_addr := write_addr + 1;
                end if;
                        
                        if write_addr < 15 then
                            report "WRITE: addr=" & integer'image(to_integer(write_addr)) & 
                                   " data=" & integer'image(to_integer(v_M_n_pos)) &
                                   " E_b=" & std_logic'image(E_b) &
                                   " web=" & std_logic'image(web_1(0)) severity note;
                        end if;
            
                    else 
                        E_b <= '0'; -- bram not enable
                        web_1 <= "0";
                        
                    end if;
                    
                    
                    

                    if cycle_count >= 1031 then  
                        state <= ACCUMULATE;            
                    end if;
                            
                            
                                         
                      
                  when ACCUMULATE =>
                  
                    E_b <= '0';
                    web_1 <= "0";
                    K_ready <= '0';
                    E <='0';  
                    
                    cycle_count := cycle_count + 1; 
                    report "=== K ESTIMATION ===" severity note;
                    report "Sum (decimal): " & integer'image(to_integer(sum_abs_errors)) severity note;
                   
                    -- rake average
                    if cycle_count >= 1055 then
                    report "Avg (decimal): " & integer'image(to_integer(avg)) severity note;
                        sum_sig <= sum_abs_errors;
                        avg <= shift_right(sum_abs_errors, 10);
                        state <= DONE;
                    end if;
                    
                    
    
                    
                  when DONE =>
                    K_ready <= '1';
                    K_reg <= first_one(std_logic_vector(avg));
                    E_b <= '0';
                    web_1 <= "0";
                    -- allow external access
                    if bram_ena_in = '1' then
                        addra_1 <= bram_addr_in;
                        E <= '1';
                        wea_1 <= "0";
                        bram_data_out <= douta_1;
                     else
                        E<= '0';
                    end if;
                    
                    if Counter /= 0 then
                        state <= IDLE;
                    end if;
         end case;
                  
        end if;
     end process;

end Behavioral;
