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
use IEEE.NUMERIC_STD.ALL;

entity golmbRice_tb is
end golmbRice_tb;

architecture Behavioral of golmbRice_tb is
    
    component golombRice is
        Port (
            Sample           : in STD_LOGIC;
            encodedE         : out unsigned(15 downto 0);
            total_bits       : out integer;
            samples_done     : out integer;
            compression_done : out std_logic;
            Clk              : in std_logic
        );
    end component golombRice;
    
    -- Testbench signals
    signal Clock_tb      : std_logic := '0';
    signal Sample_tb     : std_logic := '0';
    signal encodedE_tb   : unsigned(15 downto 0);
    signal total_bits_tb : integer;
    signal samples_done_tb : integer;
    signal comp_done_tb  : std_logic;
    
    -- Simulation control
    signal sim_done : boolean := false;
    
    -- Clock period
    constant CLK_PERIOD : time := 20 ns;
    
    -- Compression statistics
    constant ORIGINAL_BITS : integer := 16384;  -- 1024 samples × 16 bits
    
begin
    
    UUT: golombRice port map(
        Sample           => Sample_tb,
        encodedE         => encodedE_tb,
        total_bits       => total_bits_tb,
        samples_done     => samples_done_tb,
        compression_done => comp_done_tb,
        Clk              => Clock_tb
    );
    
    -- Clock generation
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
    
    -- Main stimulus
    stim_process: process
        variable compression_ratio : real;
        variable space_savings     : real;
    begin
        Sample_tb <= '1';
        wait for 1 ns;
        
        report "========================================" severity note;
        report "Starting Golomb-Rice Compression Test" severity note;
        report "========================================" severity note;
        
        -- Wait for system to stabilize
        wait for 100 ns;
        
        -- Wait for K estimation + encoding to complete
        -- K estimation: ~21 us
        -- Encoding: ~130 us
        -- Total: ~155 us (use 200 us to be safe)
        wait for 900 us;
        
        -- Check if compression is done
        if comp_done_tb = '1' then
            report "Compression Complete!" severity note;
            report "========================================" severity note;
            
            -- Calculate compression ratio
            compression_ratio := real(ORIGINAL_BITS) / real(total_bits_tb);
            space_savings := (1.0 - (real(total_bits_tb) / real(ORIGINAL_BITS))) * 100.0;
            
            -- Print results
            report "COMPRESSION STATISTICS:" severity note;
            report "  Original size:      " & integer'image(ORIGINAL_BITS) & " bits" severity note;
            report "  Compressed size:    " & integer'image(total_bits_tb) & " bits" severity note;
            report "  Samples encoded:    " & integer'image(samples_done_tb) severity note;
            report "  Compression ratio:  " & real'image(compression_ratio) & ":1" severity note;
            report "  Space savings:      " & real'image(space_savings) & "%" severity note;
            report "  Avg bits/sample:    " & real'image(real(total_bits_tb) / real(samples_done_tb)) severity note;
            report "========================================" severity note;
            
            -- Quality assessment
            if compression_ratio > 2.0 then
                report "EXCELLENT compression (>2:1 ratio)" severity note;
            elsif compression_ratio > 1.5 then
                report "GOOD compression (1.5-2:1 ratio)" severity note;
            elsif compression_ratio > 1.0 then
                report "MODERATE compression (1-1.5:1 ratio)" severity note;
            else
                report "WARNING: Poor compression (<1:1 ratio)" severity warning;
            end if;
            
        else
            report "ERROR: Compression did not complete!" severity error;
        end if;
        
        -- End simulation
        wait for 1 us;
        sim_done <= true;
        wait;
        
    end process;
    
    -- Monitor encoding progress
    progress_monitor: process(Clock_tb)
        variable last_sample_count : integer := 0;
    begin
        if rising_edge(Clock_tb) then
            if samples_done_tb /= last_sample_count then
                last_sample_count := samples_done_tb;
                
                -- Print progress every 100 samples
                if (samples_done_tb mod 100) = 0 then
                    report "Encoded " & integer'image(samples_done_tb) 
                           & " samples, " & integer'image(total_bits_tb) 
                           & " bits used" severity note;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
