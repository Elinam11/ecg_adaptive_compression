----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/12/2026 02:30:23 PM
-- Design Name: 
-- Module Name: bram_test_tb - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bram_test_tb is
--  Port ( );
end bram_test_tb;

architecture Behavioral of bram_test_tb is
component bram_ecg IS
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END component bram_ecg;
    
    signal Clock_tb: std_logic:= '0';
    signal  dina_1, douta_1 : std_logic_vector (15 downto 0);
    signal wea_1: std_logic_vector(0 DOWNTO 0):= "0";
    signal addra_1: STD_LOGIC_VECTOR (16 downto 0):=(others => '0');
    signal  E: std_logic:= '0';
begin
    UUT: bram_ecg
    PORT MAP (
        clka => Clock_tb,
        ena => E,
        wea => wea_1,
        addra => addra_1,
        dina => dina_1,
        douta => douta_1
    );
    
    process
    begin
        
        Clock_tb <= not Clock_tb; wait for 10 ns;
        
    end process;
    
    process
    begin
    E <= '1';
    wea_1 <= "0";
    
    addra_1 <= "00000000000000001"; wait for 5 ns;
    addra_1 <= "00000000000000010"; wait for 5 ns;
    wait;
    end process;


end Behavioral;
