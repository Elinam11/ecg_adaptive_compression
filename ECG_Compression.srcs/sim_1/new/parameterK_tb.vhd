----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/11/2026 04:59:45 PM
-- Design Name: 
-- Module Name: parameterK_tb - Behavioral
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

entity parameterK_tb is
end parameterK_tb;

architecture Behavioral of parameterK_tb is
    component parameterK is
      Port ( Counter: in integer;
             Clock: in std_logic;
             K: out integer);
end component parameterK;

    signal Counter_t, K_t: integer;
    signal Clock_t : std_logic;
    
begin

    pE: parameterK port map ( Counter=> Counter_t,
                             Clock=> Clock_t,
                             K=> K_t);
    process
        begin
        Counter_t <= 1;
        wait for 5 ns;
        wait;
    end process;


end Behavioral;
