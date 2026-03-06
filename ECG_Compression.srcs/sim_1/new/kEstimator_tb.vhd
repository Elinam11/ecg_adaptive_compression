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
use work.types_pkg.all;
use std.textio.all;

entity kEstimator_tb is
end kEstimator_tb;

architecture Behavioral of kEstimator_tb is
    
    -- Component declaration
    component kEstimator is
  Port ( Counter: in integer;
         Clock: in std_logic; 
         K_ready: out std_logic; 
         K: out integer range 0  to 15;
         total_bits : out integer; -- gc
         samples_done : out integer;
         compression_done: out std_logic;
         encoded_array: out output_array;
         encoded_array_valid: out std_logic; --gc
         M_errors: out output_array);
end component kEstimator;
    
    -- Testbench signals
    signal Clock_tb   : std_logic := '0';
    signal Counter_tb : integer := 1;  -- Start inactive
    signal K_tb       : integer range 0 to 15;
    
    -- Clock period
    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz clock
    
    -- Simulation control
    signal sim_done : boolean := false;
    
    -- new
     signal K_ready_tb:  std_logic  := '0'; 
     signal total_bits_tb :  integer; -- gc
     signal samples_done_tb :  integer;
     signal comp_done_tb:  std_logic;
     signal encoded_array_tb:  output_array;
     signal encoded_array_valid_tb:  std_logic; --gc
     signal M_errors_tb:  output_array;
     
     
     -- Compression statistics
    constant ORIGINAL_BITS : integer := 16384;  -- 1024 samples × 16 bits
    
begin

    -- Unit Under Test instantiation
  UUT: kEstimator port map
     ( Counter => Counter_tb,
         Clock => Clock_tb,
         K_ready => K_ready_tb,
         K => K_tb,
         total_bits => total_bits_tb ,-- gc
         samples_done => samples_done_tb,
         compression_done=> comp_done_tb,
         encoded_array => encoded_array_tb,
         encoded_array_valid => encoded_array_valid_tb, --gc
         M_errors => M_errors_tb );

    
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
    
    -- Main stimulus
    stim_golomb_process: process
        variable compression_ratio : real;
        variable space_savings     : real;
    begin
        
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
    
     process 
    file expected_file: text open read_mode is "C:/Users/elina/CapstoneVHDL/ECG_Compression/ECG_Compression.sim/sim_1/behav/xsim/m_n_pos.txt";
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