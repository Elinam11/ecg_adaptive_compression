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
use work.types_pkg.all;
use std.textio.all;

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
            Clk              : in std_logic;
            encoded_array: out output_array;
            encoded_array_valid: out std_logic
        );
    end component golombRice;
    
    -- Testbench signals
    signal Clock_tb      : std_logic := '0';
    signal Sample_tb     : std_logic := '0';
    signal encodedE_tb   : unsigned(15 downto 0);
    signal total_bits_tb : integer;
    signal samples_done_tb : integer;
    signal comp_done_tb  : std_logic;
    signal encoded_array_tb  : output_array;
    signal encoded_array_valid_tb : std_logic;
    
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
        Clk              => Clock_tb,
        encoded_array => encoded_array_tb,
        encoded_array_valid => encoded_array_valid_tb
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
        wait for 5000 us; -- 798990
        
        -- Check if compression is done
        wait until comp_done_tb = '1' ;
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
            
        
        --    report "ERROR: Compression did not complete!" severity error;
        
        
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

    process 
    file expected_file: text open read_mode is "C:/Users/elina/CapstoneVHDL/ECG_Compression/ECG_Compression.sim/sim_1/behav/xsim/compressed_output.txt";
    variable expected_line : line;
    variable expected_val : integer;
    variable char: character;
    variable mismatches: integer := 0;
    variable good_read : boolean;
    variable vhdl_val : integer;
begin
    -- Wait for compression to fully complete
    wait until comp_done_tb = '1' and encoded_array_valid_tb = '1';
    wait for 100 ns;  -- Extra safety margin
    
    report "========================================" severity note;
    report "Starting Python vs VHDL comparison..." severity note;
    report "========================================" severity note;
    
    -- Read Python expected values
    readline(expected_file, expected_line);
    
    -- Compare each value from the stored array
            for i in 0 to 1023 loop
            read(expected_line, expected_val, good_read);
        
            -- Read VHDL value
            vhdl_val := to_integer(encoded_array_tb(i));
        
            if i < 10 then
                report "Sample " & integer'image(i) & 
                       ": Python=" & integer'image(expected_val) & 
                       " VHDL=" & integer'image(vhdl_val) 
                       severity note;
            end if;
        
            if vhdl_val /= expected_val then
                if mismatches < 10 then
                    report "MISMATCH at sample " & integer'image(i) & 
                           ": Expected=" & integer'image(expected_val) & 
                           " Got=" & integer'image(vhdl_val) 
                           severity warning;
                end if;
                mismatches := mismatches + 1;
            end if;
        
            if i < 1023 then
                read(expected_line, char, good_read);
            end if;
        end loop;

    
    -- Final report
    report "========================================" severity note;
    if mismatches = 0 then
        report "SUCCESS! All 1024 encoded values match Python output!" severity note;
    else
        report "FAILED! " & integer'image(mismatches) & " mismatches found!" severity error;
    end if;
    report "========================================" severity note;
    
    file_close(expected_file);
    wait;
end process;
    
end Behavioral;
