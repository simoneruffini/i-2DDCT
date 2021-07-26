--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
--
-- Create Date:     Wed Jun  26 14:39:11 CEST 2021
-- Design Name:     NVM_CTRL
-- Module Name:     NVM_CTRL.vhd - RTL
-- Project Name:    iMDCT
-- Description:     Non volatile memory controller
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

entity NVM_CTRL is
  port (
    CLK               : in    std_logic;                                              -- Input clock
    RST               : in    std_logic;                                              -- Positive reset
    ----------------------------------------------------------------------------
    NVM_BUSY          : in    std_logic;                                              -- Busy signal for Async processes
    NVM_BUSY_SIG      : in    std_logic;                                              -- Busy signal for sync processes (triggered 1 clk before BUSY)
    NVM_EN            : out   std_logic;                                              -- Enable memory
    NVM_WE            : out   std_logic;                                              -- Write enable
    NVM_RADDR         : out   std_logic_vector(NVM_ADDR_W - 1 downto 0);              -- Read address port
    NVM_WADDR         : out   std_logic_vector(NVM_ADDR_W - 1 downto 0);              -- Write address port
    NVM_DIN           : out   std_logic_vector(NVM_DATA_W - 1 downto 0);              -- Data input
    NVM_DOUT          : in    std_logic_vector(NVM_DATA_W - 1 downto 0);              -- Data output from read address
    ----------------------------------------------------------------------------
    SYS_ENRG_STATUS   : in    sys_enrg_status_t;                                      -- System Energy status

    VARC_RDY          : in    std_logic;
    SYS_STATUS        : out   sys_status_t;                                           -- System status value of sys_status_t

    DBUFCTL_START     : out   std_logic;
    DBUFCTL_TX        : out   std_logic_vector(NVM_DATA_W - 1 downto 0);
    DBUFCTL_RX        : in    std_logic_vector(NVM_DATA_W - 1 downto 0);

    RAM1_START        : out   std_logic;
    RAM1_TX           : out   std_logic_vector(NVM_DATA_W - 1 downto 0);
    RAM1_RX           : in    std_logic_vector(NVM_DATA_W - 1 downto 0);

    RAM2_START        : out   std_logic;
    RAM2_TX           : out   std_logic_vector(NVM_DATA_W - 1 downto 0);
    RAM2_RX           : in    std_logic_vector(NVM_DATA_W - 1 downto 0)
  );
end entity NVM_CTRL;

architecture RTL of NVM_CTRL is

  --########################### CONSTANTS 1 ####################################

  constant C_NVM_FIRST_RUN_STRT_ADDR                 : natural := 0;
  constant C_NVM_FIRST_RUN_OFFSET                    : natural := 0;

  constant C_NVM_DBUFCTL_STRT_ADDR                   : natural := C_NVM_FIRST_RUN_STRT_ADDR + C_NVM_FIRST_RUN_OFFSET + 1;
  constant C_NVM_DBUFCTL_OFFSET                      : natural := 1;

  constant C_NVM_RAM1_STRT_ADDR                      : natural := C_NVM_DBUFCTL_STRT_ADDR + C_NVM_DBUFCTL_OFFSET + 1;
  constant C_NVM_RAM1_OFFSET                         : natural := (2 ** C_RAMADDR_W) - 1;

  constant C_NVM_RAM2_STRT_ADDR                      : natural := C_NVM_RAM1_STRT_ADDR + C_NVM_RAM1_OFFSET + 1;
  constant C_NVM_RAM2_OFFSET                         : natural := C_NVM_RAM1_OFFSET;

  --########################### TYPES ##########################################

  -- Main fsm state type

  type m_fsm_t is (
    S_INIT,
    S_CHK_FIRST_RUN,
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
    ram1,
    ram2,
    num_proc_blk_order_t
  );

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  constant C_STAGES_IN_CHKP_PROC                     : natural := proc_blk_order_t'pos(num_proc_blk_order_t);   --  DBUFCTL,RAM1,RAM2,

  --########################### SIGNALS ########################################

  signal pbsm_start_arr                              : std_logic_vector(C_STAGES_IN_CHKP_PROC downto 0);        -- 1 extra entry because of last PBSM start_out
  signal pbsm_pb_ready_arr                           : std_logic_vector(C_STAGES_IN_CHKP_PROC - 1 downto 0);
  signal pbsm_pb_start_arr                           : std_logic_vector(C_STAGES_IN_CHKP_PROC - 1 downto 0);
  signal pbsm_start                                  : std_logic;                                               -- starts alal process block state machines
  signal pbsm_end                                    : std_logic;                                               -- signals end of all process block state machines

  signal pb_dbufctl_en                               : std_logic;
  signal pb_ram1_en                                  : std_logic;
  signal pb_ram2_en                                  : std_logic;

  signal m_fsm_pstate                                : m_fsm_t;                                                 -- main fsm present state
  signal m_fsm_fstate                                : m_fsm_t;                                                 -- main fsm future state

  signal chk_first_run_cmlpt                         : std_logic;                                               -- Check first run from NVM complete
  signal first_run                                   : std_logic;                                               -- First run of the sytem
  signal nvm_en_fr                                   : std_logic;
  signal nvm_addr_fr                                 : unsigned(NVM_ADDR_W - 1 downto 0);

  signal sys_status_s                                : sys_status_t;                                            -- System status signal
  signal sys_status_s_latch                          : sys_status_t;                                            -- System status signal
  signal nvm_en_pb                                   : std_logic;
  signal nvm_addr_pb                                 : unsigned(NVM_ADDR_W - 1 downto 0);

  signal ctm_fsm_pstate                              : ctm_fsm_t;                                               -- Checkpoint Transfer Manger fsm present state
  signal ctm_fsm_fstate                              : ctm_fsm_t;                                               -- Checkpoint Transfer Manger fsm future state
  signal ctm_start                                   : std_logic;                                               -- Checkpoint Transfer Manger start signal
  signal ctm_end                                     : std_logic;                                               -- Checkpoint Transfer Manger end signal

  signal fsm_chkpnt_strt                             : std_logic;                                               -- Signals m_fsm that a checkpoint is necessary
  signal fsm_chkpnt_strt_latch                       : std_logic;                                               -- Latch of the previous signal
  signal halt                                        : std_logic;                                               -- Signals m_fsm that vol_arch must be halted

  --########################### ARCHITECTURE BEGIN #############################

begin

  --########################### ENTITY DEFINITION ##############################

  G_PBSM : for i in 0 to C_STAGES_IN_CHKP_PROC - 1 generate

    U_PBSM : entity  work.pbsm
      port map (
        CLK => CLK,
        RST => RST,
        -- from/to PBSM(m-1
        START_I => pbsm_start_arr(i),
        -- from/to PBSM(m+1
        START_O => pbsm_start_arr(i + 1),
        -- from/to processi
        PB_RDY_I   => pbsm_pb_ready_arr(i),
        PB_START_O => pbsm_pb_start_arr(i)
      );

  end generate G_PBSM;

  --########################## OUTPUT PORTS WIRING #############################

  SYS_STATUS <= sys_status_s;
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Each PBSM regulates a process block with the below sibnals.
  -- These process blocks regulate access to and from NVM for checkpopinting operations
  -- Hence the PBSM to process block mapping defines the order of execution of PBs

  DBUFCTL_START <= pbsm_pb_start_arr(proc_blk_order_t'pos(dbufctl));

  RAM1_START <= pbsm_pb_start_arr(proc_blk_order_t'pos(ram1));

  RAM2_START <= pbsm_pb_start_arr(proc_blk_order_t'pos(ram2));

  NVM_RADDR <= std_logic_vector(nvm_addr_fr) when m_fsm_pstate = S_CHK_FIRST_RUN else
               std_logic_vector(nvm_addr_pb) when m_fsm_pstate = S_NV2V_PUSH else
               (others => '0');
  NVM_WADDR <= std_logic_vector(nvm_addr_pb) when sys_status_s =SYS_PUSH_CHKPNT_V2NV else
               not std_logic_vector(nvm_addr_pb);

  NVM_DIN <= DBUFCTL_RX  when pb_dbufctl_en = '1'  else
             RAM1_RX     when pb_ram1_en= '1'      else
             RAM2_RX     when pb_ram2_en= '1'      else
             (others => '0');

  NVM_EN <= nvm_en_fr when m_fsm_pstate = S_CHK_FIRST_RUN else
            nvm_en_pb when m_fsm_pstate = S_NV2V_PUSH OR m_fsm_fstate = S_V2NV_PUSH else
            '0';

  DBUFCTL_TX <= NVM_DOUT when pb_dbufctl_en = '1' else
                (others => '0');
  RAM1_TX    <= NVM_DOUT when pb_ram1_en = '1' else
                (others => '0');
  RAM2_TX    <= NVM_DOUT when pb_ram2_en = '1' else
                (others => '0');

  --########################## COBINATORIAL FUNCTIONS ##########################

  pbsm_start_arr(0) <= pbsm_start;                              -- start of PBSM chain is piloted by pbsm_start
  pbsm_end          <= pbsm_start_arr(C_STAGES_IN_CHKP_PROC);   -- when last PBSM signals a statrt means that all PBSM completed
  ctm_end           <= pbsm_end;
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

  P_M_FSM_FUT_S : process (m_fsm_pstate, chk_first_run_cmlpt, first_run, ctm_end, fsm_chkpnt_strt, halt, VARC_RDY) is
  begin

    -- Default
    m_fsm_fstate <= m_fsm_pstate;

    case m_fsm_pstate is

      when S_INIT =>
        m_fsm_fstate <= S_CHK_FIRST_RUN;
      when S_CHK_FIRST_RUN =>

        if (chk_first_run_cmlpt = '1') then
          if (first_run = '1') then
            m_fsm_fstate <= S_SYS_RUN;
          else
            m_fsm_fstate <= S_NV2V_PUSH;
          end if;
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

        if (halt = '1') then
          m_fsm_fstate <= S_SYS_HALT;
        elsif (fsm_chkpnt_strt ='0') then
          m_fsm_fstate <= S_SYS_RUN;
        elsif (fsm_chkpnt_strt= '1') then
          m_fsm_fstate <= S_V2NV_PUSH;
        end if;

      when S_SYS_RUN =>

        if (halt = '1') then
          m_fsm_fstate <= S_SYS_HALT;
        elsif (fsm_chkpnt_strt= '1') then
          m_fsm_fstate <= S_VARC_PREP_CHKPNT;
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
      when S_CHK_FIRST_RUN =>
        nvm_en_fr   <= '1';
        nvm_addr_fr <= to_unsigned(C_NVM_FIRST_RUN_STRT_ADDR,nvm_addr_fr'length);
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
  -- Check system's first run process

  P_FIRST_RUN : process (CLK, RST) is
    variable chk_wait : std_logic;
  begin

    if (RST = '1') then
      chk_first_run_cmlpt <= '0';
      first_run           <= '0';
      chk_wait := '0';
    elsif (CLK'event and CLK = '1') then
      if (chk_wait = '1' AND NVM_BUSY = '0') then
        chk_first_run_cmlpt <= '1';
        first_run           <= NVM_DOUT(0);
      end if;
      if (m_fsm_pstate = S_CHK_FIRST_RUN) then
        chk_wait := '1';
      end if;
    end if;

  end process P_FIRST_RUN;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Process blocks process, managaes NVM access

  P_PROC_BLOCK : process (CLK, RST) is
  begin

    if (RST ='1') then
      nvm_addr_pb       <= (others => '0');
      NVM_WE            <= '0';
      nvm_en_pb         <= '0';
      pbsm_pb_ready_arr <= (others => '0');
      pb_dbufctl_en     <= '0';
      pb_ram1_en        <= '0';
      pb_ram2_en        <= '0';
    elsif (CLK'event and CLK = '1') then
      if (pb_dbufctl_en = '1') then
        if (nvm_addr_pb = C_NVM_DBUFCTL_STRT_ADDR + C_NVM_DBUFCTL_OFFSET) then
          nvm_en_pb                                        <= '0';
          pbsm_pb_ready_arr(proc_blk_order_t'pos(dbufctl)) <= '1';
          pb_dbufctl_en                                    <= '0';
        end if;
        if (NVM_BUSY = '0') then
          nvm_addr_pb <= nvm_addr_pb + 1;
        end if;
      elsif (pb_ram1_en ='1') then
        if (nvm_addr_pb = C_NVM_RAM1_STRT_ADDR + C_NVM_RAM1_OFFSET) then
          nvm_en_pb                                     <= '0';
          pbsm_pb_ready_arr(proc_blk_order_t'pos(ram1)) <= '1';
          pb_ram1_en                                    <= '0';
        end if;
        if (NVM_BUSY = '0') then
          nvm_addr_pb <= nvm_addr_pb + 1;
        end if;
      elsif (pb_ram2_en = '1') then
        if (nvm_addr_pb = C_NVM_RAM2_STRT_ADDR + C_NVM_RAM2_OFFSET) then
          nvm_en_pb                                     <= '0';
          pbsm_pb_ready_arr(proc_blk_order_t'pos(ram2)) <= '1';
          pb_ram2_en                                    <= '0';
        end if;
        if (NVM_BUSY = '0') then
          nvm_addr_pb <= nvm_addr_pb + 1;
        end if;
      end if;

      if (pbsm_pb_start_arr(proc_blk_order_t'pos(dbufctl))='1') then
        nvm_addr_pb                                      <= to_unsigned(C_NVM_DBUFCTL_STRT_ADDR, nvm_addr_pb'length);
        nvm_en_pb                                        <= '1';
        pbsm_pb_ready_arr(proc_blk_order_t'pos(dbufctl)) <= '0';
        pb_dbufctl_en                                    <= '1';
      elsif (pbsm_pb_start_arr(proc_blk_order_t'pos(ram1))='1') then
        nvm_addr_pb                                   <= to_unsigned(C_NVM_RAM1_STRT_ADDR, nvm_addr_pb'length);
        nvm_en_pb                                     <= '1';
        pbsm_pb_ready_arr(proc_blk_order_t'pos(ram1)) <= '0';
        pb_ram1_en                                    <= '1';
      elsif (pbsm_pb_start_arr(proc_blk_order_t'pos(ram2))='1') then
        nvm_addr_pb                                   <= to_unsigned(C_NVM_RAM2_STRT_ADDR, nvm_addr_pb'length);
        nvm_en_pb                                     <= '1';
        pbsm_pb_ready_arr(proc_blk_order_t'pos(ram2)) <= '0';
        pb_ram2_en                                    <= '1';
      end if;
      if (pbsm_start_arr(C_STAGES_IN_CHKP_PROC) = '1') then
        nvm_addr_pb       <= (others => '0');
        nvm_en_pb         <= '0';
        pbsm_pb_ready_arr <= (others => '0');
      end if;

      if (sys_status_s=SYS_PUSH_CHKPNT_NV2V or pbsm_end ='1') then
        NVM_WE <= '0';
      elsif (sys_status_s = SYS_PUSH_CHKPNT_V2NV and pbsm_start = '1') then
        NVM_WE <= '1';
      end if;
    end if;

  end process P_PROC_BLOCK;

  P_FSM_INTRP_SIG_GEN : process (CLK, RST) is
  begin

    if (RST = '1') then
      halt            <= '0';
      fsm_chkpnt_strt <= '0';
    elsif (CLK'event and CLK = '1') then

      case SYS_ENRG_STATUS is

        when sys_enrg_hazard =>
          halt <= '1';
        when sys_enrg_wrng =>
          fsm_chkpnt_strt <= '1';
          -- Push a checkpoint to NVM only once
          if (fsm_chkpnt_strt = '1' and fsm_chkpnt_strt = fsm_chkpnt_strt_latch) then
            fsm_chkpnt_strt <= '0';
          end if;
        when sys_enrg_ok =>
          halt            <= '0';
          fsm_chkpnt_strt <= '0';
          -- Reset latch
          fsm_chkpnt_strt_latch <= '0';

      end case;

      -- Latch (reset only when sys is able to run: energy ok)
      if (fsm_chkpnt_strt = '1') then
        fsm_chkpnt_strt_latch <= '1';
      end if;
    end if;

  end process P_FSM_INTRP_SIG_GEN;

end architecture RTL;
