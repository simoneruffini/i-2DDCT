--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
--
-- Create Date:     Wed Jun  9 14:39:11 CEST 2021
-- Design Name:     I_DCT1D
-- Module Name:     I_DCT1D.vhd - RTL
-- Project Name:    iMDCT
-- Description:     intermittent 1D Discrete Cosine Transform (1st stage)
--
-- Revision:
-- Revision 00 - Simone Ruffini
--  * File Created
-- Additional Comments:
--
--------------------------------------------------------------------------------

----------------------------- PACKAGES/LIBRARIES -------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

-- User libraries

library WORK;
  use WORK.I_MDCT_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity I_DCT1D is
  port (
    CLK                     : in    std_logic;                                              -- Input clock
    RST                     : in    std_logic;                                              -- Positive reset
    DCTI                    : in    std_logic_vector(C_INDATA_W - 1 downto 0);              -- DCT input data
    IDV                     : in    std_logic;                                              -- Input data valid
    ----------------------------------------------------------
    ROME_ADDR               : out   rom1_addr_t;                                            -- ROME address output
    ROMO_ADDR               : out   rom1_addr_t;                                            -- ROMO address output
    ROME_DOUT               : in    rom1_data_t;                                            -- ROME data output
    ROMO_DOUT               : in    rom1_data_t;                                            -- ROMO data output
    ----------------------------------------------------------
    RAM_WADDR               : out   std_logic_vector(C_RAMADDR_W - 1 downto 0);             -- RAM write address output
    RAM_RADDR               : out   std_logic_vector(C_RAMADDR_W - 1 downto 0);             -- RAM write address output
    RAM_DIN                 : out   std_logic_vector(C_RAMDATA_W - 1 downto 0);             -- RAM data input
    RAM_DOUT                : in    std_logic_vector(C_RAMDATA_W - 1 downto 0);             -- RAM data input
    RAM_WE                  : out   std_logic;                                              -- RAM write enable
    ----------------------------------------------------------
    FRAME_CMPLT             : out   std_logic;                                              -- Write memory select signal
    -- Debug -------------------------------------------------
    ODV                     : out   std_logic;                                              -- Output data valid
    DCTO                    : out   std_logic_vector(C_1D_OUTDATA_W - 1 downto 0);          -- DCT data output
    ----------------------------------------------------------
    -- Intermittent Enhancment Ports -------------------------
    SYS_STATUS              : in    sys_status_t;                                           -- System status
    VARC_RDY                : out   std_logic                                               -- Volatile Architecture Ready
    ----------------------------------------------------------
  );
end entity I_DCT1D;

----------------------------- ARCHITECTURE -------------------------------------

architecture RTL of I_DCT1D is

  --########################### CONSTANTS 1 ####################################
  constant C_NV_DATA_BUF_DATA_W                     : natural := C_INDATA_W + 1;
  constant C_PIPELINE_STAGES                        : natural := 4;

  --########################### TYPES ##########################################

  type input_data is array (N - 1 downto 0) of signed(C_INDATA_W downto 0);                                               -- NOTE: C_INDATA_W not C_INDATA_W-1, one bit extra

  type ram_waddr_delay_t is array (natural range <>) of std_logic_vector(C_RAMADDR_W - 1 downto 0);

  -- I_DCT Main FSM states type

  type i_dct1d_m_fsm_t is (
    S_INIT,
    S_HALT,
    S_WAIT_DBUF_CMPLT,
    S_PUSH_CHKPNT_RAM,
    S_WAIT_PUSH_CHKPNT_V2NV,
    S_WAIT_PUSH_CHKPNT_NV2V,
    S_PULL_CHKPNT_RAM,
    S_RUN
  );

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################
  constant C_DCT1D_CHKP_IN_RAM_STRT_ADDR            : natural := (C_FRAME_SIZE - 1) + 1;                                  -- start address in ram where DCT1D state/checkpoint is saved
  constant C_DCT1D_CHKP_IN_RAM_OFST                 : natural := C_DCT1D_CHKPNT_RAM_SIZE - 1;                                 -- length of data saved in ram for DCT1D state/checkpoint: DBUF(N) + ROW_COL

  constant C_RAM_DBUF_STRT_ADDR                     : natural := C_DCT1D_CHKP_IN_RAM_STRT_ADDR;
  constant C_RAM_DBUF_OFST                          : natural := N - 1;
  constant C_RAM_ROW_COL_STRT_ADDR                  : natural := C_RAM_DBUF_STRT_ADDR + C_RAM_DBUF_OFST + 1;
  constant C_RAM_ROW_COL_OFST                       : natural := 0;

  --########################### SIGNALS ########################################

  signal m_pstate                                   : i_dct1d_m_fsm_t;                                                    -- I_DCT1D main fsm present state
  signal m_fstate                                   : i_dct1d_m_fsm_t;                                                    -- I_DCT1D main fsm future state

  signal push_chkpnt_ram_cmplt                      : std_logic;                                                          -- Push checkpoint data to RAM complete signal
  signal pull_chkpnt_ram_cmplt                      : std_logic;                                                          -- Pull checkpoint data from RAM complete signal

  signal varc_rdy_s                                 : std_logic;                                                          -- Volatile architecture ready signal
  signal i_dct_halt                                 : std_logic;                                                          -- Halt all idct
  signal i_dct_halt_input                           : std_logic;                                                          -- Halt only input stage of idct leaving rest working

  signal dbuf                                       : input_data;
  signal dcti_shift_reg                             : input_data;

  signal col_cnt                                    : unsigned(ilog2(C_FRAME_SIZE) / 2 - 1 downto 0);                     -- Counter for column positioning inside RAM
  signal row_cnt                                    : unsigned(ilog2(C_FRAME_SIZE) / 2 - 1 downto 0);                     -- Counter for row position inside RAM (transposition)
  signal inpt_cnt                                   : unsigned(ilog2(N) - 1 downto 0);                                    -- Counter for received input data

  signal ram_we_s                                   : std_logic;
  signal frame_cmplt_s                              : std_logic;
  signal stage2_start                               : std_logic;
  signal stage2_cnt                                 : unsigned (ilog2(N + 1) - 1 downto 0);                               -- Counter for stage2, needs to count N+1 values for init purposes
  signal col_cnt2                                   : unsigned(ilog2(C_FRAME_SIZE) / 2 - 1 downto 0);
  signal ram_waddr_s                                : std_logic_vector(C_RAMADDR_W - 1 downto 0);

  signal is_even                                    : std_logic;                                                          -- if is_even = '1' then this stage in the pipeline is computing an even row, else, if '0' an odd one.
  signal is_even_d                                  : std_logic_vector((C_PIPELINE_STAGES - 1) - 1 downto 0);
  signal ram_we_d                                   : std_logic_vector(C_PIPELINE_STAGES - 1 downto 0);
  signal ram_waddr_d                                : ram_waddr_delay_t (C_PIPELINE_STAGES - 1 downto 0);
  signal frame_cmplt_s_d                            : std_logic_vector(C_PIPELINE_STAGES - 1 downto 0);

  signal rome_dout_d1                               : rom1_data_t;
  signal romo_dout_d1                               : rom1_data_t;
  signal rome_dout_d2                               : rom1_data_t;
  signal romo_dout_d2                               : rom1_data_t;
  signal rome_dout_d3                               : rom1_data_t;
  signal romo_dout_d3                               : rom1_data_t;
  signal dcto_1                                     : std_logic_vector(C_PL1_DATA_W - 1 downto 0);
  signal dcto_2                                     : std_logic_vector(C_PL1_DATA_W - 1 downto 0);
  signal dcto_3                                     : std_logic_vector(C_PL1_DATA_W - 1 downto 0);
  signal dcto_4                                     : std_logic_vector(C_PL1_DATA_W - 1 downto 0);

  signal dbuf_cmplt_d                               : std_logic_vector((1 + C_PIPELINE_STAGES) - 1 downto 0);             -- Data Buffer Complete Delay : Once stage2_cnt = N-1 last data of dbuf goes first through ROM then in Pipleline and it's computation completes
  signal last_dbuf_cmplt                            : std_logic;                                                          -- LAST data buffer complete/computed and saved to ram

  signal push_chkpnt_to_ram_en                      : std_logic;                                                          -- Enalbe procedure that pushes current I_DCT1D status as a checkpoint to ram
  signal pull_chkpnt_from_ram_en                    : std_logic;                                                          -- Enable procedure that pulls checkpoint from ram and stores to I_DCT1D
  signal ram_xaddr_incr_en                          : std_logic;                                                          -- Enable increase of ram_Xaddr

  signal ram_xaddr_drct                             : unsigned (C_RAMADDR_W - 1 downto 0);                                -- When in direct mode (no I_DCT1D pipeline) either raddr or wadddr are drived not both, this signal is then mapped to the correct one
  signal ram_din_drct                               : std_logic_vector(C_RAMDATA_W - 1 downto 0);                         -- Direct signal from ram din
  signal ram_we_drct                                : std_logic;                                                          -- Direct signal to ram wirte enable, goes over I_DCT1D pipeline

  signal dbuf_from_ram                              : std_logic;                                                          -- Current data reqeuested from ram is dbuf
  signal dbuf_from_ram_d1                           : std_logic;                                                          -- Delay of above (used to compensate ram output delay)
  signal row_col_from_ram                           : std_logic;                                                          -- Current data requested from ram is row_col
  signal row_col_from_ram_d1                        : std_logic;                                                          -- Delay of above (used to compensate ram output delay)

  --########################### ARCHITECTURE BEGIN #############################

begin

  assert(C_RAM_DBUF_OFST + C_RAM_ROW_COL_OFST <= C_DCT1D_CHKP_IN_RAM_OFST)
    report "Values saved in ram use more space then available"
    severity failure;

  --########################### ENTITY DEFINITION ##############################

  --########################## OUTPUT PORTS WIRING #############################

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- multiplexers for direct drive of ram signals (during V2NV/NV2V ops)
  -- or DCT1D pipeline control

  RAM_WADDR <= ram_waddr_d(ram_waddr_d'length - 1) when push_chkpnt_to_ram_en = '0' else       -- 4 clock dealy
               std_logic_vector(ram_xaddr_drct);                                               -- address drived from push chkpnt procedure
  RAM_WE    <= ram_we_d(ram_we_d'length - 1) when push_chkpnt_to_ram_en = '0' else             -- 4 clock dealy
               ram_we_drct;                                                                    -- enable drived from push chkpnt
  RAM_DIN   <= dcto_4(C_PL1_DATA_W - 1 downto 12) when push_chkpnt_to_ram_en = '0' else        -- data from 4th pipleine stage
               ram_din_drct;                                                                   -- data drived from pull chkpnt procedure

  RAM_RADDR <= (others => '0') when pull_chkpnt_from_ram_en = '0' else
               std_logic_vector(ram_xaddr_drct);                                         -- address drived from pull chkpnt procedure

  ODV         <= ram_we_d(ram_we_d'length - 1);                       -- 4 clock dealy
  DCTO        <= std_logic_vector(resize(signed(dcto_4(C_PL1_DATA_W - 1 downto 12)), C_1D_OUTDATA_W));
  FRAME_CMPLT <= frame_cmplt_s_d(frame_cmplt_s_d'length - 1);         -- 4 clock delay
  VARC_RDY    <= varc_rdy_s;

  --########################## COBINATORIAL FUNCTIONS ##########################

  last_dbuf_cmplt <= dbuf_cmplt_d(dbuf_cmplt_d'length - 1);

  --########################## PROCESSES #######################################

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Sequential process for I_DCT MAIN fsm (synthesizes FFs)

  P_I_DCT_M_FSM_SEQ : process (CLK, RST) is
  begin

    if (RST = '1') then
      m_pstate <= S_INIT;
    elsif (CLK'event and CLK = '1') then
      m_pstate <= m_fstate;
    end if;

  end process P_I_DCT_M_FSM_SEQ;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Future state computation for I_DCT Main fsm (combinatorial process)

  P_I_DCT_M_FSM_FUT_S : process (m_pstate, SYS_STATUS, last_dbuf_cmplt, push_chkpnt_ram_cmplt, pull_chkpnt_ram_cmplt) is
  begin

    -- Default
    m_fstate <= m_pstate;

    case m_pstate is

      when S_INIT =>
        m_fstate <= S_HALT;
      when S_HALT =>

        case SYS_STATUS is

          when SYS_HALT =>
            m_fstate <= S_HALT;
          when SYS_VARC_PREP_CHKPNT =>

            if (last_dbuf_cmplt='1') then
              m_fstate <= S_PUSH_CHKPNT_RAM;
            else
              m_fstate <= S_WAIT_DBUF_CMPLT;
            end if;

          when SYS_PUSH_CHKPNT_V2NV =>
            m_fstate <= S_WAIT_PUSH_CHKPNT_V2NV;
          when SYS_PUSH_CHKPNT_NV2V =>
            m_fstate <= S_WAIT_PUSH_CHKPNT_NV2V;
          when SYS_VARC_INIT_CHKPNT =>
            m_fstate <= S_PULL_CHKPNT_RAM;
          when SYS_RUN =>
            m_fstate <= S_RUN;

        end case;

      when S_WAIT_DBUF_CMPLT =>

        if (last_dbuf_cmplt='1') then
          m_fstate <= S_PUSH_CHKPNT_RAM;
        end if;

      when S_PUSH_CHKPNT_RAM =>

        if (push_chkpnt_ram_cmplt = '1') then
          m_fstate <= S_HALT;
        end if;

      when S_WAIT_PUSH_CHKPNT_V2NV =>

        if (SYS_STATUS /= SYS_PUSH_CHKPNT_V2NV) then
          m_fstate <= S_HALT;
        end if;

      when S_WAIT_PUSH_CHKPNT_NV2V =>

        if (SYS_STATUS /= SYS_PUSH_CHKPNT_NV2V) then
          m_fstate <= S_HALT;
        end if;

      when S_PULL_CHKPNT_RAM =>

        if (pull_chkpnt_ram_cmplt = '1') then
          m_fstate <= S_HALT;
        end if;

      when S_RUN =>

        if (SYS_STATUS /= SYS_RUN) then
          m_fstate <= S_HALT;
        end if;

    end case;

  end process P_I_DCT_M_FSM_FUT_S;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Output generator for I_DCT Main fsm (mealy machine)

  P_I_DCT_M_FSM_OUTPUTS : process (m_pstate, SYS_STATUS, push_chkpnt_ram_cmplt, pull_chkpnt_ram_cmplt) is
  begin

    -- defaults
    -- By defining them the synthesizer produces a combinatrial logic without FFs
    varc_rdy_s       <= '0';
    i_dct_halt       <= '1';
    i_dct_halt_input <= '0';

    case m_pstate is

      when S_INIT =>
      when S_HALT =>
        i_dct_halt <= '1';
      when S_WAIT_DBUF_CMPLT =>
        i_dct_halt       <= '0';
        i_dct_halt_input <= '1';
      when S_PUSH_CHKPNT_RAM =>

        if (push_chkpnt_ram_cmplt = '1') then
          varc_rdy_s <= '1';
        end if;

      when S_WAIT_PUSH_CHKPNT_V2NV =>
        varc_rdy_s <= '1';

        if (SYS_STATUS/= SYS_PUSH_CHKPNT_V2NV) then
          varc_rdy_s <= '0';
        end if;

      when S_WAIT_PUSH_CHKPNT_NV2V =>
        varc_rdy_s <= '1';

        if (SYS_STATUS/= SYS_PUSH_CHKPNT_NV2V) then
          varc_rdy_s <= '0';
        end if;

      when S_PULL_CHKPNT_RAM =>

        if (pull_chkpnt_ram_cmplt = '1') then
          varc_rdy_s <= '1';
        end if;

      when S_RUN =>
        i_dct_halt <= '0';

    end case;

  end process P_I_DCT_M_FSM_OUTPUTS;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Data buffer latch and control signal mangaer

  P_DATA_BUF_AND_CTRL : process (CLK, RST) is
  begin

    if (RST = '1') then
      inpt_cnt       <= (others => '0');
      dcti_shift_reg <= (others => (others => '0'));
      dbuf           <= (others => (others => '0'));
      stage2_start   <= '0';

      stage2_cnt <= (others => '1');                                                                                -- NOTE: stage2_cnt starts from a number greater then N-1, if it started from 0 it triggers 2stage prematurely
      col_cnt    <= (others => '0');
      col_cnt2   <= (others => '0');
      row_cnt    <= (others => '0');

      frame_cmplt_s <= '0';
      ram_we_s      <= '0';
      ram_waddr_s   <= (others => '0');

      pull_chkpnt_ram_cmplt <= '0';
      push_chkpnt_ram_cmplt <= '0';

      pull_chkpnt_from_ram_en <= '0';
      push_chkpnt_to_ram_en   <= '0';
      ram_xaddr_incr_en       <= '0';

      ram_xaddr_drct <= (others => '0');
      ram_we_drct    <= '0';
      ram_din_drct   <= (others => '0');

      dbuf_from_ram       <= '0';
      dbuf_from_ram_d1    <= '0';
      row_col_from_ram    <= '0';
      row_col_from_ram_d1 <= '0';
    elsif (CLK = '1' and CLK'event) then
      -- Global Defaults
      pull_chkpnt_ram_cmplt <= '0';
      push_chkpnt_ram_cmplt <= '0';

      if (i_dct_halt = '1') then
        -- Enable PULL/PUSH checkpoint procedure
        if (m_pstate = S_PULL_CHKPNT_RAM AND pull_chkpnt_from_ram_en = '0') then
          pull_chkpnt_from_ram_en <= '1';
          ram_xaddr_drct          <= to_unsigned(C_DCT1D_CHKP_IN_RAM_STRT_ADDR, ram_xaddr_drct'length);
        elsif (m_pstate = S_PUSH_CHKPNT_RAM AND push_chkpnt_to_ram_en = '0') then
          push_chkpnt_to_ram_en <= '1';
          ram_xaddr_drct        <= to_unsigned(C_DCT1D_CHKP_IN_RAM_STRT_ADDR, ram_xaddr_drct'length);
        end if;

        -- Ram address caclucator
        if (ram_xaddr_incr_en = '1') then
          if (to_integer(ram_xaddr_drct) < C_DCT1D_CHKP_IN_RAM_STRT_ADDR + C_DCT1D_CHKP_IN_RAM_OFST) then
            ram_xaddr_drct <= ram_xaddr_drct + 1;
          end if;
        end if;

        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        -- Pull checkpoint from ram procedure
        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if (pull_chkpnt_from_ram_en = '1') then
          -- Defaults
          dbuf_from_ram     <= '0';
          row_col_from_ram  <= '0';
          ram_xaddr_incr_en <= '1';

          if (to_integer(ram_xaddr_drct) >= C_RAM_DBUF_STRT_ADDR and to_integer(ram_xaddr_drct) < C_RAM_DBUF_STRT_ADDR + C_RAM_DBUF_OFST) then
            dbuf_from_ram <= '1';
          elsif (to_integer(ram_xaddr_drct) >= C_RAM_DBUF_STRT_ADDR + C_RAM_DBUF_OFST and to_integer(ram_xaddr_drct) < C_RAM_ROW_COL_STRT_ADDR + C_RAM_ROW_COL_OFST) then
            row_col_from_ram <= '1';
          end if;

          if (to_integer(ram_xaddr_drct) = C_RAM_ROW_COL_STRT_ADDR + C_RAM_ROW_COL_OFST) then
            ram_xaddr_incr_en     <= '0';
            pull_chkpnt_ram_cmplt <= '1';                                                                           -- Pulse to let know I_DCT1D_fsm that pull prcedure completed succesfully
          end if;

          dbuf_from_ram_d1    <= dbuf_from_ram;
          row_col_from_ram_d1 <= row_col_from_ram;

          if (dbuf_from_ram_d1 = '1') then
            dbuf(0)                        <= resize(signed(RAM_DOUT), dbuf(0)'length);
            dbuf(dbuf'length - 1 downto 1) <= dbuf(dbuf'length - 2 downto 0);
          end if;
          if (row_col_from_ram_d1 = '1') then
            row_cnt <= resize(unsigned(RAM_DOUT), row_cnt'length);

            stage2_start <= '1';                                                                                    -- Most important signal: makes I_DCT1D restart from checkpoint

            pull_chkpnt_from_ram_en <= '0';
          end if;

        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        -- Push checkpoint to ram procedure
        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        elsif (push_chkpnt_to_ram_en = '1') then
          ram_we_drct       <= '1';
          ram_xaddr_incr_en <= '1';

          if (to_integer(ram_xaddr_drct) >= C_RAM_DBUF_STRT_ADDR and to_integer(ram_xaddr_drct) < C_RAM_DBUF_STRT_ADDR + C_RAM_DBUF_OFST) then
            dbuf(0)                        <= dbuf(dbuf'length - 1);
            dbuf(dbuf'length - 1 downto 1) <= dbuf(dbuf'length - 2 downto 0);
            ram_din_drct                   <= std_logic_vector(resize(dbuf(dbuf'length - 1), ram_din_drct'length)); -- data is arithmetically adjusted (with 1's in MSbits) since dbuf is signed
          elsif (to_integer(ram_xaddr_drct) >= C_RAM_DBUF_STRT_ADDR + C_RAM_DBUF_OFST and to_integer(ram_xaddr_drct) < C_RAM_ROW_COL_STRT_ADDR + C_RAM_ROW_COL_OFST) then
            ram_din_drct <= std_logic_vector(resize(row_cnt, ram_din_drct'length));
          end if;

          if (to_integer(ram_xaddr_drct)= C_DCT1D_CHKP_IN_RAM_STRT_ADDR + C_DCT1D_CHKP_IN_RAM_OFST) then
            ram_we_drct           <= '0';                                                                           -- disable write enable
            ram_xaddr_incr_en     <= '0';                                                                           -- disabe ram_Xaddr increase procedure
            push_chkpnt_to_ram_en <= '0';                                                                           -- disable push checkpoint to ram procedure
            push_chkpnt_ram_cmplt <= '1';                                                                           -- Signal successfull push checkpoint to m_fsm
          end if;
        else
          ram_xaddr_incr_en <= '0';
          ram_we_drct       <= '0';
          ram_din_drct      <= (others => '0');
        end if;
      else
        stage2_start  <= '0';
        ram_we_s      <= '0';
        frame_cmplt_s <= '0';

        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        -- 1st stage
        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if (IDV = '1' AND i_dct_halt_input = '0') then
          inpt_cnt <= inpt_cnt + 1; -- 0->N-1 (7)

          -- Input data is level shifted. This will range DC coeff to boundary 9 bits

          -- DCTI shift register: right shift input data
          dcti_shift_reg(N - 2 downto 0) <= dcti_shift_reg(N - 1 downto 1);
          dcti_shift_reg(N - 1)          <= SIGNED('0' & DCTI) - LEVEL_SHIFT;
          if (inpt_cnt = N - 1) then
            -- after this sum dbuf is in range of -256 to 254 (min to max)
            dbuf(0) <= dcti_shift_reg(1) + (SIGNED('0' & DCTI) - LEVEL_SHIFT);
            dbuf(1) <= dcti_shift_reg(2) + dcti_shift_reg(7);
            dbuf(2) <= dcti_shift_reg(3) + dcti_shift_reg(6);
            dbuf(3) <= dcti_shift_reg(4) + dcti_shift_reg(5);
            dbuf(4) <= dcti_shift_reg(1) - (SIGNED('0' & DCTI) - LEVEL_SHIFT);
            dbuf(5) <= dcti_shift_reg(2) - dcti_shift_reg(7);
            dbuf(6) <= dcti_shift_reg(3) - dcti_shift_reg(6);
            dbuf(7) <= dcti_shift_reg(4) - dcti_shift_reg(5);

            inpt_cnt     <= (others => '0');
            stage2_start <= '1';
          end if;
        end if;
        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        -- 2nd stage
        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if (stage2_cnt < N) then
          stage2_cnt <= stage2_cnt + 1;  --  0->N (8)

          -- write RAM
          ram_we_s <= '1';
          -- reverse col/row order for transposition purpose
          ram_waddr_s <= std_logic_vector(resize(unsigned(col_cnt2 & row_cnt), ram_waddr_s'length));
          -- increment column counter
          col_cnt  <= col_cnt + 1;     -- 0->N-1 (7)
          col_cnt2 <= col_cnt2 + 1;    -- 0->N-1 (7)

          -- finished processing one input row
          if (col_cnt = 0) then
            row_cnt <= row_cnt + 1; -- 0->N-1 (7)

            -- Signal a complete frame to DBUFCTL (resultin in switch to 2nd memory)
            if (row_cnt = N - 1) then
              frame_cmplt_s <= '1';
              col_cnt       <= (others => '0');
            end if;
          end if;
        end if;
        if (stage2_start = '1') then
          stage2_cnt <= (others => '0');

          -- row_cnt++ happens when col_cnt overloeads to 0 (see finished processing input row).
          -- So this needs to be triggered by logic and not by intialization, hence col_cnt starts from 1
          col_cnt <= (0=>'1', others => '0');

          col_cnt2 <= (others => '0');
        end if;
        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      end if;
    end if;

  end process P_DATA_BUF_AND_CTRL;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Delays for internal signals

  P_DELAYS : process (CLK, RST) is
  begin

    if (RST= '1') then
      is_even         <= '0';
      is_even_d       <= (others => '0');
      ram_we_d        <= (others => '0');
      ram_waddr_d     <= (others => (others => '0'));
      frame_cmplt_s_d <= (others => '0');
      dbuf_cmplt_d    <= (others => '1');       -- the buffer is complete when we start
    elsif (CLK'event and CLK = '1') then
      if (i_dct_halt = '1') then
      else
        -- stge2_cnt first bit represents even (=0) or odd (=1) row computation in the pipeline
        is_even <= not stage2_cnt(0);

        -- Is even delay with shift register
        is_even_d(is_even_d'length - 1 downto 1) <= is_even_d(is_even_d'length - 2 downto 0);
        is_even_d(0)                             <= is_even;

        ram_we_d(ram_we_d'length - 1 downto 1 ) <= ram_we_d(ram_we_d'length - 2 downto 0);
        ram_we_d(0)                             <= ram_we_s;

        ram_waddr_d(ram_waddr_d'length - 1 downto 1) <= ram_waddr_d(ram_waddr_d'length - 2 downto 0);
        ram_waddr_d(0)                               <= ram_waddr_s;

        frame_cmplt_s_d (frame_cmplt_s_d'length - 1 downto 1) <= frame_cmplt_s_d(frame_cmplt_s_d'length - 2 downto 0);
        frame_cmplt_s_d(0)                                    <= frame_cmplt_s;

        dbuf_cmplt_d(dbuf_cmplt_d'length - 1 downto 1) <= dbuf_cmplt_d(dbuf_cmplt_d'length - 2 downto 0);
        if (stage2_cnt >= N - 1) then           -- //TODO check if not only N
          dbuf_cmplt_d(0) <= '1';
        else
          dbuf_cmplt_d(0) <= '0';
        end if;
      end if;
    end if;

  end process P_DELAYS;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Data Pipeline

  P_DATA_OUT_PIPE : process (CLK, RST) is
  begin

    if (RST = '1') then
      dcto_1 <= (others => '0');
      dcto_2 <= (others => '0');
      dcto_3 <= (others => '0');
      dcto_4 <= (others => '0');
    elsif (CLK'event and CLK = '1') then
      if (i_dct_halt= '1') then
      else
        if (is_even = '1') then               -- is even
          dcto_1 <= STD_LOGIC_VECTOR(RESIZE
                                     (RESIZE(SIGNED(ROME_DOUT(0)), C_PL1_DATA_W) +
                                       (RESIZE(SIGNED(ROME_DOUT(1)), C_PL1_DATA_W - 1) & '0') +
                                       (RESIZE(SIGNED(ROME_DOUT(2)), C_PL1_DATA_W - 2) & "00"),
                                       C_PL1_DATA_W));
        else
          dcto_1 <= STD_LOGIC_VECTOR(RESIZE
                                     (RESIZE(SIGNED(ROMO_DOUT(0)), C_PL1_DATA_W) +
                                       (RESIZE(SIGNED(ROMO_DOUT(1)), C_PL1_DATA_W - 1) & '0') +
                                       (RESIZE(SIGNED(ROMO_DOUT(2)), C_PL1_DATA_W - 2) & "00"),
                                       C_PL1_DATA_W));
        end if;
        if (is_even_d(1 - 1) = '1') then      -- is even 1 clk delay
          dcto_2 <= STD_LOGIC_VECTOR(RESIZE
                                     (signed(dcto_1) +
                                       (RESIZE(SIGNED(rome_dout_d1(3)), C_PL1_DATA_W - 3) & "000") +
                                       (RESIZE(SIGNED(rome_dout_d1(4)), C_PL1_DATA_W - 4) & "0000"),
                                       C_PL1_DATA_W));
        else
          dcto_2 <= STD_LOGIC_VECTOR(RESIZE
                                     (signed(dcto_1) +
                                       (RESIZE(SIGNED(romo_dout_d1(3)), C_PL1_DATA_W - 3) & "000") +
                                       (RESIZE(SIGNED(romo_dout_d1(4)), C_PL1_DATA_W - 4) & "0000"),
                                       C_PL1_DATA_W));
        end if;
        if (is_even_d(2 - 1) = '1') then      -- is even 2 clock delay
          dcto_3 <= STD_LOGIC_VECTOR(RESIZE
                                     (signed(dcto_2) +
                                       (RESIZE(SIGNED(rome_dout_d2(5)), C_PL1_DATA_W - 5) & "00000") +
                                       (RESIZE(SIGNED(rome_dout_d2(6)), C_PL1_DATA_W - 6) & "000000"),
                                       C_PL1_DATA_W));
        else
          dcto_3 <= STD_LOGIC_VECTOR(RESIZE
                                     (signed(dcto_2) +
                                       (RESIZE(SIGNED(romo_dout_d2(5)), C_PL1_DATA_W - 5) & "00000") +
                                       (RESIZE(SIGNED(romo_dout_d2(6)), C_PL1_DATA_W - 6) & "000000"),
                                       C_PL1_DATA_W));
        end if;
        if (is_even_d(3 - 1) = '1') then      -- is even 3 clock delay
          dcto_4 <= STD_LOGIC_VECTOR(RESIZE
                                     (signed(dcto_3) +
                                       (RESIZE(SIGNED(rome_dout_d3(7)), C_PL1_DATA_W - 7) & "0000000") -
                                       (RESIZE(SIGNED(rome_dout_d3(8)), C_PL1_DATA_W - 8) & "00000000"),
                                       C_PL1_DATA_W));
        else
          dcto_4 <= STD_LOGIC_VECTOR(RESIZE
                                     (signed(dcto_3) +
                                       (RESIZE(SIGNED(romo_dout_d3(7)), C_PL1_DATA_W - 7) & "0000000") -
                                       (RESIZE(SIGNED(romo_dout_d3(8)), C_PL1_DATA_W - 8) & "00000000"),
                                       C_PL1_DATA_W));
        end if;
      end if;
    end if;

  end process P_DATA_OUT_PIPE;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Rom address generator: read precomputed MAC results from LUT

  P_ROMADDR : process (CLK, RST) is
  begin

    if (RST = '1') then
      ROME_ADDR <= (others => (others => '0'));
      ROMO_ADDR <= (others => (others => '0'));
    elsif (CLK'event and CLK = '1') then
      if (i_dct_halt = '1') then
      else
        for i in 0 to 8 loop
          -- even
          ROME_ADDR(i) <= std_logic_vector(col_cnt(ilog2(C_FRAME_SIZE) / 2 - 1 downto 1)) &
                          dbuf(0)(i) &
                          dbuf(1)(i) &
                          dbuf(2)(i) &
                          dbuf(3)(i);
          -- odd
          ROMO_ADDR(i) <= std_logic_vector(col_cnt(ilog2(C_FRAME_SIZE) / 2 - 1 downto 1)) &
                          dbuf(4)(i) &
                          dbuf(5)(i) &
                          dbuf(6)(i) &
                          dbuf(7)(i);
        end loop;
      end if;
    end if;

  end process P_ROMADDR;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Rom data output delay used by pipeline

  P_ROMDATAO_D1 : process (CLK, RST) is
  begin

    if (RST = '1') then
      rome_dout_d1 <= (others => (others => '0'));
      romo_dout_d1 <= (others => (others => '0'));
      rome_dout_d2 <= (others => (others => '0'));
      romo_dout_d2 <= (others => (others => '0'));
      rome_dout_d3 <= (others => (others => '0'));
      romo_dout_d3 <= (others => (others => '0'));
    elsif (CLK'event and CLK = '1') then
      if (i_dct_halt = '1') then
      else
        rome_dout_d1 <= ROME_DOUT;
        romo_dout_d1 <= ROMO_DOUT;
        rome_dout_d2 <= rome_dout_d1;
        romo_dout_d2 <= romo_dout_d1;
        rome_dout_d3 <= rome_dout_d2;
        romo_dout_d3 <= romo_dout_d2;
      end if;
    end if;

  end process P_ROMDATAO_D1;

end architecture RTL;

--------------------------------------------------------------------------------
