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
use std.textio.all;
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
        coeff_array_valid: out std_logic;
             coeff: out array9a);
end component hwt;

signal coeff_tb: array9a;
signal coeff_valid_tb: std_logic := '0';
signal Clk_tb: std_logic;
signal sim_done: boolean:= false;
constant CLK_PERIOD : time := 20 ns;

begin
    UUT: hwt port map ( Clock=> Clk_tb,
                        coeff_array_valid => coeff_valid_tb,
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
    
        process 
        file expected_file: text open read_mode is "C:/Users/elina/CapstoneVHDL/ECG_Compression/ECG_Compression.sim/sim_1/behav/xsim/hwt_coeffs_fixed.txt";
        variable expected_line : line;
        variable expected_val : integer;
        variable char: character;
        variable mismatches: integer := 0;
        variable good_read : boolean;
        variable vhdl_val : integer;
    begin
        -- Wait for compression to fully complete
        wait until coeff_valid_tb = '1';
        wait for 100 ns;  -- Extra safety margin
        
        report "========================================" severity note;
        report "Starting Python vs VHDL comparison..." severity note;
        report "========================================" severity note;
        
        -- Read Python expected values
        readline(expected_file, expected_line);
        
        -- Compare each value from the stored array
                for i in 0 to 511 loop
                read(expected_line, expected_val, good_read);
            
                -- Read VHDL value
                vhdl_val := to_integer(coeff_tb(i));
            
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
                
                if i < 511 then
                read(expected_line, char, good_read);
                end if ;
            end loop;
    
        
        -- Final report
        report "========================================" severity note;
        if mismatches = 0 then
            report "SUCCESS! All 512 encoded values match Python output!" severity note;
        else
            report "FAILED! " & integer'image(mismatches) & " mismatches found!" severity error;
        end if;
        report "========================================" severity note;
        
        file_close(expected_file);
        wait;
    end process;

end Behavioral;
