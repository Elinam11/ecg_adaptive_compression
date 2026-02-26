----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/23/2026 05:42:47 PM
-- Design Name: 
-- Module Name: hwt_tb - Behavioral
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
use work.types_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hwt_tb is
end hwt_tb;

architecture Behavioral of hwt_tb is
component hwt is
  Port ( Clock: in std_logic;
             coeff: out array10);
end component hwt;

signal coeff_tb: array10;
signal Clk_tb: std_logic;
signal sim_done: boolean:= false;
constant CLK_PERIOD : time := 20 ns;

begin
    UUT: hwt port map ( Clock=> Clk_tb,
                      coeff => coeff_tb);
             
    clk_process: process
        begin
        while not sim_done loop
            Clk_tb <= '0';
             wait for CLK_PERIOD/2;
            Clk_tb <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    process 
    begin
        report "=== Starting HWT Test ===" severity note;
        wait for 200200 ns;
        sim_done <= true;
        wait;
    end process;
    
end Behavioral;
