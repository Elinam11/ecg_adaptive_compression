----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/29/2026 05:56:56 PM
-- Design Name: 
-- Module Name: full16bitSubtractor - Behavioral
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

entity full16bitSubtractor is
    Port ( A: in std_logic_vector(15 downto 0);
           B: in std_logic_vector(15 downto 0);
           Overflow : out STD_LOGIC;
           S: out std_logic_vector(15 downto 0));
end full16bitSubtractor;

architecture Behavioral of full16bitSubtractor is
    component fullAdder is
        Port ( A : in std_logic;
               B : in std_logic;
               Bin : in std_logic;
               Diff : out std_logic;
               Bout : out std_logic);
    end component fullAdder;
    signal C0,C1,C2,C3 ,C4,C5 ,C6, C7 ,C8 ,C9 ,C10 ,C11, C12,C13, C14, C15: std_logic;
    signal B0,B1,B2,B3 ,B4,B5 ,B6, B7 ,B8 ,B9 ,B10 ,B11, B12,B13, B14, B15: std_logic;
    begin
    
    B0 <= not(B(0));
    B1 <= not(B(1));
    B2 <= not(B(2));
    B3 <= not(B(3)); 
    B4 <= not(B(4));
    B5 <= not(B(5));
    B6 <= not(B(6));
    B7 <= not(B(7));
    B8 <= not(B(8));
    B9 <= not(B(9));
    B10 <= not(B(10));
    B11 <= not(B(11));
    B12 <= not(B(12));
    B13 <= not(B(13));
    B14 <= not(B(14));
    B15 <= not(B(15));
    
    FA0: fullAdder port map (A=>A(0),B=>B0,Bin=>'1',Diff=>S(0),Bout=>C0);
    FA1: fullAdder port map (A=>A(1),B=>B1,Bin=>C0,Diff=>S(1),Bout=>C1);
    FA2: fullAdder port map (A=>A(2),B=>B2,Bin=>C1,Diff=>S(2),Bout=>C2);
    FA3: fullAdder port map (A=>A(3),B=>B3,Bin=>C2,Diff=>S(3),Bout=>C3);
    FA4: fullAdder port map (A=>A(4),B=>B4,Bin=>C3,Diff=>S(4),Bout=>C4);
    FA5: fullAdder port map (A=>A(5),B=>B5,Bin=>C4,Diff=>S(5),Bout=>C5);
    FA6: fullAdder port map (A=>A(6),B=>B6,Bin=>C5,Diff=>S(6),Bout=>C6);
    FA7: fullAdder port map (A=>A(7),B=>B7,Bin=>C6,Diff=>S(7),Bout=>C7);
    FA8: fullAdder port map (A=>A(8),B=>B8,Bin=>C7,Diff=>S(8),Bout=>C8);
    FA9: fullAdder port map (A=>A(9),B=>B9,Bin=>C8,Diff=>S(9),Bout=>C9);
    FA10: fullAdder port map (A=>A(10),B=>B10,Bin=>C9,Diff=>S(10),Bout=>C10);
    FA11: fullAdder port map (A=>A(11),B=>B11,Bin=>C10,Diff=>S(11),Bout=>C11);
    FA12: fullAdder port map (A=>A(12),B=>B12,Bin=>C11,Diff=>S(12),Bout=>C12);
    FA13: fullAdder port map (A=>A(13),B=>B13,Bin=>C12,Diff=>S(13),Bout=>C13);
    FA14: fullAdder port map (A=>A(14),B=>B14,Bin=>C13,Diff=>S(14),Bout=>C14);
    FA15: fullAdder port map (A=>A(15),B=>B15,Bin=>C14,Diff=>S(15),Bout=>C15);
    
    Overflow <= C14 xor C15;
    
    
end Behavioral;
