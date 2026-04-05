----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/07/2026 07:39:23 PM
-- Design Name: 
-- Module Name: losslessComp - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity losslessComp is
  Port ( Counter: in std_logic;
         Clock: in std_logic; 
         segment_count : in integer;
         raw_samples : in samples_array;
         K_ready: out std_logic; 
         K: out integer range 0  to 15;
         total_bits : out integer; -- gc
         samples_done : out integer;
         compression_done: out std_logic;
         encoded_array: out output_larray;
         encoded_array_valid: out std_logic --gc
         );
end losslessComp;

architecture Behavioral of losslessComp is
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
    
    function encode_gc(vM_n: unsigned; k: integer) return unsigned is 
    variable Q , R,M_n0: std_logic_vector (15 downto 0) :=(others => '0'); --gc
    variable encoded_val : unsigned(15 downto 0);
    variable pa_K : integer range 0 to 15  :=0;
        begin
        pa_K := k;
        case k is
        when 0 =>
            encoded_val := shift_left(resize(vM_n,32 ), (1 ))(15 downto (1 )) & to_unsigned(0,1);
        when 1 =>
            -- mask lower bits
             R := std_logic_vector(vM_n and shift_right(unsigned(not(std_logic_vector(to_unsigned(0,16)))) , 15)) ;
             encoded_val := shift_left(resize(vM_n,32 ), (2))(15 downto 2) & to_unsigned(0,1) & unsigned(R(0 downto 0));
        when 2 =>
             R := std_logic_vector(vM_n and shift_right(unsigned(not(std_logic_vector(to_unsigned(0,16)))) , 14)) ;
             encoded_val := shift_left(resize(vM_n,32 ), (3))(15 downto 3) & to_unsigned(0,1) & unsigned(R(1 downto 0));
        when 3 =>
             R := std_logic_vector(vM_n and shift_right(unsigned(not(std_logic_vector(to_unsigned(0,16)))) , 13)) ;
             encoded_val := shift_left(resize(vM_n,32 ), (4))(15 downto 4) & to_unsigned(0,1) & unsigned(R(2 downto 0));
        when 4 =>
             R := std_logic_vector(vM_n and shift_right(unsigned(not(std_logic_vector(to_unsigned(0,16)))) , 12)) ;
             encoded_val := shift_left(resize(vM_n,32 ), (5))(15 downto 5) & to_unsigned(0,1) & unsigned(R(3 downto 0));
        when 5 =>
             R := std_logic_vector(vM_n and shift_right(unsigned(not(std_logic_vector(to_unsigned(0,16)))) , 11)) ;
             encoded_val := shift_left(resize(vM_n,32 ), (6))(15 downto 6) & to_unsigned(0,1) & unsigned(R(4 downto 0));
        when 6 =>
             R := std_logic_vector(vM_n and shift_right(unsigned(not(std_logic_vector(to_unsigned(0,16)))) , 10)) ;
             encoded_val := shift_left(resize(vM_n,32 ), (7))(15 downto 7) & to_unsigned(0,1) & unsigned(R(5 downto 0));
        when 7 =>
             R := std_logic_vector(vM_n and shift_right(unsigned(not(std_logic_vector(to_unsigned(0,16)))) ,9 )) ;
             encoded_val := shift_left(resize(vM_n,32 ), (8))(15 downto 8) & to_unsigned(0,1) & unsigned(R(6 downto 0));
        when 8 =>
             R := std_logic_vector(vM_n and shift_right(unsigned(not(std_logic_vector(to_unsigned(0,16)))) , 8)) ;
             encoded_val := shift_left(resize(vM_n,32 ), (9))(15 downto 9) & to_unsigned(0,1) & unsigned(R(7 downto 0));
        when 9 =>
             R := std_logic_vector(vM_n and shift_right(unsigned(not(std_logic_vector(to_unsigned(0,16)))) , 7)) ;
             encoded_val := shift_left(resize(vM_n,32 ), (10))(15 downto 10) & to_unsigned(0,1) & unsigned(R(8 downto 0));
        when others =>
            encoded_val:= (others => '0');
        end case;
        return encoded_val;
    end function;
                
-- for k estimation average
constant RECIP_72 : unsigned  (15 downto 0) := x"038E";  -- 910 in hex
signal M_errors: output_larray;
    
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
        variable M_n_errors: output_larray:=(others => (others => '0'));
        variable sample_index : integer := 0; 
        variable encoded_val : unsigned(15 downto 0);
        variable encoded_array_var : output_larray := (others => (others => '0'));
        variable product_temp : unsigned (41 downto 0); 
        variable qrs_samples : samples_array := (others => (others => '0'));
        VARIABLE reported : std_logic := '0';
        
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
                     qrs_samples :=  (others =>(others => '0')) ;
                     
                     -- golomb rice 
                     total_bits_reg <= 0;
                     samples_done_reg  <= 0;
                     sample_index := 0;  -- RESET
                     for i in 0 to 71 loop
                        encoded_array_var(i) := (others => '0');
                        encoded_array(i) <= (others => '0');
                     end loop;
                     encoded_array_valid <= '0';
                     
                     if Counter = '1' then  
                        -- read_addr:= unsigned(addr_start);       !!!!!!!!!!!!!
                        state <= READY;
                     end if;
                
                when READY =>
                    --E <= '1';
                    --E_b <= '0';
                    --web_1 <= "0";
                    --addra_1 <= std_logic_vector(read_addr);
                    --read_addr := read_addr + 1;
                    cycle_count := cycle_count + 1;
                    
                    if cycle_count = 1 then
                    for i in 0 to 71 loop
                    qrs_samples(i) := raw_samples(i);
                    end loop;
                    cycle_count := 0 ;
                    state <= COMPUTE;
                    end if;
                    
                    -- Just fill BRAM pipeline (2 cycles)
                    
                    
                    

            when COMPUTE =>
                -- Read continuously
                --if read_addr <= 1023 then
                --    E <= '1';
                --    addra_1 <= std_logic_vector(read_addr);
                --    read_addr := read_addr + 1;
                --else
                --    E <= '0';
                --end if;
                
                -- Process current data (always valid after READY)
                v_current := qrs_samples(to_integer(write_count));
                
                -- first 2 errors are raw samples since buffer is not full for computation
                if write_count < 2 then
                    v_M_n_pos := pos_value(resize(v_current, 17));
                    temp_buffer(to_integer(write_count)) <= std_logic_vector(v_current);
                    report "RAW_SAMPLE[" & integer'image(to_integer(write_count)) & 
                   "]=" & integer'image(to_integer(v_current)) &
                   " pos_value=" & integer'image(to_integer(v_M_n_pos)) severity note;
                    
                    
                    report "=== CHECK ===" severity note;
                    report "ERROR1: " & integer'image(to_integer(v_M_n_pos)) severity note;
                else
                
                -- 2nd order linear predictor
                v_sampleShifted := shift_left(signed(temp_buffer(1)), 1);
                v_predictedO := v_sampleShifted - signed(temp_buffer(0));
                v_M_n := resize(v_current, 17) - resize(v_predictedO, 17);
                v_M_n_pos := pos_value(v_M_n);
                temp_buffer(0) <= temp_buffer(1);
                temp_buffer(1)<= std_logic_vector(v_current);
                    
                    
                end if;
                
                M_n_errors(to_integer(write_count)):= v_M_n_pos;
                
                -- in COMPUTE state, after calculating v_M_n_pos
                report "SEG_MN[" & integer'image(segment_count) &
                       "][" & integer'image(to_integer(write_count)) & "]=" &
                       integer'image(to_integer(v_M_n_pos)) severity note;
                
                sum_abs_errors := sum_abs_errors + v_M_n_pos;
                write_count := write_count + 1;
                
                -- errors are computed for current window
                if write_count >= 72 then
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
                    if cycle_count >= 103 then   -- check if 1055
                    report "Avg (decimal): " & integer'image(to_integer(avg)) severity note;
                        sum_sig <= sum_abs_errors;
                        --avg <= shift_right(sum_abs_errors, 10);
                        product_temp := sum_abs_errors * RECIP_72 ;
                        avg <= product_temp(41 downto 16);
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
                -- output error
                encoded_val := encode_gc(vgc_M_n, K_reg);
                
                --encodedE <= encoded_val;
                
                if sample_index < 72 then
                encoded_array_var(sample_index) := encoded_val;
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
                if encode_count = 71 then
                    -- send in next k function by seting counter in component
                    Counter_var := 0 ;
                    state <= DONE;
               
                end if; 
                
                Counter_var := Counter_var + 1;
                encode_count := encode_count + 1;
                    
                  when DONE =>
                    encoded_array <= encoded_array_var;
                    E_b <= '0';
                    web_1 <= "0";
                    comp_done <= '1';
                    
                    -- print all encoded values to transcript
                    if reported = '0' then      -- only report once
                        for i in 0 to 71 loop
                            report "SEG_ENCODED[" & integer'image(segment_count) &
                                   "][" & integer'image(i) & "]=" &
                                   integer'image(to_integer(encoded_array_var(i))) severity note;
                        end loop;
                        report "SEG_K[" & integer'image(segment_count) & "]=" &
                               integer'image(K_reg) severity note;
                        reported := '1';
                    end if;
                    if Counter = '0' then
                        reported := '0';
                        state <= IDLE;
                    end if;
         end case;
                  
        end if;
     end process;

end Behavioral;