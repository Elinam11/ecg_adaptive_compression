----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/29/2026 06:32:35 PM
-- Design Name: 
-- Module Name: full16bitSubtractor_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity full16bitSubtractor_tb is
end full16bitSubtractor_tb;

architecture Behavioral of full16bitSubtractor_tb is

    component full16bitSubtractor is
    Port ( A: in std_logic_vector(15 downto 0);
           B: in std_logic_vector(15 downto 0);
           Overflow : out STD_LOGIC;
           S: out std_logic_vector(15 downto 0));
    end component full16bitSubtractor;
    signal A_tb , B_tb , S_tb : std_logic_vector(15 downto 0);
    signal Of_tb: std_logic;
   
    
    begin
    UUT: full16bitSubtractor port map(A=>A_tb, B=> B_tb , Overflow => Of_tb , S => S_tb);
    
    process
        --variable seed1 , seed 2: positive := 1;
        --variable randA , randB : integer;
    begin
        for k in 0 to 30 loop
            --uniform(seed1,seed2, randA);
            --uniform(seed1,seed2, randB);
            --A_tb <= std_logic_vector(to_unsigned(randA mod 65536, 16));
            --B_tb <= std_logic_vector(to_unsigned(randB mod 65536, 16));
            wait for 10ns;
        end loop;
        wait;
    end process;
end Behavioral;
