----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/23/2026 05:13:02 PM
-- Design Name: 
-- Module Name: hwt - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;

entity hwt is
  Port ( Clk: in std_logic;
         compress_data : in std_logic;
         ecg_samples : in dataStore;
         real_samples : in integer;
         coeff_array_valid: out std_logic;
         coeff: out dataStore);
end hwt;

architecture Behavioral of hwt is

    function nonzero(coeff: signed) return integer is
    variable num_bits: integer:= 0; 
    begin 
        for i in coeff'high downto coeff'low loop
            if coeff(i) /= '0' then
                num_bits := num_bits + 1;
            end if;
        end loop;
        return num_bits;
    end function;

    -- state machine
    type state_type is (IDLE, READY, COMPUTE, THRESHOLD, DONE, WAIT_ACK);
    signal state: state_type := IDLE;

    -- ----------------------------------------------------------------
    -- PROBE SIGNALS  (all visible in the waveform viewer)
    -- ----------------------------------------------------------------

    -- data load probes: snapshot of ecg_samples when latched
    signal probe_loaded_0  : signed(15 downto 0) := (others => '0');
    signal probe_loaded_1  : signed(15 downto 0) := (others => '0');
    signal probe_loaded_2  : signed(15 downto 0) := (others => '0');
    signal probe_loaded_3  : signed(15 downto 0) := (others => '0');
    signal probe_loaded_last : signed(15 downto 0) := (others => '0');

    -- butterfly probes: a, b, sum, diff, approx, detail for current pair
    signal probe_level     : integer := 0;
    signal probe_pidx      : integer := 0;
    signal probe_half      : integer := 0;
    signal probe_a         : signed(15 downto 0) := (others => '0');
    signal probe_b         : signed(15 downto 0) := (others => '0');
    signal probe_sum       : signed(16 downto 0) := (others => '0');
    signal probe_diff      : signed(16 downto 0) := (others => '0');
    signal probe_approx    : signed(15 downto 0) := (others => '0');
    signal probe_detail    : signed(15 downto 0) := (others => '0');

    -- local_arr snapshot after each level completes (first 8 entries)
    signal probe_after_lvl0_0 : signed(15 downto 0) := (others => '0');
    signal probe_after_lvl0_1 : signed(15 downto 0) := (others => '0');
    signal probe_after_lvl0_2 : signed(15 downto 0) := (others => '0');
    signal probe_after_lvl0_3 : signed(15 downto 0) := (others => '0');

    signal probe_after_lvl1_0 : signed(15 downto 0) := (others => '0');
    signal probe_after_lvl1_1 : signed(15 downto 0) := (others => '0');
    signal probe_after_lvl1_2 : signed(15 downto 0) := (others => '0');
    signal probe_after_lvl1_3 : signed(15 downto 0) := (others => '0');

    signal probe_after_lvl2_0 : signed(15 downto 0) := (others => '0');
    signal probe_after_lvl2_1 : signed(15 downto 0) := (others => '0');
    signal probe_after_lvl2_2 : signed(15 downto 0) := (others => '0');
    signal probe_after_lvl2_3 : signed(15 downto 0) := (others => '0');

    signal probe_after_lvl3_0 : signed(15 downto 0) := (others => '0');
    signal probe_after_lvl3_1 : signed(15 downto 0) := (others => '0');
    signal probe_after_lvl3_2 : signed(15 downto 0) := (others => '0');
    signal probe_after_lvl3_3 : signed(15 downto 0) := (others => '0');

    -- buffer_arr snapshot after copy (first 8 entries)
    signal probe_buf_0  : signed(15 downto 0) := (others => '0');
    signal probe_buf_1  : signed(15 downto 0) := (others => '0');
    signal probe_buf_2  : signed(15 downto 0) := (others => '0');
    signal probe_buf_3  : signed(15 downto 0) := (others => '0');
    signal probe_buf_4  : signed(15 downto 0) := (others => '0');
    signal probe_buf_5  : signed(15 downto 0) := (others => '0');
    signal probe_buf_6  : signed(15 downto 0) := (others => '0');
    signal probe_buf_7  : signed(15 downto 0) := (others => '0');

    -- threshold probes
    signal probe_thresh_idx   : integer := 0;
    signal probe_thresh_coeff : signed(15 downto 0) := (others => '0');
    signal probe_thresh_kept  : std_logic := '0';
    signal probe_real_coeffs  : integer := 0;

    -- final output probes
    signal probe_coeff_0 : signed(15 downto 0) := (others => '0');
    signal probe_coeff_1 : signed(15 downto 0) := (others => '0');
    signal probe_coeff_2 : signed(15 downto 0) := (others => '0');
    signal probe_coeff_3 : signed(15 downto 0) := (others => '0');

    -- compression tracking
    signal total_bits_reg    : integer := 0;
    signal samples_done_reg  : integer := 0;
    
begin

    process(Clk)
    variable approx_temp      : array9;
    variable detail_temp      : array9;
    variable local_arr        : dataStore;
    variable buffer_arr       : dataStore;
    variable level_count      : integer := 0;
    variable coeff_count      : integer := 0;
    variable a                : signed(15 downto 0) := (others => '0');
    variable b                : signed(15 downto 0) := (others => '0');
    variable sum_ab           : signed(16 downto 0) := (others => '0');
    variable diff_ab          : signed(16 downto 0) := (others => '0');
    variable sum_product_ab   : signed(33 downto 0) := (others => '0');
    variable diff_product_ab  : signed(33 downto 0) := (others => '0');
    variable half             : integer := 128;
    variable process_idx      : integer := 0;
    variable thresh           : integer := 25;
    variable real_coeffs      : integer := 0;
    variable coefficient      : signed(15 downto 0) := (others => '0');
    variable total_bits_used  : integer := 0;
    variable cycle_count      : integer := 0;
    variable real_approx_coeffs : integer := 0;
    begin
    if rising_edge(Clk) then
    case state is

        -- ----------------------------------------------------------------
        when IDLE =>
            
            
            coeff             <= (others => (others => '0'));
            total_bits_reg    <= 0;
            cycle_count       := 0;
            coeff_count       := 0;
            level_count       := 0;
            process_idx       := 0;
            half              := 128;
            thresh            := 25;
            total_bits_used   := 0;
            local_arr         := (others => (others => '0'));
            buffer_arr        := (others => (others => '0'));
            approx_temp       := (others => (others => '0'));
            detail_temp       := (others => (others => '0'));

            -- reset probes
            probe_level  <= 0;
            probe_pidx   <= 0;
            probe_half   <= 128;
            coeff_array_valid <= '0';
            if compress_data = '1' then
                state <= READY;
            end if;

        -- ----------------------------------------------------------------
        when READY =>
            -- latch ecg_samples into local_arr NOW (one cycle after
            -- compress_data so ecg_samples is stable)
            for i in 0 to 255 loop
                local_arr(i) := ecg_samples(i);
            end loop;
            half      := 128;
            level_count := 0;
            process_idx := 0;
            real_coeffs := real_samples ;
            buffer_arr  := (others => (others => '0'));
            real_approx_coeffs := (real_samples + 15) / 16;
            
            

            -- PROBE: snapshot first and last loaded values
            probe_loaded_0    <= local_arr(0);
            probe_loaded_1    <= local_arr(1);
            probe_loaded_2    <= local_arr(2);
            probe_loaded_3    <= local_arr(3);
            if real_samples > 0  then
                probe_loaded_last <= local_arr(real_samples - 1);
            end if;
            probe_real_coeffs <= real_coeffs;

            --report "READY: real_samples=" & integer'image(real_samples) &
            --       "  real_coeffs=" & integer'image(real_coeffs) &
            --       "  local_arr(0)=" & integer'image(to_integer(local_arr(0))) &
            --       "  local_arr(1)=" & integer'image(to_integer(local_arr(1))) &
            --       "  local_arr(2)=" & integer'image(to_integer(local_arr(2)))
            --severity note;

            state <= COMPUTE;

        -- ----------------------------------------------------------------
        when COMPUTE =>
            if level_count = 0 and process_idx = 0 then
    a := local_arr(0);
    b := local_arr(1);
    --report "ACTUAL a=" & integer'image(to_integer(a)) &
    --       " b=" & integer'image(to_integer(b))
    --severity note;
end if;

            if level_count = 0 and process_idx = 0 then
        
    end if;
    
        if process_idx < 4 and level_count = 0 then
    report "butterfly lvl=" & integer'image(level_count) &
           " idx=" & integer'image(process_idx) &
           " a=" & integer'image(to_integer(a)) &
           " b=" & integer'image(to_integer(b)) &
           " approx=" & integer'image(to_integer(
               resize(approx_temp(process_idx),16))) &
           " detail=" & integer'image(to_integer(
               resize(detail_temp(process_idx),16)))
    severity note;
end if;

            if level_count < 4 then

                probe_level <= level_count;
                probe_pidx  <= process_idx;
                probe_half  <= half;

                if process_idx < half then
                    -- FIXED: 2*process_idx not 2+process_idx
                    
                    a := local_arr(2 * process_idx);
                    b := local_arr(2 * process_idx + 1);

                    sum_ab  := resize(a, 17) + resize(b, 17);
                    diff_ab := resize(a, 17) - resize(b, 17);

                    sum_product_ab  := sum_ab  * to_signed(23170, 17);
                    diff_product_ab := diff_ab * to_signed(23170, 17);

                    approx_temp(process_idx) := resize(shift_right(sum_product_ab,  15), 33);
                    detail_temp(process_idx) := resize(shift_right(diff_product_ab, 15), 33);

                    local_arr(process_idx)        := resize(approx_temp(process_idx), 16);
                    local_arr(half + process_idx) := resize(detail_temp(process_idx), 16);

                    -- PROBE: butterfly inputs and outputs this cycle
                    probe_a      <= a;
                    probe_b      <= b;
                    probe_sum    <= sum_ab;
                    probe_diff   <= diff_ab;
                    probe_approx <= resize(approx_temp(process_idx), 16);
                    probe_detail <= resize(detail_temp(process_idx), 16);

                    process_idx := process_idx + 1;

                else
                    -- level complete: snapshot first 4 entries of local_arr
                    case level_count is
                        when 0 =>
                            probe_after_lvl0_0 <= local_arr(0);
                            probe_after_lvl0_1 <= local_arr(1);
                            probe_after_lvl0_2 <= local_arr(2);
                            probe_after_lvl0_3 <= local_arr(3);
                            --report "Level 0 done: local_arr(0)=" &
                            --       integer'image(to_integer(local_arr(0))) &
                            --       " (1)=" & integer'image(to_integer(local_arr(1))) &
                            --       " (2)=" & integer'image(to_integer(local_arr(2))) &
                            --       " (3)=" & integer'image(to_integer(local_arr(3)))
                            --severity note;
                        when 1 =>
                            probe_after_lvl1_0 <= local_arr(0);
                            probe_after_lvl1_1 <= local_arr(1);
                            probe_after_lvl1_2 <= local_arr(2);
                            probe_after_lvl1_3 <= local_arr(3);
                            
                        when 2 =>
                            probe_after_lvl2_0 <= local_arr(0);
                            probe_after_lvl2_1 <= local_arr(1);
                            probe_after_lvl2_2 <= local_arr(2);
                            probe_after_lvl2_3 <= local_arr(3);
                            report "Level 2 done: local_arr(0)=" &
                                   integer'image(to_integer(local_arr(0))) &
                                   " (1)=" & integer'image(to_integer(local_arr(1))) &
                                   " (2)=" & integer'image(to_integer(local_arr(2))) &
                                   " (3)=" & integer'image(to_integer(local_arr(3)))
                            severity note;
                        when 3 =>
                            probe_after_lvl3_0 <= local_arr(0);
                            probe_after_lvl3_1 <= local_arr(1);
                            probe_after_lvl3_2 <= local_arr(2);
                            probe_after_lvl3_3 <= local_arr(3);
                            report "Level 3 done: local_arr(0)=" &
                                   integer'image(to_integer(local_arr(0))) &
                                   " (1)=" & integer'image(to_integer(local_arr(1))) &
                                   " (2)=" & integer'image(to_integer(local_arr(2))) &
                                   " (3)=" & integer'image(to_integer(local_arr(3)))
                            severity note;
                        when others => null;
                    end case;

                    half        := half / 2;
                    level_count := level_count + 1;
                    process_idx := 0;
                end if;

            else
                -- all 4 levels done: copy to buffer_arr
                for idx in 0 to 255 loop
                    buffer_arr(idx) := local_arr(idx);
                end loop;

                -- PROBE: first 8 buffer entries after copy
                probe_buf_0 <= buffer_arr(0);
                probe_buf_1 <= buffer_arr(1);
                probe_buf_2 <= buffer_arr(2);
                probe_buf_2 <= buffer_arr(2);
                probe_buf_3 <= buffer_arr(3);
                probe_buf_4 <= buffer_arr(4);
                probe_buf_5 <= buffer_arr(5);
                probe_buf_6 <= buffer_arr(6);
                probe_buf_7 <= buffer_arr(7);

                report "COPY done: buffer_arr(0)=" &
                       integer'image(to_integer(buffer_arr(0))) &
                       " (1)=" & integer'image(to_integer(buffer_arr(1))) &
                       " (2)=" & integer'image(to_integer(buffer_arr(2))) &
                       " (3)=" & integer'image(to_integer(buffer_arr(3)))
                severity note;

                process_idx := 0;
                state       <= THRESHOLD;
            end if;

        -- ----------------------------------------------------------------
        when THRESHOLD =>
    if process_idx < 256 then
        
        if process_idx < 16 then
            -- approximation band (indices 0..15)
            -- zero beyond what real samples contribute
            if process_idx >= real_approx_coeffs then
                buffer_arr(process_idx) := (others => '0');
                probe_thresh_kept <= '0';
            else
                coefficient := abs(buffer_arr(process_idx));
                total_bits_used := nonzero(coefficient) + total_bits_used;
                probe_thresh_idx   <= process_idx;
                probe_thresh_coeff <= coefficient;
                if coefficient <= thresh then
                    buffer_arr(process_idx) := (others => '0');
                    probe_thresh_kept <= '0';
                else
                    probe_thresh_kept <= '1';
                    report "THRESHOLD keep approx: idx=" &
                           integer'image(process_idx) &
                           "  coeff=" & integer'image(to_integer(coefficient))
                    severity note;
                end if;
            end if;
            
        else
            -- detail bands (indices 16..127)
            -- threshold only, no zeroing by index
            coefficient := abs(buffer_arr(process_idx));
            total_bits_used := nonzero(coefficient) + total_bits_used;
            probe_thresh_idx   <= process_idx;
            probe_thresh_coeff <= coefficient;
            if coefficient <= thresh then
                buffer_arr(process_idx) := (others => '0');
                probe_thresh_kept <= '0';
            else
                probe_thresh_kept <= '1';
                report "THRESHOLD keep detail: idx=" &
                       integer'image(process_idx) &
                       "  coeff=" & integer'image(to_integer(coefficient))
                severity note;
            end if;
        end if;
        
        process_idx := process_idx + 1;
    else
        report "THRESHOLD done. total_bits_used=" &
               integer'image(total_bits_used)
        severity note;
        state <= DONE;
    end if;

        -- ----------------------------------------------------------------
        --uncomment
        --when DONE =>
          --  coeff_array_valid <= '1';
          --  total_bits_reg    <= total_bits_used;
          --  coeff             <= buffer_arr;
          --  state <= IDLE;
          --  state <= WAIT_ACK;
             --PROBE: final output
          --  probe_coeff_0 <= buffer_arr(0);
          --  probe_coeff_1 <= buffer_arr(1);
          --  probe_coeff_2 <= buffer_arr(2);
          --  probe_coeff_3 <= buffer_arr(3);


        when DONE =>
    coeff_array_valid <= '1';
    total_bits_reg    <= total_bits_used;
    coeff             <= buffer_arr;
    state             <= WAIT_ACK;

    -- dump nonzero coefficients to transcript
    report "SEG_START," & integer'image(total_bits_used) & "," & integer'image(real_coeffs)
    severity note;
    
    for i in 0 to 255 loop
        if buffer_arr(i) /= 0 then
            report "COEFF," & integer'image(i) & "," & integer'image(to_integer(buffer_arr(i)))
            severity note;
        end if;
    end loop;
    
    report "SEG_END"
    severity note;

       when WAIT_ACK =>
       coeff_array_valid <= '1';
       report "WAIT_ACK: compress_data=" & std_logic'image(compress_data) 
       severity note;
        if compress_data = '0' then
                
                state <= IDLE;
            end if;
            
    end case;
    end if;
    end process;

end Behavioral;
