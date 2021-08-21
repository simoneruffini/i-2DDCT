--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
-- Create Date:     Fri Aug 20 20:57:09 CEST 2021
-- Design Name:     I_2DDCT_TOP_LEVEL_TB
-- Module Name:     I_2DDCT_TOP_LEVEL_TB.vhd - Behavioral
-- Project Name:    i-2DDCT
-- Description:     Top level testbench for i-2DDCT
--
-- Revision:
-- Revision 00 - Simone Ruffini
--  * File created
-- Additional Comments:
--
--------------------------------------------------------------------------------

----------------------------- PACKAGES/LIBRARIES -------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;

-- User libraries

library WORK;
  use WORK.I_2DDCT_PKG.all;
  use WORK.I_2DDCTTB_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity I_2DDCT_TOP_LEVEL_TB is
  --port (
  --);
end entity I_2DDCT_TOP_LEVEL_TB;

----------------------------- ARCHITECTURE -------------------------------------

architecture BEHAVIORAL of I_2DDCT_TOP_LEVEL_TB is

  --########################### CONSTANTS 1 ####################################

  --########################### TYPES ##########################################

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################

  signal clk                           : std_logic;
  signal clk_s                         : std_logic;
  signal gate_clk_s                    : std_logic;

  signal rst                           : std_logic;

  signal din                           : std_logic_vector(C_INDATA_W - 1 downto 0);
  signal idv                           : std_logic;
  signal dout                          : std_logic_vector(C_OUTDATA_W - 1 downto 0);
  signal odv                           : std_logic;

  signal dbufctl_start                 : std_logic;
  signal dbufctl_tx                    : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal dbufctl_rx                    : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal dbufctl_ready                 : std_logic;

  signal ram_pb_start                  : std_logic;
  signal ram_pb_tx                     : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal ram_pb_rx                     : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal ram_pb_ready                  : std_logic;

  signal odv1                          : std_logic;
  signal dcto1                         : std_logic_vector(C_1S_OUTDATA_W - 1 downto 0);

  signal nvm_busy                      : std_logic;
  signal nvm_busy_s                    : std_logic;
  signal nvm_en                        : std_logic;
  signal nvm_we                        : std_logic;
  signal nvm_raddr                     : std_logic_vector(C_NVM_ADDR_W - 1 downto 0);
  signal nvm_waddr                     : std_logic_vector(C_NVM_ADDR_W - 1 downto 0);
  signal nvm_din                       : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal nvm_dout                      : std_logic_vector(C_NVM_DATA_W - 1 downto 0);

  signal sys_enrg_status               : sys_enrg_status_t;                                                                                                     -- System energy status
  signal first_run                     : std_logic;

  signal varc_rdy                      : std_logic;
  signal sys_status                    : sys_status_t;                                                                                                          -- System status value of sys_status_t
  signal nvm_ctrl_sync                 : std_logic;

  signal testend                       : boolean;

  --########################### ARCHITECTURE BEGIN #############################

begin

  --########################### ENTITY DEFINITION ##############################

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |CLKGEN|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_CLKGEN : entity work.clkgen
    generic map (
      CLK_HZ => C_CLK_FREQ_HZ
    )
    port map (
      CLK => clk
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |I_2DDCT|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_I_2DDCT : entity  work.i_2ddct
    port map (
      CLK => clk_s,
      RST => rst,
      --------------------------------------------------------------------------
      DIN  => din,
      IDV  => idv,
      DOUT => dout,
      ODV  => odv,
      --------------------------------------------------------------------------
      -- Intermitent enhancement ports
      FIRST_RUN     => first_run,
      NVM_CTRL_SYNC => nvm_ctrl_sync,
      SYS_STATUS    => sys_status,
      VARC_READY    => varc_rdy,

      RAM_PB_START => ram_pb_start,
      RAM_PB_RX    => ram_pb_rx,
      RAM_PB_TX    => ram_pb_tx,
      RAM_PB_READY => ram_pb_ready,

      DBUFCTL_START => dbufctl_start,
      DBUFCTL_RX    => dbufctl_rx,
      DBUFCTL_TX    => dbufctl_tx,
      DBUFCTL_READY => dbufctl_ready,
      --------------------------------------------------------------------------
      -- debug
      DCTO1 => dcto1,
      ODV1  => odv1
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |NVM_CTRL|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_NVM_CTRL : entity work.nvm_ctrl
    port map (
      CLK => clk,
      RST => rst,
      ----------------------------------------------------------------------------
      NVM_BUSY     => nvm_busy,
      NVM_BUSY_SIG => nvm_busy_s,
      NVM_EN       => nvm_en,
      NVM_WE       => nvm_we,
      NVM_RADDR    => nvm_raddr,
      NVM_WADDR    => nvm_waddr,
      NVM_DIN      => nvm_din,
      NVM_DOUT     => nvm_dout,
      ----------------------------------------------------------------------------
      SYS_ENRG_STATUS => sys_enrg_status,
      FIRST_RUN       => first_run,

      VARC_RDY   => varc_rdy,
      SYS_STATUS => sys_status,
      SYNC       => nvm_ctrl_sync,

      DBUFCTL_START => dbufctl_start,
      DBUFCTL_TX    => dbufctl_tx,
      DBUFCTL_RX    => dbufctl_rx,
      DBUFCTL_READY => dbufctl_ready,

      RAM_PB_START => ram_pb_start,
      RAM_PB_TX    => ram_pb_tx,
      RAM_PB_RX    => ram_pb_rx,
      RAM_PB_READY => ram_pb_ready
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |INP_IMG_GEN|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_INPIMAGE : entity work.inp_img_gen
    port map (
      CLK   => clk_s,
      ODV1  => odv1,
      DCTO1 => dcto1,
      ODV   => odv,
      DCTO  => dout,

      RST     => rst,
      IMAGEO  => din,
      DV      => idv,
      TESTEND => testend
    );

  --########################## OUTPUT PORTS WIRING #############################

  --########################## COBINATORIAL FUNCTIONS ##########################

  gate_clk_s <= '0' when testend = false else
                '1';

  clk_s <= clk and (not gate_clk_s);

  --########################## PROCESSES #######################################
  P_GLOBAL_SIG : process is
  begin

    sys_enrg_status <= sys_enrg_ok;
    first_run       <= '1';
    --wait for 10 * C_CLK_PERIOD_NS;
    --rst             <= '1';
    --wait for C_CLK_PERIOD_NS;
    --rst             <= '0';
    --wait for 10 * C_CLK_PERIOD_NS;
    --first_run <= '0';
    --wait for 300 * C_CLK_PERIOD_NS;
    --sys_enrg_status <= sys_enrg_hazard;
    --wait for 400 * C_CLK_PERIOD_NS;
    --rst             <= '1';
    --sys_enrg_status <= sys_enrg_ok;
    --wait for C_CLK_PERIOD_NS;
    --rst             <= '0';
    --sys_enrg_status <= sys_enrg_ok;
    wait;

  end process P_GLOBAL_SIG;

end architecture BEHAVIORAL;

-----------------------------------

