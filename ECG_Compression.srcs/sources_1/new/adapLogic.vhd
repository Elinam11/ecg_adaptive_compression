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
    
    component hwt is
      Port ( Clk: in std_logic;
             compress_data : in std_logic; -- same as hwt_start 
             ecg_samples : in dataStore;
             real_samples : in integer;
            coeff_array_valid: out std_logic;
            coeff: out dataStore);
    end component hwt;

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
        
       
        result.avg := resize(shift_right(m_sum, 4),32);
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
    
    -- hwt compression
    signal n_real : integer := 0 ;
    signal is_partial  : std_logic := '0' ;
    -- state machine for k estimation
    type state_type is (IDLE, READY, SEG_WAIT, COMPUTE, QRS, SEG_HWT_START, LOAD_BLOCK, WAIT_HWT, NEXT_BLOCK,DONE);
    signal state: state_type := IDLE;
    
    -- non qrs samples
    signal block_size :integer := 256;
    signal block_count :integer range 0 to 1023 := 0;
    signal full_blocks :integer range 0 to 1023 := 0;
    signal remainder :integer range 0 to 255 := 0;
    signal lossy_start_addr : std_logic_vector(16 downto 0):= (others => '0');
    signal lossy_end_addr : std_logic_vector(16 downto 0):= (others => '0');
    signal hwt_start : std_logic := '0';
    signal coeff_valid: std_logic := '0';
    signal lossy_block: dataStore;
    signal coeff_array: dataStore;
    
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
     
     lossy_compressor: hwt port map( Clk => Clock,
                                     compress_data =>hwt_start, -- same as hwt_start 
                                     ecg_samples => lossy_block,
                                     real_samples => n_real,
                                    coeff_array_valid => coeff_valid,
                                    coeff => coeff_array);
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
    variable q_onseto: integer;
    variable s_offseto: integer;
    variable max_idx: integer;
    variable qrs_count: integer;
    
    --hwt
    variable n_samples :std_logic_vector(16 downto 0);
    variable lossy_block_data: dataStore;
    variable acc_count: integer := 0;
    variable v_block_size :integer := 0;
    variable v_lossy_start :integer := 0;
    variable v_lossy_end :integer := 0;
    variable v_block_count : integer := 0;
    variable v_full_blocks : integer := 0;
    variable v_remainder :integer range 0 to 255 := 0;
    
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
                     max_idx:= 131071 ; -- from calculation of bram size
                     
                     --hwt
                     qrs_count:= 0;
                     lossy_block <= (others =>(others => '0'));
                     lossy_block_data := (others =>(others => '0'));
                     
                     
                     if start = '1' then  
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
                --state <= QRS;  -- delete
                if read_addr <= 131072 then
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
                v_threshold := v_threshold + shift_right(v_smooth - v_threshold,7);
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
                    
                -- compress final non-QRS segment
                elsif cycle_count >= 131072 + 4 then
                    
                    v_lossy_start := s_offset - 2; -- -2 for zero indexing and to avoid final S sample
                    v_lossy_end := 131072; -- last address
                    
                -- guard from negatives
                if v_lossy_end > v_lossy_start then
                    lossy_start_addr <= std_logic_vector(to_unsigned(v_lossy_start,17)); -- -2 for zero indexing and to avoid final S sample
                    lossy_end_addr <= std_logic_vector(to_unsigned(v_lossy_end,17));
                    n_samples := std_logic_vector(to_unsigned(v_lossy_end - v_lossy_start,17));
                    state <= SEG_HWT_START;
                else
                    state <= DONE; 
                end if;
            
                end if;
                    
         when QRS =>
            E_b <= '0';
            qrs_idx := cycle_count - 3;  -- check value 
            if qrs_idx - v_max_left > 0 then
                left_start := qrs_idx - v_max_left ;
            else 
                left_start:= 0;
            end if;
            
            if qrs_idx + v_max_right < max_idx then
                right_end := qrs_idx + v_max_right ;
            else 
                right_end:= max_idx;
            end if; 
            
            -- store past indices of Q and S
            q_onseto:= q_onset;
            s_offseto:= s_offset;
            
            q_onset:= left_start;
            s_offset := right_end;
            
            start_addr <= std_logic_vector(to_unsigned(q_onset ,17)); -- zero indexing
            end_addr <= std_logic_vector(to_unsigned(s_offset ,17));
            -- n_samples:= to_integer(start_addr - end_addr);
            
            
            -- send QRS TO LOSSLESS
            
            -- send non QRS TO HWT 
            
            -- if begining send first sample to Q to this state and not q onset is not addr o
            if qrs_count = 0 then
                v_lossy_start := 0;
                
                if q_onset > 2 then
                    v_lossy_end := q_onset - 2; -- -2 for zero indexing and to avoid first Q sample
                else
                    v_lossy_end := 0;
                end if;
            
            -- if end -- s detected is less than 256 from , check if there is another r peak last index
            elsif cycle_count >= 131072  + 4 and (s_offset /= 131072 ) then
                if s_offset > 2 then 
                    v_lossy_start := s_offset - 2; -- -2 for zero indexing and to avoid final S sample
                else
                    v_lossy_start := 0;
                end if;
                v_lossy_end := 131072; -- last address
                
                
            -- if middle send past s index and current q
            else
                if s_offseto > 2 then
                    v_lossy_start := s_offseto -2 ;
                else
                    v_lossy_start:= 0;
                end if;
                
                if q_onset > 2 then
                    v_lossy_end := q_onset - 2; -- -2 for zero indexing and to avoid first Q sample
                else
                    v_lossy_end:= 0;
                end if;
            end if;
            
            lossy_start_addr <= std_logic_vector(to_unsigned(v_lossy_start,17)); -- -2 for zero indexing and to avoid final S sample
            lossy_end_addr <= std_logic_vector(to_unsigned(v_lossy_end,17));
            
            --v_lossy_start := 0;
             --v_lossy_end   := 37;
             --lossy_start_addr <= std_logic_vector(to_unsigned(v_lossy_start,17));
             --lossy_end_addr <= std_logic_vector(to_unsigned(v_lossy_end,17));
            -- guard from negatives
            if v_lossy_end > v_lossy_start then
                n_samples := std_logic_vector(to_unsigned(v_lossy_end - v_lossy_start,17));
            else
                n_samples := (others => '0');
            end if;
            qrs_count := qrs_count + 1;
            state <= SEG_HWT_START;
            
            when SEG_HWT_START =>
                full_blocks <= to_integer(unsigned(n_samples(15 downto 8)));
                remainder <= to_integer(unsigned(n_samples(7 downto 0)));
                block_count <= 0;
                v_block_count := 0;
                v_full_blocks := to_integer(unsigned(n_samples(15 downto 8)));
                v_remainder := to_integer(unsigned(n_samples(7 downto 0)));
                lossy_block_data := (others => (others => '0'));
                acc_count := 0;
                state <= LOAD_BLOCK;
            
            when LOAD_BLOCK =>
                E_b <= '1';
                
                -- determine block actual size
                if v_block_count < v_full_blocks then
                    v_block_size:= 256;
                else
                    v_block_size := v_remainder;
                end if;
                
                -- make sure it is within non qrs and don't waste memory access
                if acc_count < (v_lossy_end - v_lossy_start) then -- to_integer(unsigned(n_samples)) 
                    addrb_1 <= std_logic_vector(signed(lossy_start_addr) + to_signed(v_block_count*256 + acc_count,17));
                    
                 end if;   
                 
                --load data into hwt block if it was within non QRS start and end
                if acc_count >= 4 and acc_count < v_block_size + 4 then -- changed to 3
                    
                    lossy_block_data(acc_count - 4):= signed(doutb_1);
                    
                     -- lossy_block_data(acc_count - 2) := to_signed(1000,16);
                    
                end if;
                
                -- on the last iteration to fill the block set these variables
                if acc_count >= v_block_size + 4 then  -- changed to 3
                        
                        report "Pre-HWT: lossy_block_data(37)=" & 
                               integer'image(to_integer(lossy_block_data(37))) &
                               " (38)=" & integer'image(to_integer(lossy_block_data(38))) &
                               " (39)=" & integer'image(to_integer(lossy_block_data(39)))
                        severity note;
                        if v_block_count = v_full_blocks then
                            is_partial <= '1';
                        else
                            is_partial <= '0';
                        end if; 
                        
                        if v_block_size > 0 then
                            n_real <= v_block_size;
                        -- is_partial <= '1' if block_count = full_blocks else '0';
                        lossy_block <= lossy_block_data;
                        
                        acc_count := 0;
                        state <= SEG_WAIT; --WAIT_HWT;
                        else 
                        acc_count := 0;
                        state <= NEXT_BLOCK;
                        end if;
                     
                 end if;
                acc_count := acc_count + 1;
                
            when SEG_WAIT =>
                hwt_start <= '1';
                state <= WAIT_HWT;
                
            when WAIT_HWT =>
                
                hwt_start <= '0';
                
                --report "WAIT_HWT: coeff_valid=" & std_logic'image(coeff_valid) &
           --" hwt_start was cleared"
    --severity note;
                if coeff_valid = '1' then
                    -- send it to packetizer 
                    
                    -- go to the next detected block
                    
                    state <= NEXT_BLOCK;
                   
                 end if;
                 
            when NEXT_BLOCK =>
                lossy_block_data := (others =>(others => '0'));
                if v_block_count < v_full_blocks then 
                    v_block_count := v_block_count + 1;
                    block_count <= block_count + 1;
                    state <= LOAD_BLOCK;
                    
                -- process last block    
                elsif v_remainder > 0 and is_partial = '0' then
                    v_block_count := v_full_blocks;
                     block_count <= full_blocks;
                    state <= LOAD_BLOCK;
                else
                    if cycle_count >= 131072  + 4 then
                        state <= DONE;
                    else 
                        state <= COMPUTE;
                    end if;
                end if ;
                    
            when DONE =>
                
                state <= IDLE;
        end case;            
    end if;
    end process;


end Behavioral;
