----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/16/2026 01:58:08 PM
-- Design Name: 
-- Module Name: adapLogic - Behavioral
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
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity adapLogic is
   Port (Clock: in std_logic;
         start: in std_logic;
         start_addr: out std_logic_vector(16 downto 0);
         end_addr: out std_logic_vector(16 downto 0));
end adapLogic;

architecture Behavioral of adapLogic is

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
    
    -- bandpass filter 
    -- first-order low-pass IIR filter to smooth signal and remove low freq noise with
    -- high pass filter to remove baseline drift
    function bandPass (sample: signed; hp: signed ; lp: signed) return valStore is 
    variable low_pass : signed(15 downto 0) := lp;
    variable high_pass : signed(15 downto 0) := hp;
    variable out_p : signed(15 downto 0)  ;
    variable result: valStore;
    begin
        low_pass := low_pass + shift_right((sample - low_pass), 3 );
        out_p := low_pass - high_pass;
        high_pass := high_pass +  shift_right(out_p, 5);
        result(0) := out_p;
        result(1) := low_pass;
        result(2) := high_pass;
        
        return result;
    end function;
    
    -- to store moving average data
    type ma_result is record
        avg: signed (31 downto 0);
        buf: maBuffer;
        idx:  integer range 0 to 15;
        sum : signed(63 downto 0);
    end record;
    
    function movingAverage (sample: signed(31 downto 0); buf_in: maBuffer; ma_i:integer; sum:signed(63 downto 0)) return ma_result is
    variable m_buffer: maBuffer:= buf_in;
    variable old : signed(31 downto 0);
    variable m_idx : integer range 0 to 15:= ma_i;
    variable m_sum: signed(63 downto 0):= sum;
    variable m_len: integer:= 16;
    variable m_a: signed(31 downto 0);
    variable result: ma_result;
    begin
        old:= m_buffer(ma_i);
        m_sum:= m_sum - old + sample;
        m_buffer(ma_i) := sample;
        m_idx := m_idx + 1;
        
        if m_idx >= m_len then
            m_idx := 0;
        end if;
        
        m_sum:= shift_right(m_sum, 4);
        m_a:= resize(m_sum,32);
        result.avg := m_a;
        result.buf := m_buffer;
        result.idx := m_idx;
        result.sum := m_sum;
        return result;
    end function;
    
        -- BRAM signals A 
    signal  dina_1, douta_1 : std_logic_vector (15 downto 0);
    signal wea_1: std_logic_vector(0 DOWNTO 0):= "0";
    signal addra_1: STD_LOGIC_VECTOR (16 downto 0):=(others => '0');
    signal  E: std_logic:= '0';
    
        -- BRAM signals B
    signal  dinb_1, doutb_1 : std_logic_vector (15 downto 0);
    signal web_1: std_logic_vector(0 DOWNTO 0):= "0";
    signal addrb_1: STD_LOGIC_VECTOR (16 downto 0):=(others => '0');
    signal  E_b: std_logic:= '0';
    
    -- state machine for k estimation
    type state_type is (IDLE, READY, COMPUTE, QRS, DONE);
    signal state: state_type := IDLE;
    
begin
    ram: bram_ecg port map(clka=>Clock,
                        wea => wea_1,
                        ena => E,
                        addra => addra_1,
                        dina => dina_1,
                        douta => douta_1,
                        clkb => Clock,
                        enb => E_b,
                        web => web_1,
                        addrb => addrb_1,
                        dinb => dinb_1,
                        doutb => doutb_1);
     
    
    process(Clock)
    variable stored_values: valStore;
    variable vsample : signed(15 downto 0) ;
    variable vlow_pass : signed(15 downto 0) ;
    variable vhigh_pass : signed(15 downto 0);
    variable cycle_count : integer;
    variable read_addr: unsigned(16 downto 0)  := (others => '0');
    
    --tkeo
    variable v_sampleC : signed(15 downto 0);
    variable v_x1 : signed(15 downto 0);
    variable v_x2: signed(15 downto 0);
    variable v_energy : signed(31 downto 0);
    
    -- moving average
    variable v_buf: maBuffer;
    variable v_idx: integer range 0 to 15;
    variable v_sum: signed(63 downto 0);
    variable v_result: ma_result;
    variable v_smooth: signed(31 downto 0);
    
    --threshold 
    variable v_threshold: signed(31 downto 0);
    variable v_refcount: integer;
    variable v_peak: std_logic;
    variable v_refractory: integer;
    
    -- qrs
    variable v_max_left: integer;
    variable v_max_right: integer;
    variable qrs_idx: integer;
    variable left_start: integer;
    variable right_end: integer;
    variable q_onset: integer;
    variable s_offset: integer;
    variable max_idx: integer;
    
    begin
    if rising_edge(Clock) then
        case state is
                 when IDLE =>
                     E <= '0'; -- bram not enable
                     E_b <= '0';
                     web_1 <= "0";
                     dinb_1 <= (others => '0');
                     cycle_count:= 0;
                     stored_values := (others =>(others => '0'));
                     vsample := (others => '0');
                     
                     
                     -- tkeo init
                     vlow_pass :=(others => '0');
                     vhigh_pass := (others => '0');
                     v_refractory:= 72;
                     v_sampleC := (others => '0');
                     v_x1 := (others => '0');
                     v_x2:= (others => '0');
                     v_energy := (others => '0');
                     
                     -- moving average
                    v_buf := (others =>(others => '0'));
                     v_idx := 0 ;
                     v_sum:= (others => '0');
                     v_result  := (avg => (others => '0'),
                                   buf => (others =>(others => '0')),
                                   idx => 0,
                                   sum => (others => '0'));
                     v_smooth:= (others => '0');
                    
                    --threshold 
                     v_threshold:= (others => '0');
                     v_refcount:= 0;
                     v_peak:= '0';
                     
    
                     -- QRS boundary
                     v_max_left:= 28;
                     v_max_right:= 43;
                     qrs_idx:= 0;
                     left_start:= 0;
                     right_end:= 0;
                     q_onset:= 0;
                     max_idx:= 138239; -- from calculation of bram size
                     
                     if start = '0' then  
                        read_addr:= (others => '0');
                        state <= READY;
                     end if;
                
                when READY =>
                    E <= '1';
                    E_b <= '0';
                    web_1 <= "0";
                    addra_1 <= std_logic_vector(read_addr);
                    read_addr := read_addr + 1;
                    cycle_count := cycle_count + 1;
                    
                    -- Just fill BRAM pipeline (2 cycles)
                    if cycle_count >= 3 then
                        state <= COMPUTE;
                    end if;

            when COMPUTE =>
                if read_addr <= 1023 then
                    E <= '1';
                    addra_1 <= std_logic_vector(read_addr);
                    read_addr := read_addr + 1;
                else
                    E <= '0';
                end if;
                
                -- Process current data (always valid after READY)
                --v_current := signed(douta_1);
                
                -- smooth the signal and remove noise 
                stored_values := bandPass(signed(douta_1),vlow_pass, vhigh_pass);
                vsample := stored_values(0);
                vlow_pass := stored_values(1);
                vhigh_pass := stored_values(2);
                
                
                -- tkeo : peak calculation
                
                --v_sampleC := resize(vsample, 32) ;
                v_sampleC := vsample;
                v_energy := resize(abs(v_sampleC * v_sampleC - v_x1 * v_x2), 32);
                v_x2 := v_x1;
                v_x1 := v_sampleC;
                
                -- moving average
                v_result := movingAverage(v_energy, v_buf, v_idx, v_sum);
                v_smooth := v_result.avg;
                v_buf := v_result.buf;
                v_idx :=  v_result.idx;
                v_sum := v_result.sum;
                
                --threshold and peak detection
                v_threshold := shift_right(v_smooth - v_threshold,7);
                v_peak := '0';
                
                if v_refcount > 0 then
                    v_refcount := v_refcount - 1;
                elsif v_smooth > 3 * v_threshold then
                    v_peak := '1';
                    v_refcount := v_refractory;
                end if;
                
                cycle_count := cycle_count + 1;
                
                if v_peak = '1' then
                    state <= QRS;
                end if;
                    
         when QRS =>
            qrs_idx := cycle_count - 3;  -- check value 
            if qrs_idx - v_max_left > 0 then
                left_start := qrs_idx - v_max_left ;
            else 
                left_start:= 0;
            end if;
            
            if qrs_idx + v_max_right < max_idx then
                left_start := qrs_idx + v_max_right ;
            else 
                left_start:= max_idx;
            end if; 
            
            q_onset:= left_start;
            s_offset := right_end;
            
            start_addr <= std_logic_vector(to_unsigned(q_onset - 1,17)); -- zero indexing
            end_addr <= std_logic_vector(to_unsigned(s_offset - 1,17));
            
            state <= COMPUTE;
            
            when DONE =>
                state <= IDLE;
        end case;            
    end if;
    end process;


end Behavioral;
