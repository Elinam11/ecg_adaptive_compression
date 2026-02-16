----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/10/2026 05:47:00 PM
-- Design Name: 
-- Module Name: parameterKEstimator_tb - Behavioral
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

entity parameterKEstimator_tb is
end parameterKEstimator_tb;

architecture Behavioral of parameterKEstimator_tb is
    component parameterKEst2 is
      Port (Counter: in integer;
            Clock: in std_logic;
            K: out integer);
end component parameterKEst2;
    
    signal Counter_tb , K_tb: integer:= 0 ;
    signal Clock_tb:  std_logic;
    
    
                                        
begin
    pEstimator: parameterKEst2 port map (Counter=> Counter_tb,
                                              Clock=> Clock_tb,
                                              K=> K_tb);
                                              
    process
        begin 
        Clock_tb <= '0'; wait for 10 ns;
        Clock_tb <= '1'; wait for 10 ns;
    end process;

    process
        begin
        Counter_tb <= 0;
        
        wait for 50 us;
        
        Counter_tb <= 1;
        
        wait for 50 us;
        wait;
    end process;

end Behavioral;
