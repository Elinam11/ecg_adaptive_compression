----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/09/2026 11:40:58 AM
-- Design Name: 
-- Module Name: fullAdder16 - Behavioral
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


entity fullAdder16 is
    Port ( A_16 : in STD_LOGIC_VECTOR (15 downto 0);
           B_16 : in STD_LOGIC_VECTOR (15 downto 0);
           Bin_16 : in STD_LOGIC;
           Sum_16 : out STD_LOGIC_VECTOR (15 downto 0);
           Cout_16 : out STD_LOGIC);
end fullAdder16;

architecture Behavioral of fullAdder16 is
    component fullAdder is
    Port ( A : in std_logic ;
           B : in std_logic;
           Bin : in std_logic;
           Diff : out std_logic;
           Bout : out std_logic);
    end component fullAdder;
    
    signal Cout : STD_LOGIC_VECTOR (15 downto 0);

begin
    FA1: fullAdder port map (A => A_16(0), B => B_16(0) , Bin => Bin_16 , Diff => Sum_16(0), Bout => Cout(0));
    FA2: fullAdder port map (A => A_16(1), B => B_16(1) , Bin => Cout(0) , Diff => Sum_16(1), Bout => Cout(1));
    FA3: fullAdder port map (A => A_16(2), B => B_16(2) , Bin => Cout(1) , Diff => Sum_16(2), Bout => Cout(2));
    FA4: fullAdder port map (A => A_16(3), B => B_16(3) , Bin => Cout(2) , Diff => Sum_16(3), Bout => Cout(3));
    FA5: fullAdder port map (A => A_16(4), B => B_16(4) , Bin => Cout(3) , Diff => Sum_16(4), Bout => Cout(4));
    FA6: fullAdder port map (A => A_16(5), B => B_16(5) , Bin => Cout(4) , Diff => Sum_16(5), Bout => Cout(5));
    FA7: fullAdder port map (A => A_16(6), B => B_16(6) , Bin => Cout(5) , Diff => Sum_16(6), Bout => Cout(6));
    FA8: fullAdder port map (A => A_16(7), B => B_16(7) , Bin => Cout(6) , Diff => Sum_16(7), Bout => Cout(7));
    FA9: fullAdder port map (A => A_16(8), B => B_16(8) , Bin => Cout(7) , Diff => Sum_16(8), Bout => Cout(8));
    FA10: fullAdder port map (A => A_16(9), B => B_16(9) , Bin => Cout(8) , Diff => Sum_16(9), Bout => Cout(9));
    FA11: fullAdder port map (A => A_16(10), B => B_16(10) , Bin => Cout(9) , Diff => Sum_16(10), Bout => Cout(10));
    FA12: fullAdder port map (A => A_16(11), B => B_16(11) , Bin => Cout(10) , Diff => Sum_16(11), Bout => Cout(11));
    FA13: fullAdder port map (A => A_16(12), B => B_16(12) , Bin => Cout(11) , Diff => Sum_16(12), Bout => Cout(12));
    FA14: fullAdder port map (A => A_16(13), B => B_16(13) , Bin => Cout(12) , Diff => Sum_16(13), Bout => Cout(13));
    FA15: fullAdder port map (A => A_16(14), B => B_16(14) , Bin => Cout(13) , Diff => Sum_16(14), Bout => Cout(14));
    FA16: fullAdder port map (A => A_16(15), B => B_16(15) , Bin => Cout(14) , Diff => Sum_16(15), Bout => Cout(15));
    Cout_16 <= Cout(15);

end Behavioral;
