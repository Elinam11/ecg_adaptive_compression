----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/09/2026 11:52:53 AM
-- Design Name: 
-- Module Name: fullAdder16_tb - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/04/2026 05:05:07 PM
-- Design Name: 
-- Module Name: fullAdder12_tb - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fullAdder16_tb is
end fullAdder16_tb;

architecture Behavioral of fullAdder16_tb is
        component fullAdder16 is
            Port ( A_16 : in STD_LOGIC_VECTOR (15 downto 0);
                   B_16 : in STD_LOGIC_VECTOR (15 downto 0);
                   Bin_16 : in STD_LOGIC;
                   Sum_16 : out STD_LOGIC_VECTOR (15 downto 0);
                   Cout_16 : out STD_LOGIC);
        end component fullAdder16;
    
    signal A_tb, B_tb, Sum_tb : std_logic_vector(15 downto 0);
    signal Bin_tb, Cout_tb: std_logic;

begin
    UUT: fullAdder16 port map (A_16 => A_tb,
                               B_16 => B_tb,
                               Bin_16 => Bin_tb,
                               Sum_16 => Sum_tb,
                               Cout_16 => Cout_tb);
    process
        begin
        A_tb <= "0100000000000011";
        B_tb<=  "0000000000000001";
        Bin_tb<=  '0';
        wait for 10 ns;
        wait;
        
    end process;

end Behavioral;
