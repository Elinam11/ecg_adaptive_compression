----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/17/2026 09:42:04 PM
-- Design Name: 
-- Module Name: adapLogic_tb - Behavioral
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

entity adapLogic_tb is
end adapLogic_tb;

architecture Behavioral of adapLogic_tb is
   component adapLogic is
   Port (Clock: in std_logic;
         start: in std_logic;
         start_addr: out std_logic_vector(16 downto 0);
         end_addr: out std_logic_vector(16 downto 0));
    end component adapLogic;
    
    signal Clock_tb: std_logic;
    signal start_tb: std_logic;
    signal start_addr_tb: std_logic_vector(16 downto 0);
    signal end_addr_tb: std_logic_vector(16 downto 0);
    constant CLK_PERIOD : time := 20 ns;
    signal sim_done: boolean:= false;
    
begin
    UUT: adapLogic port map 
        (Clock=> Clock_tb,
         start => start_tb,
         start_addr => start_addr_tb,
         end_addr => end_addr_tb);
         
    clk_process: process
        begin
        while not sim_done loop
            Clock_tb <= '0';
             wait for CLK_PERIOD/2;
            Clock_tb <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    process 
    begin
        report "=== Starting Adaptive Logic Test ===" severity note;
        
        start_tb <=  '1';
        wait for 50500200 ns;
        sim_done <= true;
        start_tb <=  '0';
        wait;
    end process;
    
end Behavioral;
