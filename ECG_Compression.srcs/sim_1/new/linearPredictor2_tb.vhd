----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/03/2026 08:02:50 AM
-- Design Name: 
-- Module Name: linearPredictor2_tb - Behavioral
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
-- library work;
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

entity linearPredictor2_tb is
end linearPredictor2_tb;

architecture Behavioral of linearPredictor2_tb is
    component linearPredictor2 is
    Port (sample1: in STD_LOGIC; -- b16array;
          predictedOverflow : out STD_LOGIC;
          predicted: out STD_LOGIC); -- b16array;
    end component linearPredictor2;
    
    --signal A1 , Z1: b16array;
    signal overflow:  std_logic;
begin
    --UUT: linearPredictor2 port map(sample1=> A1,
      --                             predictedOverflow =>overflow,
        --                           predicted=> Z1);
    process
        begin
      --  A1(0) <= "0010001001111110" ;
      --  A1(1) <= "0010001001111110" ;
       -- A1(2) <= "0010001001111110";
        --A1(3) <= "0010001001111110";
        
        wait for 10 ns;
        
        
        wait;
    end process;


end Behavioral;
