----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/12/2026 03:11:24 PM
-- Design Name: 
-- Module Name: bram_test_tb2 - Behavioral
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

entity bram_test_tb2 is
--  Port ( );
end bram_test_tb2;

architecture Behavioral of bram_test_tb2 is
component bram_test is
   Port (
   Counter: in integer;
   Clock: in std_logic;
         temp: OUT integer);
end component bram_test;

signal Clock_tb: std_logic:= '0';
signal temp_tb, Counter_tb: integer:= 0;



begin

UUT: bram_test port map
        (Counter => Counter_tb,
        Clock => Clock_tb,
         temp=> temp_tb);




process
    begin
        
        Clock_tb <= not Clock_tb; wait for 10 ns;
        
    end process;
    
process
    begin
        
        Counter_tb <= 0; wait for 100 ns;
        
        Counter_tb <= 1; wait for 100 ns;
        wait;
        
    end process;
    
    end Behavioral;