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
use work.types_pkg.all;
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
         addr_start : in std_logic_vector(16 DOWNTO 0);
         K_ready: out std_logic; 
         K: out integer range 0  to 15;
         total_bits : out integer; -- gc
         samples_done : out integer;
         compression_done: out std_logic;
         encoded_array: out output_array;
         encoded_array_valid: out std_logic; --gc
         M_errors: out output_array);
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
        variable v_M_n_posf : unsigned(15 downto 0);
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
type state_type is (IDLE, READY, ACCUMULATE, COMPUTE, GOLOMB_R, ENCODE, DONE);
signal state: state_type := IDLE;

-- address counter for iterating through BRAM
signal addr_count: unsigned (16 downto 0):=(others => '0');
signal sum_sig:unsigned(25 downto 0) := (others => '0');


-- compression tracking
signal total_bits_reg: integer := 0;
signal samples_done_reg : integer := 0;
signal comp_done : std_logic := '0';
    
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
     
                                              
    K <= K_reg;
    total_bits <= total_bits_reg;
    samples_done <= samples_done_reg;
    compression_done <= comp_done;
     
     process(Clock)
        variable sum_abs_errors : unsigned(25 downto 0) := (others => '0');
        variable abs_error : unsigned(15 downto 0);
        variable read_addr : unsigned(16 downto 0)  := (others => '0');
        variable write_count : unsigned(16 downto 0)  := (others => '0');
        variable cycle_count : integer range  0 to 1100 := 0;
        variable v_sampleShifted: signed(15 downto 0);
        variable v_predictedO: signed(15 downto 0);
        variable v_M_n: signed(16 downto 0);
        variable vgc_M_n: unsigned(15 downto 0); -- gc
        variable Counter_var : integer := 0; 
        variable pa_K : integer range 0 to 15  :=0;
        variable bits_used : integer:= 0;
        variable Q , R,  M_n0: std_logic_vector (15 downto 0) :=(others => '0'); --gc
        variable encode_count: integer := 0;
        variable v_M_n_pos: unsigned(15 downto 0);
        variable M_n_interim : signed(16 downto 0);
        variable Z_interim : unsigned(16 downto 0);
        variable v_current : signed(15 downto 0);
        variable v_predicted : signed(15 downto 0);
        variable v_error : signed(16 downto 0);
        variable M_n_errors: output_array:=(others => (others => '0'));
        variable sample_index : integer := 0; 
        variable encoded_val : unsigned(15 downto 0);
        variable encoded_array_var : output_array := (others => (others => '0'));
        
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
                     write_count := (others => '0');
                     cycle_count:= 0;
                     sum_abs_errors := (others => '0');
                     valid_pipe <= (others => '0');
                     
                     
                     -- golomb rice 
                     total_bits_reg <= 0;
                     samples_done_reg  <= 0;
                     sample_index := 0;  -- RESET
                     for i in 0 to 1023 loop
                        encoded_array_var(i) := (others => '0');
                     end loop;
                     encoded_array_valid <= '0';
                     
                     if Counter = 0 then  
                        read_addr:= unsigned(addr_start);
                        state <= READY;
                     end if;
                
                when READY =>
                    E <= '1';
                    E_b <= '0';
                    web_1 <= "0";
                    addra_1 <= std_logic_vector(read_addr);
                    read_addr := read_addr + 1;
                    cycle_count := cycle_count + 1;
                    
                    -- Just fill BRAM pipeline (2 cycles)
                    if cycle_count >= 3 then
                        state <= COMPUTE;
                    end if;

            when COMPUTE =>
                -- Read continuously
                if read_addr <= 1023 then
                    E <= '1';
                    addra_1 <= std_logic_vector(read_addr);
                    read_addr := read_addr + 1;
                else
                    E <= '0';
                end if;
                
                -- Process current data (always valid after READY)
                v_current := signed(douta_1);
                
                -- first 2 errors are raw samples since buffer is not full for computation
                if write_count < 2 then
                    v_M_n_pos := pos_value(resize(v_current, 17));
                    temp_buffer(to_integer(write_count)) <= std_logic_vector(v_current);
                    
                    report "=== CHECK ===" severity note;
                    report "ERROR1: " & integer'image(to_integer(v_M_n_pos)) severity note;
                else
                -- 2nd order linear predictor
                    v_sampleShifted := shift_left(signed(temp_buffer(1)), 1);
                    v_predictedO := v_sampleShifted - signed(temp_buffer(0));
                    v_M_n := resize(v_current, 17) - resize(v_predictedO, 17);
                    v_M_n_pos := pos_value(v_M_n);
                    temp_buffer(0) <= temp_buffer(1);
                    temp_buffer(1) <= std_logic_vector(v_current);
                end if;
                
                M_n_errors(to_integer(write_count)):= v_M_n_pos;
                
                
                sum_abs_errors := sum_abs_errors + v_M_n_pos;
                write_count := write_count + 1;
                
                -- errors are computed for current window
                if write_count >= 1024 then
                    M_errors <= M_n_errors;
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
                   
                    -- take average
                    if cycle_count >= 1055 then
                    report "Avg (decimal): " & integer'image(to_integer(avg)) severity note;
                        sum_sig <= sum_abs_errors;
                        avg <= shift_right(sum_abs_errors, 10);
                        state <= GOLOMB_R;
                    end if;
 
             when GOLOMB_R =>
                K_reg <= first_one(std_logic_vector(avg));
                K_ready <= '1'; 
                encode_count := 0;
                state <= ENCODE;
                      
             when ENCODE =>
             -- Golomb Rice Encoder          
             -- take computed errors and k
                vgc_M_n := M_n_errors(encode_count);  
                pa_K := K_reg;        
                
                -- find q and r 
                Q :=  std_logic_vector(shift_right(vgc_M_n , pa_K));
                M_n0 := std_logic_vector(vgc_M_n);
                -- mask lower bits
                R := std_logic_vector(vgc_M_n and shift_right(unsigned(not(std_logic_vector(to_unsigned(0,16)))) , 16 - pa_K)) ;
                
                -- output error
                
                encoded_val := shift_left(resize(vgc_M_n,32 ), pa_K + 1)(15 downto pa_K + 1) & to_unsigned(0,1) & unsigned(R(pa_K - 1 downto 0));
                --encodedE <= encoded_val;
                
                if sample_index < 1024 then
                encoded_array_var(sample_index) := shift_left(resize(vgc_M_n,32 ), pa_K + 1)(15 downto pa_K + 1) & to_unsigned(0,1) & unsigned(R(pa_K - 1 downto 0));
                end if;
                
                -- DEBUG: Report what you're encoding
                if cycle_count <= 10 then  -- First 10 samples only
                    report "Sample " & integer'image(sample_index) & 
                           ": M_n=" & integer'image(to_integer(M_n)) & 
                           " Q=" & integer'image(to_integer(unsigned(Q))) &
                           " encoded= "  & integer'image(to_integer(encoded_val))&
                           " bits=" & integer'image(bits_used) severity note;
                end if;
    
                -- compression measurement
                bits_used := to_integer(unsigned(Q)) + 1 + pa_K;
                total_bits_reg <= total_bits_reg + bits_used;
                samples_done_reg <= samples_done_reg + 1;
                sample_index := sample_index + 1;
    

                -- store error
        
                -- put in function to say unless 123
                if encode_count = 1023 then
                    -- send in next k function by seting counter in component
                    Counter_var := 0 ;
                    state <= DONE;
               
                end if; 
                
                Counter_var := Counter_var + 1;
                encode_count := encode_count + 1;
                    
                  when DONE =>
                    
                    E_b <= '0';
                    web_1 <= "0";
                    comp_done <= '1';
                    
                    if Counter /= 0 then
                        state <= IDLE;
                    end if;
         end case;
                  
        end if;
     end process;

end Behavioral;