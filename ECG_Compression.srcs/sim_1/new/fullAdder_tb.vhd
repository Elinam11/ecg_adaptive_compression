----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/06/2026 11:07:56 PM
-- Design Name: 
-- Module Name: fullAdder_tb - Behavioral
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

entity fullAdder_tb is
end fullAdder_tb;

architecture Behavioral of fullAdder_tb is

    component fullAdder is
    Port ( A : in std_logic ;
           B : in std_logic;
           Bin : in std_logic;
           Diff : out std_logic;
           Bout : out std_logic);
    end component fullAdder;
    signal A1 , B1 , Bin1, Diff1, Bout1: std_logic;
    
    begin

    UUT: fullAdder port map(A=>A1, B => B1, Bin=> Bin1, Diff => Diff1 , Bout => Bout1);
    process
    begin
        
        A1 <= '0';
        B1<=  '0';
        Bin1<=  '0';
        wait for 10ns;
        
        A1 <= '0';
        B1<=  '0';
        Bin1<=  '1';
        wait for 10ns;
        
        A1 <= '0';
        B1<=  '1';
        Bin1<=  '0';
        wait for 10ns;
        
        A1 <= '0';
        B1<=  '1';
        Bin1<=  '1';
        wait for 10ns;
        
        A1 <= '1';
        B1<=  '0';
        Bin1<=  '0';
        wait for 10ns;
        
         A1 <= '1';
        B1<=  '0';
        Bin1<=  '1';
        wait for 10ns;
        
        A1 <= '1';
        B1<=  '1';
        Bin1<=  '0';
        wait for 10ns;
        
        
        A1 <= '1';
        B1<=  '1';
        Bin1<=  '1';
        wait for 10ns;
        
        wait;
        
    end process;

end Behavioral;

