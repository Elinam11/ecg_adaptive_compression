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

entity fullAdder12_tb is
end fullAdder12_tb;

architecture Behavioral of fullAdder12_tb is
        component fullAdder12 is
            Port ( A_12 : in STD_LOGIC_VECTOR (11 downto 0);
                   B_12 : in STD_LOGIC_VECTOR (11 downto 0);
                   Bin_12 : in STD_LOGIC;
                   Sum_12 : out STD_LOGIC_VECTOR (11 downto 0);
                   Cout_12 : out STD_LOGIC);                   
        end component fullAdder12;
    
    signal A_tb, B_tb, Sum_tb : std_logic_vector(11 downto 0);
    signal Bin_tb, Cout_tb: std_logic;

begin
    UUT: fullAdder12 port map (A_12 => A_tb,
                               B_12 => B_tb,
                               Bin_12 => Bin_tb,
                               Sum_12 => Sum_tb,
                               Cout_12 => Cout_tb);
    process
        begin
        A_tb <= "010000000011";
        B_tb<=  "000000000001";
        Bin_tb<=  '0';
        wait for 10 ns;
        wait;
        
    end process;

end Behavioral;
