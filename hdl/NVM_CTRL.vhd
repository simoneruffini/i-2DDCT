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
    CLK                         : in    std_logic;                                          -- Input clock
    RST                         : in    std_logic;                                          -- Positive reset
    ----------------------------------------------------------------------------
    NVM_BUSY                    : in    std_logic;                                          -- Busy signal for Async processes
    NVM_BUSY_SIG                : in    std_logic;                                          -- Busy signal for sync processes (triggered 1 clk before BUSY)
    NVM_EN                      : out   std_logic;                                          -- Enable memory
    NVM_WE                      : out   std_logic;                                          -- Write enable
    NVM_RADDR                   : out   std_logic_vector(NVM_ADDR_W - 1 downto 0);          -- Read address port
    NVM_WADDR                   : out   std_logic_vector(NVM_ADDR_W - 1 downto 0);          -- Write address port
    NVM_DIN                     : out   std_logic_vector(NVM_DATA_W - 1 downto 0);          -- Data input
    NVM_DOUT                    : in    std_logic_vector(NVM_DATA_W - 1 downto 0);          -- Data output from read address
    ----------------------------------------------------------------------------
    V2NV_OR_NV2V_STRT           : in    std_logic;
    V2NV_OR_NV2V_END            : out   std_logic;

    DCT1D_START                 : out   std_logic;
    DCT1D_TX                    : out   std_logic(NVM_ADDR_W - 1 downto 0);
    DCT1D_RX                    : in    std_logic(NVM_ADDR_W - 1 downto 0);

    RAM1_START                  : out   std_logic;
    RAM1_TX                     : out   std_logic(NVM_ADDR_W - 1 downto 0);
    RAM1_RX                     : in    std_logic(NVM_ADDR_W - 1 downto 0);

    RAM2_START                  : out   std_logic;
    RAM2_TX                     : out   std_logic(NVM_ADDR_W - 1 downto 0);
    RAM2_RX                     : in    std_logic(NVM_ADDR_W - 1 downto 0);

    DCT2D_START                 : out   std_logic;
    DCT2D_TX                    : out   std_logic(NVM_ADDR_W - 1 downto 0);
    DCT2D_RX                    : in    std_logic(NVM_ADDR_W - 1 downto 0);

    DBUFCTL_START               : out   std_logic;
    DBUFCTL_TX                  : out   std_logic(NVM_ADDR_W - 1 downto 0);
    DBUFCTL_RX                  : in    std_logic(NVM_ADDR_W - 1 downto 0)
  );
end entity NVM_CTRL;

architecture RTL of NVM_CTRL is

  --########################### CONSTANTS 1 ####################################

  constant C_NVM_DCT1D_STRT_ADDR   : narual := 0;
  constant C_NVM_DCT1D_OFFSET      : narual := (N + 1) - 1;

  constant C_NVM_RAM1_STRT_ADDR    : narual := C_NVM_DCT1D_STRT_ADDR + C_NVM_DCT1D_OFFSET + 1;
  constant C_NVM_RAM1_OFFSET       : narual := (2 ** RAMADRR_W) - 1;

  constant C_NVM_RAM2_STRT_ADDR    : narual := C_NVM_RAM1_STRT_ADDR + C_NVM_RAM1_OFFSET + 1;
  constant C_NVM_RAM2_OFFSET       : narual := C_NVM_RAM1_OFFSET;

  constant C_NVM_DCT2D_STRT_ADDR   : narual := C_NVM_RAM2_STRT_ADDR + C_NVM_RAM2_OFFSET + 1;
  constant C_NVM_DCT2D_OFFSET      : narual := C_NVM_DCT1D_OFFSET;

  constant C_NVM_DBUFCTL_STRT_ADDR : narual := C_NVM_DCT2D_STRT_ADDR + C_NVM_DCT2D_OFFSET + 1;
  constant C_NVM_DBUFCTL_OFFSET    : narual := 1;

  --########################### TYPES ##########################################

  type fsm_t is (
    S_INIT,
    S_NV2V_PUSH,
    S_WAIT_VARC_READY,
    S_PROC_ON,
    S_WAIT_V2NV_PUSH,
    S_V2NV_PUSH
  );

  type proc_blk_order_t is (
    dct1ds
    ram1,
    ram2,
    dct2d,
    dbufctl,
    num_proc_blk_order_t
  );

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  constant C_STAGES_IN_CHKP_PROC   : natural := proc_blk_order_t'pos(num_proc_blk_order_t); -- DCT1D, RAM1,RAM2,DCT2D,DBUFCTL

  --########################### SIGNALS ########################################

  signal varc_ready                : std_logic;                                             -- volatile architecutre ready
  signal proc_strt                 : std_logic;
  signal proc_end                  : std_logic;

  signal start_arr                 : std_logic_vector(C_STAGES_IN_CHKP_PROC downto 0);      -- 1 extra entry because of last PBSM start_out
  signal pb_ready_arr              : std_logic_vector(C_STAGES_IN_CHKP_PROC - 1 downto 0);
  signal pb_start_arr              : std_logic_vector(C_STAGES_IN_CHKP_PROC - 1 downto 0);

  signal m_fsm_pres_state          : fsm_t;                                                 -- main fsm present state
  signal m_fsm_fut_state           : fsm_t;                                                 -- main fsm future state

  signal v2nv                      : std_logic;                                             -- volatile to non volatile flag
  signal nv2v                      : std_logic;                                             -- non volatile to volatile flag

  signal nvm_addr                  : unsigned(NVM_ADDR_W - 1 downto 0);
  signal pb_dct1d_en               : std_logic;
  signal pb_dct2d_en               : std_logic;
  signal pb_ram1_en                : std_logic;
  signal pb_ram2_en                : std_logic;
  signal pb_dbufctl_en             : std_logic;

  --########################### ARCHITECTURE BEGIN #############################

begin

  --########################### ENTITY DEFINITION ##############################

  G_PBSM : for i in 0 to C_STAGES_IN_CHKP_PROC - 1 generate

    U_PBSM : entity  work.pbsm
      port map (
        CLK => CLK,
        RST => RST,
        -- from/to PBSM(m-1
        START_I => start_arr(i),
        -- from/to PBSM(m+1
        START_O => start_arr(i + 1),
        -- from/to processi
        PB_RDY_I   => pb_ready_arr(i),
        PB_START_O => pb_start_arr(i)
      );

  end generate G_PBSM;

  --########################## OUTPUT PORTS WIRING#############################
  proc_start       <= V2NV_OR_NV2V_STRT;
  start_arr(0)     <= proc_start;                        -- first start in PBSM chain is piloted by proc_start
  proc_end         <= start_arr(C_STAGES_IN_CHKP_PROC);  -- when last PBSM signals a statrt means that all PBSM completed
  V2NV_OR_NV2V_END <= proc_end;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Each PBSM regulates a process block with the below sibnals.
  -- These process blocks regulate access to and from NVM for checkpopinting operations
  -- Hence the PBSM to process block mapping defines the order of execution of PBs
  -- pb_ready_arr(proc_blk_order_t'pos(dct1d)) <= DCT1D_READY;
  DCT1D_START <= pb_start_arr(proc_blk_order_t'pos(dct1d));

  --pb_ready_arr(proc_blk_order_t'pos(ram1)) <= RAM1_READY;
  RAM1_START <= pb_start_arr(proc_blk_order_t'pos(ram1));

  --pb_ready_arr(proc_blk_order_t'pos(ram2)) <= RAM2_READY;
  RAM2_START <= pb_start_arr(proc_blk_order_t'pos(ram2));

  --pb_ready_arr(proc_blk_order_t'pos(dct2d)) <= DCT2D_READY;
  DCT2D_START <= pb_start_arr(proc_blk_order_t'pos(dct2d));

  --pb_ready_arr(proc_blk_order_t'pos(dbufctl)) <= DBUFCTL_READY;
  DBUFCTL_START <= pb_start_arr(proc_blk_order_t'pos(dbufct));

  NVM_RADDR <= std_logic(nvm_addr) when nv2v ='1' else
               not std_logic(nvm_addr);
  NVM_WADDR <= std_logic(nvm_addr) when v2nv ='1' else
               not std_logic(nvm_addr);

  NVM_DIN <= DCT1D_RX    when pb_dct1d_en= '1'     else
             RAM1_RX     when pb_ram1_en= '1'      else
             RAM2_RX     when pb_ram2_en= '1'      else
             DCT2D_RX    when pb_dct2d_en= '1'     else
             DBUFCTL_RX  when pb_dbufctl_en = '1'  else
             (others => '0');

  DCT1D_TX   <= NVM_DOUT when pb_dct1d_en = '1' else
                (others => '0');
  RAM1_TX    <= NVM_DOUT when pb_ram1_en = '1' else
                (others => '0');
  RAM2_TX    <= NVM_DOUT when pb_ram2_en = '1' else
                (others => '0');
  DCT2D_TX   <= NVM_DOUT when pb_dct2d_en = '1' else
                (others => '0');
  DBUFCTL_TX <= NVM_DOUT when pb_dbufctl_en = '1' else
                (others => '0');
  --########################## COBINATORIAL FUNCTIONS ##########################

  --########################## PROCESSES #######################################

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- sequential process for main fsm (synthesized FFs)

  P_M_FSM_SEQ : process (CLK, RST) is
  begin

    if (RST = '1') then
      m_fsm_pres_state <= S_INIT;
    elsif (CLK'event and CLK = '1') then
      m_fsm_pres_state <= m_fsm_fut_state;
    end if;

  end process P_M_FSM_SEQ;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Future state computation for main fsm (combinatorial process)

  P_M_FSM_FUT_S : process (m_fsm_pres_state, varc_ready, proc_end, V2NV_START) is
  begin

    case m_fsm_pres_state is

      when S_INIT =>
        m_fsm_fut_state <= S_NV2V_PUSH;
      when S_NV2V_PUSH =>
        m_fsm_fut_state <= S_WAIT_VARC_READY;
      when S_WAIT_VARC_READY =>

        if (varc_ready = '1') then
          m_fsm_fut_state <= S_PROC_ON;
        end if;

      when S_PROC_ON =>

        if (proc_end = '1') then
          m_fsm_fut_state <= S_WAIT_V2NV_PUSH;
        end if;

      when S_WAIT_V2NV_PUSH =>

        if (V2NV_START = '1') then
          m_fsm_fut_state <= S_V2NV_PUSH;
        end if;

      when S_V2NV_PUSH =>
        m_fsm_fut_state <= S_WAIT_VARC_READY;

    end case;

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- Output generator for a mealy fsm (output depends on input)

    P_M_FSM_OUTPUTS : process (m_fsm_pres_state, varc_ready) is
    begin

    -- defaults
    -- By defining them the synthesizer produces a combinatrial logic without FFs
    proc_strt <= '0';
    proc_end  <= '0';

    case m_fsm_pres_state is

      when S_INIT =>
      when S_NV2V_PUSH =>
      when S_WAIT_VARC_READY =>

        if (varc_ready = '1') then
          proc_strt <= '1';
        end if;

      when S_PROC_ON =>
      when S_WAIT_V2NV_PUSH =>
      when S_V2NV_PUSH =>

    end case;

  end process P_M_FSM_OUTPUTS;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Latch process for v2nv and nv2v signals

  P_V2NV_NV2V_LATCH : process (CLK, RST) is
  begin

    if (RST = '1') then
      nv2v <= '0';
      v2nv <= '0';
    elsif (CLK'event and CLK = '1') then
      if (m_fsm_pres_state = S_V2NV_PUSH) then
        v2nv <= '1';
      elsif (m_fsm_pres_state = S_NV2V_PUSH) then
        nv2v <= '1';
      end if;
      if (proc_end= '1') then
        nv2v <= '0';
        v2nv <= '0';
      end if;
    end if;

  end process P_V2NV_NV2V_LATCH;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Process blocks process, managaes NVM access

  P_PROC_BLOCK : process (CLK, RST) is
  begin

    if (RST ='1') then
      nvm_addr      <= (others => '0');
      NVM_WE        <= '0';
      pb_ready_arr  <= (others => '0');
      pb_dct1d_en   <= '0';
      pb_dct2d_en   <= '0';
      pb_ram1_en    <= '0';
      pb_ram2_en    <= '0';
      pb_dbufctl_en <= '0';
    elsif (CLK'event and CLK = '1') then
      if (pb_dct1d_en ='1') then
        if (nvm_addr = C_NVM_DCT1D_STRT_ADDR + C_NVM_DCT1D_OFFSET) then
          NVM_EN                                    <= '0';
          pb_ready_arr(proc_blk_order_t'pos(dct1d)) <= '1';
          pb_dct1d_en                               <= '0';
        end if;
        if (NVM_BUSY = '1') then
          nvm_addr <= nvm_addr + 1;
        end if;
      elsif (pb_ram1_en ='1') then
        if (nvm_addr = C_NVM_RAM1_STRT_ADDR + C_NVM_RAM1_OFFSET) then
          NVM_EN                                   <= '0';
          pb_ready_arr(proc_blk_order_t'pos(ram1)) <= '1';
          pb_ram1_en                               <= '0';
        end if;
        if (NVM_BUSY = '1') then
          nvm_addr <= nvm_addr + 1;
        end if;
      elsif (pb_ram2_en = '1') then
        if (nvm_addr = C_NVM_RAM2_STRT_ADDR + C_NVM_RAM2_OFFSET) then
          NVM_EN                                   <= '0';
          pb_ready_arr(proc_blk_order_t'pos(ram2)) <= '1';
          pb_ram2_en                               <= '0';
        end if;
        if (NVM_BUSY = '1') then
          nvm_addr <= nvm_addr + 1;
        end if;
      elsif (pb_dct2d ='1') then
        if (nvm_addr = C_NVM_DCT2D_STRT_ADDR + C_NVM_DCT2D_OFFSET) then
          NVM_EN                                    <= '0';
          pb_ready_arr(proc_blk_order_t'pos(dct2d)) <= '1';
          pb_dct2d_en                               <= '0';
        end if;
        if (NVM_BUSY = '1') then
          nvm_addr <= nvm_addr + 1;
        end if;
      elsif (pb_dbufctl_en = '1') then
        if (nvm_addr = C_NVM_DBUFCTL_STRT_ADDR + C_NVM_DBUFCTL_OFFSET) then
          NVM_EN                                      <= '0';
          pb_ready_arr(proc_blk_order_t'pos(dbufctl)) <= '1';
          pb_dbufctl_en                               <= '0';
        end if;
        if (NVM_BUSY = '1') then
          nvm_addr <= nvm_addr + 1;
        end if;
      end if;

      if (pb_start_arr(proc_blk_order_t'pos(dct1d))='1') then
        nvm_addr                                  <= to_unsigned(C_NVM_DCT1D_STRT_ADDR, nvm_addr'length);
        NVM_EN                                    <= '1';
        pb_ready_arr(proc_blk_order_t'pos(dct1d)) <= '0';
        pb_dct1d_en                               <= '1';
      elsif (pb_start_arr(proc_blk_order_t'pos(ram1))='1') then
        nvm_addr                                 <= to_unsigned(C_NVM_RAM1_STRT_ADDR, nvm_addr'length);
        NVM_EN                                   <= '1';
        pb_ready_arr(proc_blk_order_t'pos(ram1)) <= '0';
        pb_ram1_en                               <= '1';
      elsif (pb_start_arr(proc_blk_order_t'pos(ram2))='1') then
        nvm_addr                                 <= to_unsigned(C_NVM_RAM2_STRT_ADDR, nvm_addr'length);
        NVM_EN                                   <= '1';
        pb_ready_arr(proc_blk_order_t'pos(ram2)) <= '0';
        pb_ram2_en                               <= '1';
      elsif (pb_start_arr(proc_blk_order_t'pos(dct2d))='1') then
        nvm_addr                                  <= to_unsigned(C_NVM_DCT2D_STRT_ADDR, nvm_addr'length);
        NVM_EN                                    <= '1';
        pb_ready_arr(proc_blk_order_t'pos(dct2d)) <= '0';
        pb_dct2d_en                               <= '1';
      elsif (pb_start_arr(proc_blk_order_t'pos(dbufctl))='1') then
        nvm_addr                                    <= to_unsigned(C_NVM_DBUFCTL_STRT_ADDR, nvm_addr'length);
        NVM_EN                                      <= '1';
        pb_ready_arr(proc_blk_order_t'pos(dbufctl)) <= '0';
        pb_dbufctl_en                               <= '1';
      elsif (pb_start_arr(C_STAGES_IN_CHKP_PROC) = '1') then
        nvm_addr     <= (others => '0');
        NVM_EN       <= '0';
        pb_ready_arr <= (others => '0');
      end if;

      if (v2nv='1' and proc_start = '1') then
        NVM_WE <= '1';
      elsif (nv2v = '1' or proc_end ='1') then
        NVM_WE <= '0';
      end if;
    end if;

  end process P_PROC_BLOCK;

end architecture RTL;
