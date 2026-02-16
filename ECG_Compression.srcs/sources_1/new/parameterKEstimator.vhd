----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/04/2026 10:28:31 AM
-- Design Name: 
-- Module Name: parameterKEstimator - Behavioral
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
--use work.my_btypes.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
-- use ieee.std_logic_misc.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity parameterKEstimator is
      Port (Counter: in integer;
            Clock: in std_logic;
            K: out integer);
end parameterKEstimator;

architecture Behavioral of parameterKEstimator is
    component bram_ecg IS
      PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
      );
    END component bram_ecg;

    component fullAdder26 is
    Port ( A_16 : in STD_LOGIC_VECTOR (25 downto 0);
           B_16 : in STD_LOGIC_VECTOR (25 downto 0);
           Bin_16 : in STD_LOGIC;
           Sum_16 : out STD_LOGIC_VECTOR (25 downto 0);
           Cout_16 : out STD_LOGIC);
end component fullAdder26;
    --component bram is 
    --Port (clocka: in std_logic;
    --        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    --        addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    --        dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    --        douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
    --end component bram;
    
    function first_one(vec: std_logic_vector) return integer is 
    begin
        for i in vec'high downto vec'low loop
            if vec(i) = '1' then
                return i;
                
            end if;
        end loop;
        return 0;
     end function;
     
    signal  dina_1, douta_1 : std_logic_vector (15 downto 0);
    signal wea_1: std_logic_vector(0 DOWNTO 0):= "0";
    signal addra_1: STD_LOGIC_VECTOR (16 downto 0):=(others => '0');
    signal  E: std_logic:= '0';
    -- signal avg: std_logic_vector(15 downto 0);
    
    -- summing the errors
    signal Sum,  avg, A,B,S: std_logic_vector(25 downto 0):=(others => '0');
    signal  Bin , C: std_logic:= '0';
    
begin
    ram: bram_ecg port map(clka=>Clock,
                        wea => wea_1,
                        ena => E,
                        addra => addra_1,
                        dina => dina_1,
                        douta => douta_1);
     
     FA: fullAdder26 port map( A_16=> A,
                               B_16 => B,
                               Bin_16 =>Bin,
                               Sum_16 => S,
                               Cout_16 => C);         
    
    
    process
        -- initialize sum variable 
        variable temp_sum : signed(24 downto 0) := (others => '0');
    begin
         
            
             if Counter = 0 then
               for i in 0 to 1023 loop

                        wait until rising_edge(Clock);
                        -- increment address count
                      --    A <= std_logic_vector(resize(unsigned(addra_1),26)) ;
                     --   B <= std_logic_vector(to_unsigned(1,26)); 
                        
                        -- read data from the address
                        E <= '1';
                        --addra_1 <= "00000000000000001";
                         addra_1 <= std_logic_vector(unsigned(addra_1)+ 1); -- first address??
                        -- Buffer16(j) <= douta_1;
                        
                        wait until rising_edge(Clock);
                        
                        -- store data in sum variable
                        -- A2 <= Sum;
                        -- B2 <= std_logic_vector(resize(signed(douta_1), 26));
                        -- Sum <= S2;
                        --temp_sum :=  temp_sum + resize(signed(douta_1), 26);
                        
                        temp_sum := resize(signed(douta_1), 25);
                        
                   
                    end loop;
                    
                  --end loop; 
          
          --Sum <= std_logic_vector(temp_sum);
          --report "Sum = " & integer'image(to_integer(signed(temp_sum)))severity warning;
          -- assign K after averaging window
         --wait for 1 us;
          --avg <=  std_logic_vector(shift_right(abs(signed(temp_sum)), 10));    -- error  
          
        --   wait until rising_edge(Clock);
          
           --K <= first_one(avg);
           K <= to_integer(temp_sum);
          
          --2 report "Avg = " & integer'image(to_integer(abs(signed(avg))))severity warning;
          
    end if;     
    wait;
    end process;

end Behavioral;
