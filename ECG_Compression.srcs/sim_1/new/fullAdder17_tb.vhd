----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/09/2026 11:43:47 AM
-- Design Name: 
-- Module Name: fullAdder17_tb - Behavioral
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

entity fullAdder17_tb is
end fullAdder17_tb;

architecture Behavioral of fullAdder17_tb is
        component fullAdder17 is
            Port ( A_17 : in STD_LOGIC_VECTOR (16 downto 0);
                   B_17 : in STD_LOGIC_VECTOR (16 downto 0);
                   Bin_17 : in STD_LOGIC;
                   Sum_17 : out STD_LOGIC_VECTOR (16 downto 0);
                   Cout_17 : out STD_LOGIC);
        end component fullAdder17;
        
    signal A_tb, B_tb, Sum_tb : std_logic_vector(16 downto 0);
    signal Bin_tb, Cout_tb: std_logic;

begin
    UUT: fullAdder17 port map (A_17 => A_tb,
                               B_17 => B_tb,
                               Bin_17 => Bin_tb,
                               Sum_17 => Sum_tb,
                               Cout_17 => Cout_tb);
    process
        begin
        A_tb <= "00000010000000011";
        B_tb<=  "00000000000000001";
        Bin_tb<=  '0';
        wait for 10 ns;
        wait;
        
    end process;

end Behavioral;
