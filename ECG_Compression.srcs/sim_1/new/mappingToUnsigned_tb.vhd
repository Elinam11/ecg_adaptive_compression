----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/03/2026 06:23:25 PM
-- Design Name: 
-- Module Name: mappingToUnsigned_tb - Behavioral
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

entity mappingToUnsigned_tb is
end mappingToUnsigned_tb;

architecture Behavioral of mappingToUnsigned_tb is
    component mappingToUnsigned is
    Port ( A : in signed (15 downto 0);
           Z : out signed (15 downto 0));
    end component mappingToUnsigned;
    
    signal A_tb , Z_tb : signed (15 downto 0);
begin
    UUT: mappingToUnsigned port map(A=> A_tb ,
                                    Z => Z_tb);
    
    process
        begin
            A_tb <= "1010001001111110" ;
            wait for 10 ns;
            wait;
    end process;

end Behavioral;
