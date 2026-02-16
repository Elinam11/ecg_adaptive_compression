----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/13/2026 09:10:16 AM
-- Design Name: 
-- Module Name: golmbRice_tb - Behavioral
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

entity golmbRice_tb is
--  Port ( );
end golmbRice_tb;

architecture Behavioral of golmbRice_tb is
    component golombRice is
    Port (--Sample: in STD_LOGIC_VECTOR(15 downto 0);
          --Buffer2: in b16array3;
          Sample: in STD_LOGIC;
          encodedE: out unsigned(15 downto 0);
          q_r: out STD_LOGIC_VECTOR(15 downto 0);
          Clk: in std_logic);
    end component golombRice;

    signal Clock_tb, Sample_tb   : std_logic := '0';
    signal encodedE_tb: unsigned(15 downto 0);
    signal qr_tb:  STD_LOGIC_VECTOR(15 downto 0);
    
    
    
    
    -- Simulation control
    signal sim_done : boolean := false;
    
     -- Clock period
    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz clock



begin
    
    UUT: golombRice port map(--Sample: in STD_LOGIC_VECTOR(15 downto 0);
          --Buffer2: in b16array3;
          Sample => Sample_tb,
          encodedE=>encodedE_tb,
          q_r=>qr_tb,
          Clk=> Clock_tb);
    
   -- Clock generation process
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
    
     
    stim_process: process
    begin
    
        Sample_tb <= '1';
        wait for 1 ns;
        report "=== Starting Parameter K Estimator Test ===" severity note;
        
        -- Wait for system to stabilize
        wait for 100 ns;
        -- Wait for computation to complete
        wait for 100000 * CLK_PERIOD;
        
        sim_done <= true;
        wait;
        
    end process;
    
end Behavioral;
