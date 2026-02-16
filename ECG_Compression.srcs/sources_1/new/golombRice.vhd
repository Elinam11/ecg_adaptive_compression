----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/08/2026 11:41:12 PM
-- Design Name: 
-- Module Name: golombRice - Behavioral
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
--library work;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use work.my_btypes.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity golombRice is
    Port (Sample: in STD_LOGIC;
          --Buffer2: in b16array3;
          encodedE: out unsigned(15 downto 0);
          q_r: out STD_LOGIC_VECTOR(15 downto 0);
          Clk: in std_logic);
end golombRice;

architecture Behavioral of golombRice is

    COMPONENT bram_ecg IS
      PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        clkb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addrb : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
        dinb : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
      );
    END COMPONENT bram_ecg;

    
    component mappingToUnsigned is
        Port ( A : in signed (15 downto 0);
               Z : out unsigned (15 downto 0));
    end component mappingToUnsigned;

     component kEstimator is
      Port ( Counter: in integer;
             Clock: in std_logic; 
             K_ready: out std_logic;
             K: out integer range 0  to 15);
    end component kEstimator;

    
    signal k_valid:  std_logic;
    -- linear predictor
    signal overflow : std_logic;
    signal predictedO : signed(15 downto 0);
    
    
    -- param K estimator
    -- signal paramK: unsigned(15 downto 0);
    signal paramK:integer;
    
        -- BRAM signals
    signal  dina_1, douta_1 : std_logic_vector (15 downto 0);
    signal wea_1: std_logic_vector(0 DOWNTO 0):= "0";
    signal addra_1: STD_LOGIC_VECTOR (16 downto 0):=(others => '0');
    signal  E: std_logic:= '0';
    
    
    -- BRAM signals B
    signal  dinb_1, doutb_1 : std_logic_vector (15 downto 0);
    signal web_1: std_logic_vector(0 DOWNTO 0):= "0";
    signal addrb_1: STD_LOGIC_VECTOR (16 downto 0):=(others => '0');
    signal  E_b: std_logic:= '0';

    --prediction error
    signal sampleShifted: signed(15 downto 0) ;
    signal  predictionErr: signed(15 downto 0);
    
    signal Counter : integer :=0;
    
    -- golomb 
    signal Q , R,  M_n0: std_logic_vector (15 downto 0);
    signal  M_n : signed(15 downto 0);
    signal  M_n_pos : unsigned(15 downto 0);
    signal pa_K : integer range 0 to 15  :=0;
    
    constant max_K_width: integer := 12;
    signal  stop_bit_sum: unsigned(max_K_width - 1 downto 0); 
    signal M_n1 : unsigned(31 downto 0); 
    
    -- state machine for compression
    type state_type is (IDLE, READY, COMPUTE, ENCODE, DONE);
    signal state: state_type := IDLE;
    
    -- address counter for iterating through BRAM
    signal addr_count: unsigned (16 downto 0):=(others => '0');
    
    -- for storing past 2 samples
    type b16array3 is array(2 downto 0) of std_logic_vector(15 downto 0);
    signal temp_buffer:  b16array3;
    
    
begin

    ram: bram_ecg port map(clka=>Clk,
                        wea => wea_1,
                        ena => E,
                        addra => addra_1,
                        dina => dina_1,
                        douta => douta_1,
                        clkb => Clk,
                        enb => E_b,
                        web => web_1,
                        addrb => addrb_1,
                        dinb => dinb_1,
                        doutb => doutb_1);
                        
    
    KE: kEstimator port map( Counter => Counter,
                             K_ready => k_valid,
                             Clock => Clk, 
                             K=> paramK);
                   
                                    
    Positive_num: mappingToUnsigned port map( A => M_n,
                                              Z => M_n_pos);
                                    
                                                       
    process(Clk)
    -- initialize counter variable 
        variable Counter_var : integer := 0; 
        variable read_addr : unsigned(16 downto 0)  := (others => '0');
        variable cycle_count : integer range  0 to 1100 := 0;
        
        begin 
        
       if rising_edge(Clk) then
       
        case state is 
            when IDLE =>
                     E <= '0'; -- bram not enable
                     E_b <= '0'; -- bram not enable
                     wea_1 <= "0";
                     Counter_var := 0; -- request for the  k
                     Counter <= Counter_var; 
                     read_addr := (others => '0');
                     cycle_count := 0;
                     
                     if k_valid = '1' then 
                        state <= READY;
                     END IF;
                     
             when READY =>
                E <= '1'; -- read enable
                cycle_count := cycle_count + 1;    
                addra_1 <= std_logic_vector(read_addr);
                
                if read_addr < 1023 then
                    read_addr:= read_addr + 1;
                end if;
                
                if cycle_count >= 2 and cycle_count < 1026 then
                       temp_buffer(0) <= temp_buffer(1) ;
                       temp_buffer(1) <= temp_buffer(2);
                       temp_buffer(2) <= douta_1;

                       
                END IF;
    
                if cycle_count >= 4 then
                    state <= COMPUTE;
                end if;
                
           when COMPUTE =>
                 
                 -- Linear 2nd Order Predictor       
                    -- pass into predictor
                    sampleShifted <= shift_left(signed(temp_buffer(2)),1);
                    predictedO <= sampleShifted - signed(temp_buffer(1));
                    -- calculate error from predicted and current
                    M_n <= signed(temp_buffer(0)) - predictedO;
                    
                    -- map to unsigned
                    -- write back to memory 
                    E_b <= '0'; -- bram not enable
                    addrb_1 <= std_logic_vector(unsigned(addra_1) - "00000000000000100");
                    web_1 <= "1";
                    dinb_1 <= std_logic_vector(M_n_pos);
                    -- done pointer for first k calculation
                    state <= ENCODE;
                    
          when ENCODE =>
      
             -- Golomb Rice Encoder          
             -- take k
                     
                -- find q and r 
                pa_K <= paramK;        
                Q <=  std_logic_vector(shift_right(M_n_pos , pa_K));
                
                M_n0 <= std_logic_vector(M_n_pos);
                -- mask lower bits
                R <= std_logic_vector(M_n_pos and (to_unsigned(2**pa_K -1 ,16)));
                
                -- output error
                M_n1 <= shift_left(resize(M_n_pos,32 ), pa_K + 1);
                encodedE <= unsigned(R) + M_n1(15 downto 0);
                
                -- store error
        
                -- put in function to say unless 123
                if Counter_var = 1023 then
                    -- send in next k function by seting counter in component
                    Counter_var := 0 ;
                    Counter <= Counter_var;
                    state <= DONE;
                else
                    Counter_var := Counter_var + 1;
                end if;
                
        when DONE =>
            -- Final state after processing all 1024 samples
            E <= '0';
            
            state <= IDLE;  -- Return to IDLE to wait for next k_valid
        
        
    end case;
            
   end if;     
        
  end process;
    
                    
end Behavioral;
