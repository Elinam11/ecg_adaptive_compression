----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/23/2026 05:13:02 PM
-- Design Name: 
-- Module Name: hwt - Behavioral
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

entity hwt is
  Port ( Clock: in std_logic;
        coeff_array_valid: out std_logic;
        coeff: out array9a);
end hwt;

architecture Behavioral of hwt is
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
    
    function nonzero(coeff: signed) return integer is
    variable num_bits: integer:= 0; 
    begin 
        for i in coeff'high downto coeff'low loop
            if coeff(i) /= '0' then
                num_bits := num_bits + 1;
            end if;
        end loop;
        return num_bits;
    end function;
                
    -- hwt
   signal temp_holder: std_logic_vector(31 DOWNTO 0);
   signal  buffer_arr: array9a;
   
    
    -- statemachine
    type state_type is (IDLE, READY,READO, COMPUTE, THRESHOLD ,DONE);
    signal state: state_type:= IDLE;
     -- BRAM signals
    signal  dina_1, douta_1 : std_logic_vector (15 downto 0);
    signal wea_1: std_logic_vector(0 DOWNTO 0):= "0";
    signal addra_1: STD_LOGIC_VECTOR (16 downto 0):=(others => '0');
    signal  E: std_logic:= '0';
    
    -- BRAM signals B
    signal  dinb_1, doutb_1 : std_logic_vector (15 downto 0);
    signal web_1: std_logic_vector(0 DOWNTO 0):= "0";
    signal addrb_1: STD_LOGIC_VECTOR (16 downto 0):=(others => '0');
    signal  E_b: std_logic:= '0';
    
    -- compression tracking
    signal total_bits_reg: integer := 0;
    signal samples_done_reg : integer := 0;
    signal comp_done : std_logic := '0';
    
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
                        
    process(Clock)
    variable  approx_temp: array9;
    variable  detail_temp: array9;
   
    -- hwt
    variable data_arr : array10;
    variable level_count: integer := 0;
    variable coeff_count: integer := 0;
    variable a : signed(15 downto 0) := (others => '0');
    variable b : signed(15 downto 0) := (others => '0');
    variable sum_ab : signed(16 downto 0) := (others => '0');
    variable diff_ab : signed(16 downto 0) := (others => '0');
    variable sum_product_ab : signed(32 downto 0) := (others => '0');
    variable diff_product_ab : signed(32 downto 0) := (others => '0');
    variable half :integer := 512;
    
    -- threshold
    variable thresh : integer:= 50;
    variable coefficient : signed (15 downto 0) :=(others => '0') ;
    variable total_bits_used : integer:= 0;
    
    --BRAM
    variable read_addr : unsigned(16 downto 0)  := (others => '0');
    variable cycle_count : integer range  0 to 1100 := 0;
    variable bits_used : integer:= 0;
    variable sample_index : integer := 0;  
    variable encoded_val : unsigned(15 downto 0);
    variable encoded_array_var : output_array := (others => (others => '0'));
    
    begin
    if rising_edge(Clock) then
    
    case state is 
        when IDLE =>
             E <= '0'; -- bram not enable
             wea_1 <= "0";
             read_addr := (others => '0');
             cycle_count := 0;
             coeff_count := 0;
             
             -- encoded 
             total_bits_reg <= 0;
             samples_done_reg  <= 0;
             sample_index := 0;  -- RESET
             
             -- hwt
             level_count := 0;
             coeff_array_valid <= '0';
             a  := (others => '0');
             b  := (others => '0');
             sum_ab := (others => '0');
             diff_ab := (others => '0');
             sum_product_ab := (others => '0');
             diff_product_ab := (others => '0');
             data_arr :=(others =>( others => '0'));
             approx_temp  := (others =>(others => '0'));
             detail_temp := (others =>(others => '0')) ;
             coeff <= (others =>(others => '0')) ;
     
             -- threshold
             thresh := 50;
             coefficient := (others => '0') ;
             
             for i in 0 to 1023 loop
                encoded_array_var(i) := (others => '0');
            end loop;
            if cycle_count = 0 then
                state <= READY;
            end if;
        
        when READY => 
            -- set up for memory access
            E <= '1';
            addra_1 <= std_logic_vector(read_addr);
            read_addr:= read_addr + 1;
            cycle_count:= cycle_count + 1;
            
            
            -- wait for data to clock out
            if cycle_count >= 3 then
               state <= READO;
                    end if;
         when READO =>
            -- read data into coeff array
            if read_addr <= 1023 then   -- !!!condition for a single window
                E <= '1';
                addra_1 <=std_logic_vector(read_addr);
                read_addr := read_addr + 1;
             else 
                E <= '0';
            end if;
            
            -- write data into data array
            data_arr(coeff_count) := signed(douta_1);
            if coeff_count >= 1023 then
                half := 512;
                state <= COMPUTE;
            end if;
            coeff_count:= coeff_count + 1;
                
        when COMPUTE =>
  
                for i in 0 to 511 loop
                    if i < half then
                    a := data_arr(2*i);
                    b := data_arr(2*i + 1);
                    sum_ab := resize(a,17) + resize(b,17) ;
                    diff_ab := resize(a,17) - resize(b,17) ;
                    sum_product_ab := sum_ab * to_signed(23170,16);
                    diff_product_ab := diff_ab * to_signed(23170,16);
                    approx_temp(i) := resize(shift_right(sum_product_ab,15),33);
                    detail_temp(i) := resize(shift_right(diff_product_ab,15),33);
                    end if;
                end loop;
                
                for i in 0 to 511 loop
                    if i < half then
                    data_arr(i) := resize(approx_temp(i),16);
                    data_arr(half + i) := resize(detail_temp(i),16);
                    end if;
                end loop;
                
                half := half / 2;
                level_count := level_count + 1;
                
                
            
            if level_count = 4 then 
 
                for i in 0 to 511 loop -- up to 512 because the rest would be empty
                  buffer_arr(i) <= data_arr(i);
                end loop;
                
                state <= THRESHOLD;
    
            end if;
            
            when THRESHOLD =>
                for i in 0 to 511 loop
                    coefficient := abs(buffer_arr(i));
                    total_bits_used := nonzero(coefficient) + total_bits_used; -- for CR tracking
                    if coefficient <= thresh then
                        buffer_arr(i)<= (others => '0');
                    end if;
                end loop; 
                state <= DONE;
                    
            when DONE =>
                coeff_array_valid <= '1';
                total_bits_reg <= total_bits_used;
                coeff <= buffer_arr;
                
                
     end case;
    end if;
    end process;
end Behavioral;
