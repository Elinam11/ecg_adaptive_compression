----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/03/2026 05:17:26 PM
-- Design Name: 
-- Module Name: mappingToUnsigned - Behavioral
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

-- first part of Golom-rice encoder, converting signed into unsigned
entity mappingToUnsigned is
    Port ( A : in signed (15 downto 0);
           Z : out unsigned (15 downto 0));
end mappingToUnsigned;

architecture Behavioral of mappingToUnsigned is

signal absA , mult2A: signed(15 downto 0);
signal gcA : std_logic_vector(15 downto 0);
signal o: std_logic;

begin
  
    process(A)
        variable A_interim: signed(16 downto 0);
        variable Z_interim: unsigned(16 downto 0);
    begin
        A_interim := resize(A,17);
        if (A_interim  >= 0) then
            Z_interim := unsigned(shift_left(A_interim,1)); -- positive no
        
        else  
            Z_interim := unsigned(shift_left(-A_interim,1)-1);  --neg no
        
        end if;
    
        Z <= resize(Z_interim,16);
    end process;

end Behavioral;
