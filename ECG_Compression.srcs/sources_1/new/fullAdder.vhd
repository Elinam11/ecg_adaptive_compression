----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/06/2026 11:06:57 PM
-- Design Name: 
-- Module Name: fullAdder - Behavioral
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


entity fullAdder is
    Port ( A : in std_logic ;
           B : in std_logic;
           Bin : in std_logic;
           Diff : out std_logic;
           Bout : out std_logic);
end fullAdder;

architecture Behavioral of fullAdder is

    component halfAdder is
    Port ( A : in std_logic;
           B : in std_logic;
           Difference : out std_logic ;
           Borrow : out std_logic);
    end component halfAdder;
    
    signal sigDiff, sigBorrow1 , sigBorrow2 : std_logic;

begin
    HS1: halfAdder port map(A=>A, B=>B, Difference=>sigDiff, Borrow=> sigBorrow1);
    HS2: halfAdder port map(A=>sigDiff, B=>Bin, Difference=>Diff, Borrow=> sigBorrow2);
    Bout <= sigBorrow1 or sigBorrow2;

end Behavioral;


