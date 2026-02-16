----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/04/2026 04:42:29 PM
-- Design Name: 
-- Module Name: fullAdder12 - Behavioral
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

entity fullAdder12 is
    Port ( A_12 : in STD_LOGIC_VECTOR (11 downto 0);
           B_12 : in STD_LOGIC_VECTOR (11 downto 0);
           Bin_12 : in STD_LOGIC;
           Sum_12 : out STD_LOGIC_VECTOR (11 downto 0);
           Cout_12 : out STD_LOGIC);
end fullAdder12;

architecture Behavioral of fullAdder12 is
    component fullAdder is
    Port ( A : in std_logic ;
           B : in std_logic;
           Bin : in std_logic;
           Diff : out std_logic;
           Bout : out std_logic);
    end component fullAdder;
    
    signal Cout : STD_LOGIC_VECTOR (11 downto 0);

begin
    FA1: fullAdder port map (A => A_12(0), B => B_12(0) , Bin => Bin_12 , Diff => Sum_12(0), Bout => Cout(0));
    FA2: fullAdder port map (A => A_12(1), B => B_12(1) , Bin => Cout(0) , Diff => Sum_12(1), Bout => Cout(1));
    FA3: fullAdder port map (A => A_12(2), B => B_12(2) , Bin => Cout(1) , Diff => Sum_12(2), Bout => Cout(2));
    FA4: fullAdder port map (A => A_12(3), B => B_12(3) , Bin => Cout(2) , Diff => Sum_12(3), Bout => Cout(3));
    FA5: fullAdder port map (A => A_12(4), B => B_12(4) , Bin => Cout(3) , Diff => Sum_12(4), Bout => Cout(4));
    FA6: fullAdder port map (A => A_12(5), B => B_12(5) , Bin => Cout(4) , Diff => Sum_12(5), Bout => Cout(5));
    FA7: fullAdder port map (A => A_12(6), B => B_12(6) , Bin => Cout(5) , Diff => Sum_12(6), Bout => Cout(6));
    FA8: fullAdder port map (A => A_12(7), B => B_12(7) , Bin => Cout(6) , Diff => Sum_12(7), Bout => Cout(7));
    FA9: fullAdder port map (A => A_12(8), B => B_12(8) , Bin => Cout(7) , Diff => Sum_12(8), Bout => Cout(8));
    FA10: fullAdder port map (A => A_12(9), B => B_12(9) , Bin => Cout(8) , Diff => Sum_12(9), Bout => Cout(9));
    FA11: fullAdder port map (A => A_12(10), B => B_12(10) , Bin => Cout(9) , Diff => Sum_12(10), Bout => Cout(10));
    FA12: fullAdder port map (A => A_12(11), B => B_12(11) , Bin => Cout(10) , Diff => Sum_12(11), Bout => Cout(11));
    Cout_12 <= Cout(11);
    
    

end Behavioral;
