----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/12/2026 07:25:17 PM
-- Design Name: 
-- Module Name: kEstimator_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity kEstimator_tb is
end kEstimator_tb;

architecture Behavioral of kEstimator_tb is
    
    -- Component declaration
    component kEstimator is
        Port (
            Counter : in integer;
            Clock   : in std_logic;
            K       : out integer range 0 to 15
        );
    end component kEstimator;
    
    -- Testbench signals
    signal Clock_tb   : std_logic := '0';
    signal Counter_tb : integer := 1;  -- Start inactive
    signal K_tb       : integer range 0 to 15;
    
    -- Clock period
    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz clock
    
    -- Simulation control
    signal sim_done : boolean := false;
    
begin

    -- Unit Under Test instantiation
    UUT: kEstimator port map (
        Counter => Counter_tb,
        Clock   => Clock_tb,
        K       => K_tb
    );
    
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
    
    -- Stimulus process
    stim_process: process
    begin
        -- Initial conditions
        Counter_tb <= 1;
        
        report "=== Starting Parameter K Estimator Test ===" severity note;
        
        -- Wait for system to stabilize
        wait for 100 ns;
        
        -----------------------------------------------------------
        -- Test 1: First K estimation
        -----------------------------------------------------------
        report "Test 1: Triggering first K estimation..." severity note;
        Counter_tb <= 0;
        
        -- Wait for computation to complete
        -- 1026 cycles for accumulation + few cycles for compute/done
        wait for 1030 * CLK_PERIOD;
        
        report "Test 1: K value = " & integer'image(K_tb) severity note;
        
        -- Deactivate
        Counter_tb <= 1;
        wait for 200 ns;
        
        -----------------------------------------------------------
        -- Test 2: Second K estimation (verify repeatability)
        -----------------------------------------------------------
        
        
        sim_done <= true;
        wait;
        
    end process;
    
    -- Monitor process (optional - prints state changes)
    monitor_process: process(K_tb)
    begin
        if K_tb'event then
            report "K output changed to: " & integer'image(K_tb) 
                   severity note;
        end if;
    end process;

end Behavioral;