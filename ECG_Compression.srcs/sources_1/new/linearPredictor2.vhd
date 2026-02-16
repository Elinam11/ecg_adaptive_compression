----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/03/2026 06:57:12 AM
-- Design Name: 
-- Module Name: linearPredictor2 - Behavioral
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
library work;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use work.my_btypes.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity linearPredictor2 is
    Port (sample1: in std_logic; --b16array3
          predictedOverflow : out STD_LOGIC;
          predicted: out signed(15 downto 0));
end linearPredictor2;

architecture Behavioral of linearPredictor2 is
    component full16bitSubtractor is
    Port ( A: in std_logic_vector(15 downto 0);
           B: in std_logic_vector(15 downto 0);
           Overflow : out STD_LOGIC;
           S: out std_logic_vector(15 downto 0));
    end component full16bitSubtractor;
    signal sampleShifted: signed(15 downto 0) ;
begin
    --sampleShifted <= shift_left(signed(sample1(0)),1);
    --predicted <= sampleShifted - signed(sample1(1));
    
end Behavioral;
