----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/19/2026 05:52:07 PM
-- Design Name: 
-- Module Name: types_pkg - Behavioral
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types_pkg is

    type output_array is array (0 to 1023) of unsigned(15 downto 0);
    
    type output_larray is array (0 to 71) of unsigned(15 downto 0);
    
    type samples_array is array (0 to 71) of signed(15 downto 0);
    
    type array9 is array (0 to 511) of signed(32 downto 0);
    
    type valStore is array (0 to 2) of signed(15 downto 0);
    
    type dataStore is array (0 to 255) of signed(15 downto 0);
    
    type halfdataStore is array (0 to 127) of signed(15 downto 0);
    
    type maBuffer is array (0 to 179) of signed(31 downto 0);
    
    type array9a is array (0 to 511) of signed(15 downto 0);
    
    type array10 is array (0 to 1023) of signed(15 downto 0);

end package;

package body types_pkg is
end package body;
