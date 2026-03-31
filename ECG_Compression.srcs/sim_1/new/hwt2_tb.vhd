----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/28/2026 09:11:29 PM
-- Design Name: 
-- Module Name: hwt2_tb - Behavioral
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

entity hwt2_tb is
end hwt2_tb;

architecture Behavioral of hwt2_tb is

    -- ----------------------------------------------------------------
    -- Component under test
    -- ----------------------------------------------------------------
    component hwt is
        Port (
            Clk               : in  std_logic;
            compress_data     : in  std_logic;
            ecg_samples       : in  dataStore;
            real_samples      : in  integer;
            coeff_array_valid : out std_logic;
            coeff             : out halfDataStore
        );
    end component hwt;

    -- ----------------------------------------------------------------
    -- Testbench signals
    -- ----------------------------------------------------------------
    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz clock

    signal Clk               : std_logic := '0';
    signal compress_data     : std_logic := '0';
    signal ecg_samples       : dataStore := (others => (others => '0'));
    signal real_samples      : integer   := 256;
    signal coeff_array_valid : std_logic;
    signal coeff             : halfDataStore;

    -- ----------------------------------------------------------------
    -- Helper: build a simple synthetic ECG pattern (sawtooth-like)
    -- ----------------------------------------------------------------
    procedure fill_ecg_ramp(signal arr : out dataStore) is
    begin
        for i in 0 to 255 loop
            arr(i) <= to_signed(i * 100, 16);   -- 0, 100, 200 … 25500
        end loop;
    end procedure;

    procedure fill_ecg_sine_approx(signal arr : out dataStore) is
        -- Simple quarter-sine values repeated; all fit in 15-bit range
        type lut_t is array(0 to 15) of integer;
        constant LUT : lut_t := (0,1305,2588,3827,5000,6088,7071,7934,
                                 8660,9239,9659,9914,10000,9914,9659,9239);
    begin
        for i in 0 to 255 loop
            arr(i) <= to_signed(LUT(i mod 16) * 3, 16);
        end loop;
    end procedure;

begin

    -- ----------------------------------------------------------------
    -- DUT instantiation
    -- ----------------------------------------------------------------
    DUT : hwt
        port map (
            Clk               => Clk,
            compress_data     => compress_data,
            ecg_samples       => ecg_samples,
            real_samples      => real_samples,
            coeff_array_valid => coeff_array_valid,
            coeff             => coeff
        );

    -- ----------------------------------------------------------------
    -- Clock generation
    -- ----------------------------------------------------------------
    clk_proc : process
    begin
        Clk <= '0'; wait for CLK_PERIOD / 2;
        Clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    -- ----------------------------------------------------------------
    -- Stimulus
    -- ----------------------------------------------------------------
    stim_proc : process
    begin

        -- ============================================================
        -- TEST 1: Basic ramp input, full real_samples = 256
        -- ============================================================
        report "=== TEST 1: Ramp input, real_samples=256 ===" severity note;

        -- Load ECG samples before asserting compress_data
        fill_ecg_ramp(ecg_samples);
        real_samples  <= 256;
        compress_data <= '0';
        wait for CLK_PERIOD * 5;

        -- Pulse compress_data for one clock to start the FSM
        compress_data <= '1';
        wait for CLK_PERIOD;
        compress_data <= '0';

        -- Wait until coeff_array_valid is asserted (DONE state)
        wait until rising_edge(coeff_array_valid);
        wait for CLK_PERIOD;   -- one more cycle to latch outputs

        -- Basic sanity check: coeff(0) should be the sentinel value 1234
        assert coeff(0) = to_signed(1234, 16)
            report "TEST 1 FAIL: coeff(0) sentinel mismatch. Got: " &
                   integer'image(to_integer(coeff(0)))
            severity error;

        report "TEST 1: coeff_array_valid asserted. coeff(0)=" &
               integer'image(to_integer(coeff(0))) severity note;

        -- Dump first 8 coefficients for visual inspection
        for k in 0 to 7 loop
            report "  coeff(" & integer'image(k) & ") = " &
                   integer'image(to_integer(coeff(k))) severity note;
        end loop;

        -- Allow DUT to return to IDLE before next test
        wait for CLK_PERIOD * 20;

        -- ============================================================
        -- TEST 2: Sine-approximation input, real_samples = 128
        --         (half samples zeroed in THRESHOLD)
        -- ============================================================
        report "=== TEST 2: Sine-approx input, real_samples=128 ===" severity note;

        fill_ecg_sine_approx(ecg_samples);
        real_samples  <= 128;
        compress_data <= '0';
        wait for CLK_PERIOD * 5;

        compress_data <= '1';
        wait for CLK_PERIOD;
        compress_data <= '0';

        wait until rising_edge(coeff_array_valid);
        wait for CLK_PERIOD;

        assert coeff(0) = to_signed(1234, 16)
            report "TEST 2 FAIL: coeff(0) sentinel mismatch." severity error;

        report "TEST 2: Done. coeff(0)=" &
               integer'image(to_integer(coeff(0))) severity note;

        for k in 0 to 7 loop
            report "  coeff(" & integer'image(k) & ") = " &
                   integer'image(to_integer(coeff(k))) severity note;
        end loop;

        wait for CLK_PERIOD * 20;

        -- ============================================================
        -- TEST 3: All-zeros input - all coefficients should be 0
        --         except the sentinel at coeff(0)
        -- ============================================================
        report "=== TEST 3: All-zero input ===" severity note;

        ecg_samples   <= (others => (others => '0'));
        real_samples  <= 256;
        wait for CLK_PERIOD * 5;

        compress_data <= '1';
        wait for CLK_PERIOD;
        compress_data <= '0';

        wait until rising_edge(coeff_array_valid);
        wait for CLK_PERIOD;

        assert coeff(0) = to_signed(1234, 16)
            report "TEST 3 FAIL: coeff(0) sentinel mismatch." severity error;

        for k in 1 to 127 loop
            assert coeff(k) = to_signed(0, 16)
                report "TEST 3 FAIL: expected coeff(" & integer'image(k) &
                       ")=0, got " & integer'image(to_integer(coeff(k)))
                severity error;
        end loop;

        report "TEST 3: All-zero check passed." severity note;

        wait for CLK_PERIOD * 20;

        -- ============================================================
        -- TEST 4: Max positive value input
        -- ============================================================
        report "=== TEST 4: Max-value input (32767) ===" severity note;

        for i in 0 to 255 loop
            ecg_samples(i) <= to_signed(32767, 16);
        end loop;
        real_samples  <= 256;
        wait for CLK_PERIOD * 5;

        compress_data <= '1';
        wait for CLK_PERIOD;
        compress_data <= '0';
    
        wait until rising_edge(coeff_array_valid);
        wait for CLK_PERIOD;
        
        assert coeff(0) = to_signed(1234, 16)
            report "TEST 4 FAIL: coeff(0) sentinel mismatch." severity error;

        report "TEST 4 PASS: coeff(0)=" &
               integer'image(to_integer(coeff(0))) severity note;

        wait for CLK_PERIOD * 20;

        -- ============================================================
        -- All tests complete
        -- ============================================================
        report "=== ALL TESTS COMPLETE ===" severity note;
        wait;  -- stop simulation
    end process;

end Behavioral;