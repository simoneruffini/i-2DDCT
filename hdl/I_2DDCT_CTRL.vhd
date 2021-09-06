--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
--
-- Create Date:     Wed Jun  26 14:39:11 CEST 2021
-- Design Name:     I_2DDCT_CTRL
-- Module Name:     I_2DDCT_CTRL.vhd - RTL
-- Project Name:    i-2DDCT
-- Description:     I-2DDCT controller
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
  use WORK.I_2DDCT_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity I_2DDCT_CTRL is
  port (
    CLK                       : in    std_logic;                                                   -- Input clock
    RST                       : in    std_logic;                                                   -- Positive reset
    ----------------------------------------------------------------------------
    NVM_BUSY                  : in    std_logic;                                                   -- Busy signal for Async processes
    NVM_BUSY_SIG              : in    std_logic;                                                   -- Busy signal for sync processes (triggered 1 clk before BUSY)
    NVM_EN                    : out   std_logic;                                                   -- Enable memory
    NVM_WE                    : out   std_logic;                                                   -- Write enable
    NVM_RADDR                 : out   std_logic_vector(C_NVM_ADDR_W - 1 downto 0);                 -- Read address port
    NVM_WADDR                 : out   std_logic_vector(C_NVM_ADDR_W - 1 downto 0);                 -- Write address port
    NVM_DIN                   : out   std_logic_vector(C_NVM_DATA_W - 1 downto 0);                 -- Data input
    NVM_DOUT                  : in    std_logic_vector(C_NVM_DATA_W - 1 downto 0);                 -- Data output from read address
    ----------------------------------------------------------------------------
    SYS_ENRG_STATUS           : in    sys_enrg_status_t;                                           -- System Energy status
    FIRST_RUN                 : in    std_logic;                                                   -- First system run

    VARC_RDY                  : in    std_logic;
    SYS_STATUS                : out   sys_status_t;                                                -- System status value of sys_status_t
    DATA_SYNC                 : out   std_logic;                                                   -- Multiple semantics: tells if TX data is valid or if RX data was accepted when 1 otherwise TX/RX lines not captured/able

    DBUFCTL_START             : out   std_logic;                                                   -- Start DBUFCTL process block
    DBUFCTL_RX                : out   std_logic_vector(C_NVM_DATA_W - 1 downto 0);                 -- DBUFCTL process block RX signal
    DBUFCTL_TX                : in    std_logic_vector(C_NVM_DATA_W - 1 downto 0);                 -- DBUFCTL process block TX signal
    DBUFCTL_READY             : in    std_logic;                                                   -- DBUFCTL process block ready signal

    RAM_PB_START              : out   std_logic;                                                   -- Start RAM process block
    RAM_PB_RX                 : out   std_logic_vector(C_NVM_DATA_W - 1 downto 0);                 -- RAM process block RX signal
    RAM_PB_TX                 : in    std_logic_vector(C_NVM_DATA_W - 1 downto 0);                 -- RAM proces block TX signal
    RAM_PB_READY              : in    std_logic                                                    -- RAM_PB process block ready signal
  );
end entity I_2DDCT_CTRL;

architecture RTL of I_2DDCT_CTRL is

  --########################### CONSTANTS 1 ####################################

  constant C_NVM_DBUFCTL_PB_STRT_ADDR                           : natural := 0;
  constant C_NVM_DBUFCTL_PB_OFFSET                              : natural := C_CHKPNT_NVM_DBUFCTL_AMOUNT - 1;

  constant C_NVM_RAM_PB_STRT_ADDR                               : natural := C_NVM_DBUFCTL_PB_STRT_ADDR + C_NVM_DBUFCTL_PB_OFFSET + 1;
  constant C_NVM_RAM_PB_OFFSET                                  : natural := C_CHKPNT_NVM_RAM_AMOUNT - 1;

  --########################### TYPES ##########################################

  -- Main fsm state type

  type m_fsm_t is (
    S_INIT,
    S_NV2V_PUSH,
    S_VARC_INIT_CHKPNT,
    S_SYS_HALT,
    S_SYS_RUN,
    S_VARC_PREP_CHKPNT,
    S_V2NV_PUSH
  );

  -- Checkpoint Transfer Manager fsm state type

  type ctm_fsm_t is (
    S_WAIT_STRT,
    S_WAIT_VARC_RDY,
    S_PROC_ON
  );

  type proc_blk_order_t is (
    dbufctl,
    ram,
    num_proc_blk_order_t
  );

  type nvm_transfer_t is (
    dbufctl_transfer,
    ram_transfer,
    no_transfer
  );

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  constant C_STAGES_IN_CHKP_PROC                                : natural := proc_blk_order_t'pos(num_proc_blk_order_t);                        --  DBUFCTL,RAM1,RAM2,

  --########################### SIGNALS ########################################

  signal pbsm_start_arr                                         : std_logic_vector(C_STAGES_IN_CHKP_PROC downto 0);                             -- 1 extra entry because of last PBSM start_out
  signal pbsm_pb_ready_arr                                      : std_logic_vector(C_STAGES_IN_CHKP_PROC - 1 downto 0);
  signal pbsm_pb_start_arr                                      : std_logic_vector(C_STAGES_IN_CHKP_PROC - 1 downto 0);
  signal pbsm_start                                             : std_logic;                                                                    -- starts alal process block state machines
  signal pbsm_end                                               : std_logic;                                                                    -- signals end of all process block state machines

  signal nvm_active_transfer                                    : nvm_transfer_t;                                                               -- NVM active transfer signal
  signal transfer_on                                            : std_logic;
  signal transfer_cnt                                           : natural range 0 to max(C_CHKPNT_NVM_RAM_AMOUNT, C_CHKPNT_NVM_DBUFCTL_AMOUNT); -- NVM active transfer signal
  --signal pb_dbufctl_en                                  : std_logic;
  --signal pb_ram_en                                      : std_logic;

  signal m_fsm_pstate                                           : m_fsm_t;                                                                      -- main fsm present state
  signal m_fsm_fstate                                           : m_fsm_t;                                                                      -- main fsm future state

  signal sys_status_s                                           : sys_status_t;                                                                 -- System status signal
  signal sys_status_s_latch                                     : sys_status_t;                                                                 -- System status signal
  signal data_sync_gate                                         : std_logic;                                                                    -- And gate to sync signal
  signal data_sync_s                                            : std_logic;
  signal nvm_en_pb                                              : std_logic;
  signal nvm_addr_pb                                            : unsigned(C_NVM_ADDR_W - 1 downto 0);

  signal ctm_fsm_pstate                                         : ctm_fsm_t;                                                                    -- Checkpoint Transfer Manger fsm present state
  signal ctm_fsm_fstate                                         : ctm_fsm_t;                                                                    -- Checkpoint Transfer Manger fsm future state
  signal ctm_start                                              : std_logic;                                                                    -- Checkpoint Transfer Manger start signal
  signal ctm_end                                                : std_logic;                                                                    -- Checkpoint Transfer Manger end signal

  signal fsm_chkpnt_strt                                        : std_logic;                                                                    -- Signals m_fsm that a checkpoint is necessary
  signal fsm_chkpnt_strt_latch                                  : std_logic;                                                                    -- Latch of the previous signal
  signal halt                                                   : std_logic;                                                                    -- Signals m_fsm that vol_arch must be halted

  --########################### ARCHITECTURE BEGIN #############################

begin

  --########################### ENTITY DEFINITION ##############################

  G_PBSM : for i in 0 to C_STAGES_IN_CHKP_PROC - 1 generate

    GI_U_PBSM : entity  work.pbsm
      port map (
        CLK          => CLK,
        RST          => RST,
        NVM_BUSY_SIG => NVM_BUSY_SIG,
        -- from/to PBSM(m-1)
        START_I => pbsm_start_arr(i),
        -- from/to PBSM(m+1)
        START_O => pbsm_start_arr(i + 1),
        -- from/to processi
        PB_RDY_I   => pbsm_pb_ready_arr(i),
        PB_START_O => pbsm_pb_start_arr(i)
      );

  end generate G_PBSM;

  --########################## OUTPUT PORTS WIRING #############################

  SYS_STATUS <= sys_status_s;
  DATA_SYNC  <= data_sync_s;
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Each PBSM regulates a process block with the below sibnals.
  -- These process blocks regulate access to and from NVM for checkpopinting operations
  -- Hence the PBSM to process block mapping defines the order of execution of PBs

  DBUFCTL_START                                    <= pbsm_pb_start_arr(proc_blk_order_t'pos(dbufctl));
  pbsm_pb_ready_arr(proc_blk_order_t'pos(dbufctl)) <= DBUFCTL_READY;

  RAM_PB_START                                 <= pbsm_pb_start_arr(proc_blk_order_t'pos(ram));
  pbsm_pb_ready_arr(proc_blk_order_t'pos(ram)) <= RAM_PB_READY;

  NVM_RADDR <= std_logic_vector(nvm_addr_pb) when m_fsm_pstate = S_NV2V_PUSH else
               not std_logic_vector(nvm_addr_pb);
  NVM_WADDR <= std_logic_vector(nvm_addr_pb) when m_fsm_pstate = S_V2NV_PUSH else
               not std_logic_vector(nvm_addr_pb);

  NVM_DIN <= DBUFCTL_TX  when nvm_active_transfer = dbufctl_transfer else
             RAM_PB_TX   when nvm_active_transfer = ram_transfer else
             (others => '0') when nvm_active_transfer = no_transfer;

  NVM_EN <= nvm_en_pb when m_fsm_pstate = S_NV2V_PUSH OR m_fsm_fstate = S_V2NV_PUSH else
            '0';

  NVM_WE <= '1' when sys_status_s = SYS_PUSH_CHKPNT_V2NV AND transfer_on = '1' else
            '0';

  DBUFCTL_RX <= NVM_DOUT;
  RAM_PB_RX  <= NVM_DOUT;

  --########################## COBINATORIAL FUNCTIONS ##########################

  pbsm_start_arr(0) <= pbsm_start;                              -- start of PBSM chain is piloted by pbsm_start
  pbsm_end          <= pbsm_start_arr(C_STAGES_IN_CHKP_PROC);   -- when last PBSM signals a statrt means that all PBSM completed
  ctm_end           <= pbsm_end;
  data_sync_s       <= data_sync_gate AND not NVM_BUSY;

  --########################## PROCESSES #######################################

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- fsms sequential process (synthesized FFs)

  P_M_FSM_SEQ : process (CLK, RST) is
  begin

    if (RST = '1') then
      m_fsm_pstate   <= S_INIT;
      ctm_fsm_pstate <= S_WAIT_STRT;
    elsif (CLK'event and CLK = '1') then
      m_fsm_pstate   <= m_fsm_fstate;
      ctm_fsm_pstate <= ctm_fsm_fstate;
    end if;

  end process P_M_FSM_SEQ;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Future state computation for main fsm (combinatorial process)

  P_M_FSM_FUT_S : process (m_fsm_pstate, FIRST_RUN, ctm_end, fsm_chkpnt_strt, halt, VARC_RDY) is
  begin

    -- Default
    m_fsm_fstate <= m_fsm_pstate;

    case m_fsm_pstate is

      when S_INIT =>

        if (FIRST_RUN = '1') then
          m_fsm_fstate <= S_SYS_HALT;
        else
          m_fsm_fstate <= S_NV2V_PUSH;
        end if;

      when S_NV2V_PUSH =>

        if (ctm_end = '1') then
          m_fsm_fstate <= S_VARC_INIT_CHKPNT;
        end if;

      when S_VARC_INIT_CHKPNT =>

        if (VARC_RDY = '1') then
          m_fsm_fstate <= S_SYS_HALT;
        end if;

      when S_SYS_HALT =>

        if (fsm_chkpnt_strt= '1') then
          m_fsm_fstate <= S_VARC_PREP_CHKPNT;
        elsif (halt = '1') then
          m_fsm_fstate <= S_SYS_HALT;
        else
          m_fsm_fstate <= S_SYS_RUN;
        end if;

      when S_SYS_RUN =>

        if (halt = '1') then
          m_fsm_fstate <= S_SYS_HALT;
        end if;

      when S_VARC_PREP_CHKPNT =>

        if (VARC_RDY ='1') then
          m_fsm_fstate <= S_V2NV_PUSH;
        end if;

      when S_V2NV_PUSH =>

        if (ctm_end = '1') then
          m_fsm_fstate <= S_SYS_HALT;
        end if;

    end case;

  end process P_M_FSM_FUT_S;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Output process for main fsm, generates a moore fsm (output depends on input)

  P_M_FSM_OUTPUTS : process (m_fsm_pstate) is
  begin

    -- defaults
    -- By defining them the synthesizer produces a combinatrial logic without FFs
    ctm_start    <= '0';
    sys_status_s <= SYS_HALT;

    case m_fsm_pstate is

      when S_INIT =>
      when S_NV2V_PUSH =>
        ctm_start    <= '1';
        sys_status_s <= SYS_PUSH_CHKPNT_NV2V;
      when S_VARC_INIT_CHKPNT =>
        sys_status_s <= SYS_VARC_INIT_CHKPNT;
      when S_SYS_HALT =>
        sys_status_s <= SYS_HALT;
      when S_SYS_RUN =>
        sys_status_s <= SYS_RUN;
      when S_VARC_PREP_CHKPNT =>
        sys_status_s <= SYS_VARC_PREP_CHKPNT;
      when S_V2NV_PUSH =>
        ctm_start    <= '1';
        sys_status_s <= SYS_PUSH_CHKPNT_V2NV;

    end case;

  end process P_M_FSM_OUTPUTS;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Future state computation for Nonvolatile Address Management Process fsm (combinatorial process)

  P_CTM_FSM_FUT_S : process (ctm_fsm_pstate, ctm_start, VARC_RDY,  pbsm_end) is
  begin

    -- Default
    ctm_fsm_fstate <= ctm_fsm_pstate;

    case ctm_fsm_pstate is

      when S_WAIT_STRT =>

        if (ctm_start = '1') then
          ctm_fsm_fstate <= S_WAIT_VARC_RDY;
        end if;

      when S_WAIT_VARC_RDY =>

        if (VARC_RDY = '1') then
          ctm_fsm_fstate <= S_PROC_ON;
        end if;

      when S_PROC_ON =>

        if (pbsm_end = '1') then
          ctm_fsm_fstate <= S_WAIT_STRT;
        end if;

    end case;

  end process P_CTM_FSM_FUT_S;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Output process for Nonvolatile Address Management Process fsm,
  -- generates a mealy fsm (output depends on input)

  P_CTM_FSM_OUTPUTS : process (ctm_fsm_pstate, VARC_RDY) is
  begin

    -- defaults
    -- By defining them the synthesizer produces a combinatrial logic without FFs
    pbsm_start <= '0';

    case ctm_fsm_pstate is

      when S_WAIT_STRT =>
      when S_WAIT_VARC_RDY =>

        if (VARC_RDY = '1') then
          pbsm_start <= '1';
        end if;

      when S_PROC_ON =>

    end case;

  end process P_CTM_FSM_OUTPUTS;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Process blocks process, managaes NVM access

  P_PROC_BLOCK : process (CLK, RST) is
  begin

    if (RST ='1') then
      nvm_addr_pb <= (others => '0');
      --NVM_WE              <= '0';
      nvm_en_pb           <= '0';
      data_sync_gate      <= '0';
      nvm_active_transfer <= no_transfer;
      transfer_on         <= '0';
      transfer_cnt        <= 1;
    elsif (CLK'event and CLK = '1') then
      data_sync_gate <= '0';

      if (transfer_on = '1') then
        data_sync_gate <= '1';

        -- NOTE: this increases nvm_addr correctly under NV2V. In V2NV, instaed,
        -- it increases one too many times (in theory) but it is correctly by
        -- the range check in Limit nvm_addr below
        if (NVM_BUSY = '0' AND nvm_en_pb = '1') then
          nvm_addr_pb <= nvm_addr_pb + 1;
        end if;

        if (data_sync_s = '1') then
          transfer_cnt <= transfer_cnt + 1;
        end if;

        case nvm_active_transfer is

          when dbufctl_transfer =>
            if (data_sync_s = '1' AND transfer_cnt = C_CHKPNT_NVM_DBUFCTL_AMOUNT) then
              transfer_on         <= '0';
              data_sync_gate      <= '0';
              nvm_active_transfer <= no_transfer;
            end if;
          when ram_transfer =>
            if (data_sync_s = '1' AND transfer_cnt = C_CHKPNT_NVM_RAM_AMOUNT) then
              transfer_on         <= '0';
              data_sync_gate      <= '0';
              nvm_active_transfer <= no_transfer;
            end if;
          when no_transfer =>
            transfer_cnt   <= 1;
            data_sync_gate <= '0';

        end case;

      end if;

      -- Enable transfer
      if (pbsm_pb_start_arr(proc_blk_order_t'pos(dbufctl))='1' OR
          pbsm_pb_start_arr(proc_blk_order_t'pos(ram))='1') then
        transfer_on    <= '1';
        nvm_en_pb      <= '1';
        data_sync_gate <= '0';
        if (sys_status_s= SYS_PUSH_CHKPNT_V2NV) then
          data_sync_gate <= '1';
        end if;
      end if;

      -- Limit nvm_address and nvm_en
      if (nvm_active_transfer = dbufctl_transfer) then
        if (NVM_BUSY = '0' AND nvm_addr_pb = C_NVM_DBUFCTL_PB_STRT_ADDR + C_NVM_DBUFCTL_PB_OFFSET) then
          if (transfer_cnt > 1) then
            nvm_en_pb <= '0';
          end if;
          nvm_addr_pb <= nvm_addr_pb;
        end if;
      end if;
      if (nvm_active_transfer = ram_transfer) then
        if (NVM_BUSY = '0' AND nvm_addr_pb = C_NVM_RAM_PB_STRT_ADDR + C_NVM_RAM_PB_OFFSET) then
          if (transfer_cnt > 1) then
            nvm_en_pb <= '0';
          end if;
          nvm_addr_pb <= nvm_addr_pb;
        end if;
      end if;

      -- Enable NVM_DIN mutex, set transfer type, NVM_ADDR and init signals
      if (pbsm_start_arr(proc_blk_order_t'pos(dbufctl))='1') then
        nvm_active_transfer <= dbufctl_transfer;
        nvm_addr_pb         <= to_unsigned(C_NVM_DBUFCTL_PB_STRT_ADDR, nvm_addr_pb'length);
        nvm_en_pb           <= '0';
        transfer_on         <= '0';
        transfer_cnt        <= 1;
      end if;
      if (pbsm_start_arr(proc_blk_order_t'pos(ram))='1') then
        nvm_active_transfer <= ram_transfer;
        nvm_addr_pb         <= to_unsigned(C_NVM_RAM_PB_STRT_ADDR, nvm_addr_pb'length);
        nvm_en_pb           <= '0';
        transfer_on         <= '0';
        transfer_cnt        <= 1;
      end if;

      if (pbsm_start_arr(C_STAGES_IN_CHKP_PROC) = '1') then
        nvm_active_transfer <= no_transfer;
        nvm_addr_pb         <= (others => '0');
        nvm_en_pb           <= '0';
        transfer_on         <= '0';
        data_sync_gate      <= '0';
        transfer_cnt        <= 1;
      end if;
    end if;

  end process P_PROC_BLOCK;

  -- --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Interrupt signal generator process

  -- TODO fix this it doesn't work
  P_INTRP_SIG_GEN : process (CLK, RST) is
  begin

    if (RST = '1') then
      halt            <= '0';
      fsm_chkpnt_strt <= '0';
    elsif (CLK'event and CLK = '1') then
      -- Defaults
      fsm_chkpnt_strt <= '0';

      case SYS_ENRG_STATUS is

        when sys_enrg_hazard =>
          halt <= '1';
          -- Push a checkpoint to NVM only once
          if (fsm_chkpnt_strt_latch = '0') then
            fsm_chkpnt_strt <= '1';
          end if;
        when sys_enrg_ok =>
          halt            <= '0';
          fsm_chkpnt_strt <= '0';

      end case;

      -- Latch (reset only when sys is able to run: energy ok)
      if (fsm_chkpnt_strt = '1') then
        fsm_chkpnt_strt_latch <= '1';
      end if;
      if (SYS_ENRG_STATUS = sys_enrg_ok AND sys_status_s = SYS_HALT) then
        fsm_chkpnt_strt_latch <= '0';
      end if;
    end if;

  end process P_INTRP_SIG_GEN;

end architecture RTL;
