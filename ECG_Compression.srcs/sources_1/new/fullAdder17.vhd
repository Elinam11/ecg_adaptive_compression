----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/04/2026 04:42:29 PM
-- Design Name: 
-- Module Name: fullAdder17 - Behavioral
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

entity fullAdder17 is
    Port ( A_17 : in STD_LOGIC_VECTOR (16 downto 0);
           B_17 : in STD_LOGIC_VECTOR (16 downto 0);
           Bin_17 : in STD_LOGIC;
           Sum_17 : out STD_LOGIC_VECTOR (16 downto 0);
           Cout_17 : out STD_LOGIC);
end fullAdder17;

architecture Behavioral of fullAdder17 is
    component fullAdder is
    Port ( A : in std_logic ;
           B : in std_logic;
           Bin : in std_logic;
           Diff : out std_logic;
           Bout : out std_logic);
    end component fullAdder;
    
    signal Cout : STD_LOGIC_VECTOR (16 downto 0);

begin
    FA1: fullAdder port map (A => A_17(0), B => B_17(0) , Bin => Bin_17 , Diff => Sum_17(0), Bout => Cout(0));
    FA2: fullAdder port map (A => A_17(1), B => B_17(1) , Bin => Cout(0) , Diff => Sum_17(1), Bout => Cout(1));
    FA3: fullAdder port map (A => A_17(2), B => B_17(2) , Bin => Cout(1) , Diff => Sum_17(2), Bout => Cout(2));
    FA4: fullAdder port map (A => A_17(3), B => B_17(3) , Bin => Cout(2) , Diff => Sum_17(3), Bout => Cout(3));
    FA5: fullAdder port map (A => A_17(4), B => B_17(4) , Bin => Cout(3) , Diff => Sum_17(4), Bout => Cout(4));
    FA6: fullAdder port map (A => A_17(5), B => B_17(5) , Bin => Cout(4) , Diff => Sum_17(5), Bout => Cout(5));
    FA7: fullAdder port map (A => A_17(6), B => B_17(6) , Bin => Cout(5) , Diff => Sum_17(6), Bout => Cout(6));
    FA8: fullAdder port map (A => A_17(7), B => B_17(7) , Bin => Cout(6) , Diff => Sum_17(7), Bout => Cout(7));
    FA9: fullAdder port map (A => A_17(8), B => B_17(8) , Bin => Cout(7) , Diff => Sum_17(8), Bout => Cout(8));
    FA10: fullAdder port map (A => A_17(9), B => B_17(9) , Bin => Cout(8) , Diff => Sum_17(9), Bout => Cout(9));
    FA11: fullAdder port map (A => A_17(10), B => B_17(10) , Bin => Cout(9) , Diff => Sum_17(10), Bout => Cout(10));
    FA12: fullAdder port map (A => A_17(11), B => B_17(11) , Bin => Cout(10) , Diff => Sum_17(11), Bout => Cout(11));
    FA13: fullAdder port map (A => A_17(12), B => B_17(12) , Bin => Cout(11) , Diff => Sum_17(12), Bout => Cout(12));
    FA14: fullAdder port map (A => A_17(13), B => B_17(13) , Bin => Cout(12) , Diff => Sum_17(13), Bout => Cout(13));
    FA15: fullAdder port map (A => A_17(14), B => B_17(14) , Bin => Cout(13) , Diff => Sum_17(14), Bout => Cout(14));
    FA16: fullAdder port map (A => A_17(15), B => B_17(15) , Bin => Cout(14) , Diff => Sum_17(15), Bout => Cout(15));
    FA17: fullAdder port map (A => A_17(16), B => B_17(16) , Bin => Cout(15) , Diff => Sum_17(16), Bout => Cout(16));
    Cout_17 <= Cout(16);
    
    

end Behavioral;
