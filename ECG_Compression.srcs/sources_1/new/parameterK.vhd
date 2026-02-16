----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/11/2026 04:47:26 PM
-- Design Name: 
-- Module Name: parameterK - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity parameterK is
  Port ( Counter: in integer;
         Clock: in std_logic;
         K: out integer);
end parameterK;

architecture Behavioral of parameterK is

begin
    
    process(Clock)
begin
    if rising_edge(Clock) then
        K <= 1;
    end if;
end process;




end Behavioral;
