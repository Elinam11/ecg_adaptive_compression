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

entity kEstimator is
  Port ( Counter: in integer;
         Clock: in std_logic; 
         K_ready: out std_logic; 
         K: out integer range 0  to 15);
end kEstimator;

architecture Behavioral of kEstimator is
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
        variable v_M_n: signed(15 downto 0);
        variable v_M_n_pos: unsigned(15 downto 0);
        variable M_n_interim : signed(16 downto 0);
        variable Z_interim : unsigned(16 downto 0);
        
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
                     
                     if Counter = 0 then    
                        state <= READY;
                     end if;
                 
                 when READY =>
                    E <= '1'; -- read enable
                    E_b <= '0';
                    web_1 <= "0";
                    K_ready <= '0';
                    
                    addra_1 <= std_logic_vector(read_addr);
                    
                    if read_addr < 1023 then
                        read_addr:= read_addr + 1;
                    end if;
                    
                    cycle_count := cycle_count + 1;    

                    if cycle_count >= 4 then
                        state <= COMPUTE;
                    end if;
                
                when COMPUTE =>
                
                cycle_count := cycle_count + 1; 
                
                E <= '1';
                addra_1 <= std_logic_vector(read_addr);
                    
                if read_addr < 1023 then
                    read_addr:= read_addr + 1;
                end if;
                    
                if cycle_count >= 2 and cycle_count < 1026 then
                    temp_buffer(0) <= temp_buffer(1) ;
                    temp_buffer(1) <= temp_buffer(2);
                    temp_buffer(2) <= douta_1;
               
                END IF;      
                -- Linear 2nd Order Predictor       
                    -- pass into predictor
                    v_sampleShifted := shift_left(signed(temp_buffer(2)),1);
                    v_predictedO := v_sampleShifted - signed(temp_buffer(1));
                    -- calculate error from predicted and current
                    v_M_n := signed(temp_buffer(0)) - v_predictedO;
                    
                    
                    -- map to unsigned
                    M_n_interim := resize(v_M_n,17);
                    if (M_n_interim  >= 0) then
                        Z_interim := unsigned(shift_left(M_n_interim,1)); -- positive no
                    
                    else  
                        Z_interim := unsigned(shift_left(-M_n_interim,1)-1);  -- neg no
                    
                    end if;
                
                    v_M_n_pos := resize(Z_interim,16);


                    sampleShifted <= v_sampleShifted;
                    predictedO <= v_predictedO;
                    M_n <= v_M_n;
                    M_n_pos <= v_M_n_pos;
                    
                    -- write back to memory 
                    E_b <= '1'; -- bram not enable
                    web_1 <= "1";
                    addrb_1 <= std_logic_vector(write_addr);
                    if cycle_count >= 5 then
                        dinb_1 <= std_logic_vector(v_M_n_pos);
                    end if;
                    
                    if write_addr < 1023 then
                        write_addr:= write_addr + 1;
                    end if;
                    
                    
                    -- done pointer for first k calculation
                    if cycle_count > 5 then
                        sum_abs_errors := sum_abs_errors + v_M_n_pos;
                    end if;

                    if cycle_count >= 1026 then  
                        state <= ACCUMULATE;            
                    end if;
                            
                            
                                         
                      
                  when ACCUMULATE =>
                  
                    E_b <= '0';
                    web_1 <= "0";
                    K_ready <= '0';
                    E <='0';      
                    -- rake average
                    avg <= shift_right(sum_abs_errors, 10);
                    state <= DONE;
                    
                  when DONE =>
                    K_ready <= '1';
                    K_reg <= first_one(std_logic_vector(avg));
                    
                    if Counter /= 0 then
                        state <= IDLE;
                    end if;
         end case;
                  
        end if;
     end process;

end Behavioral;
