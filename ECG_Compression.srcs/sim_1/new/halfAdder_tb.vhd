----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/06/2026 11:05:26 PM
-- Design Name: 
-- Module Name: halfAdder_tb - Behavioral
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

entity halfAdder_tb is
end halfAdder_tb;

architecture Behavioral of halfAdder_tb is
    component halfAdder is
    Port ( A : in std_logic;
           B : in std_logic;
           Difference : out std_logic ;
           Borrow : out std_logic);
    end component halfAdder;
    signal A1 , B1 , Diff , Borr: std_logic ;
    
    begin
    
    UUT: halfAdder port map (A=> A1 , B => B1 , Difference => Diff, Borrow => Borr);
    process 
    begin
        A1 <= '0';
        B1<=  '0';
        wait for 10ns;
        
        A1 <= '0';
        B1<=  '1';
        wait for 10ns;
        
        A1 <= '1';
        B1<=  '0';
        wait for 10ns;
        
        A1 <= '1';
        B1<=  '1';
        wait for 10ns;
        wait;
    end process;
end Behavioral;