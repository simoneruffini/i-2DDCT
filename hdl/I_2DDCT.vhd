--------------------------------------------------------------------------------
-- Engineer:  Michal Krepa
--            Simone Ruffini [simone.ruffini@tutanota.com]
--
-- Create Date:     Sat Feb 25 16:12 2006
-- Design Name:     2DDCT core
-- Module Name:     2DDCT.vhd - RTL
-- Project Name:    i-2DDCT
-- Description:     Two-dimensional Discrete Cosine Transform module
--                  top level with memories
--
-- Revision:
-- Revision 00 - Michal Krepa
--  * File Created
-- Revision 01 - Simone Ruffini
--  * Refactoring + comments
-- Additional Comments:
--
--------------------------------------------------------------------------------

----------------------------- PACKAGES/LIBRARIES -------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;

-- User libraries

library WORK;
  use WORK.I_2DDCT_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity I_2DDCT is
  port (
    CLK                             : in    std_logic;                                                   -- Input clock
    RST                             : in    std_logic;                                                   -- Positive reset
    ----------------------------------------------------------------------------
    DIN                             : in    std_logic_vector(C_INDATA_W - 1 downto 0);                   -- 2DDCT data input
    IDV                             : in    std_logic;                                                   -- Input data valid
    DOUT                            : out   std_logic_vector(C_OUTDATA_W - 1 downto 0);                  -- 2DDCT data output
    ODV                             : out   std_logic;                                                   -- Output data valid
    ----------------------------------------------------------------------------
    -- Intermitent enhancement ports
    NVM_BUSY                        : in    std_logic;                                                   -- Busy signal for Async processes
    NVM_BUSY_SIG                    : in    std_logic;                                                   -- Busy signal for sync processes (triggered 1 clk before BUSY)
    NVM_EN                          : out   std_logic;                                                   -- Enable memory
    NVM_WE                          : out   std_logic;                                                   -- Write enable
    NVM_RADDR                       : out   std_logic_vector(C_NVM_ADDR_W - 1 downto 0);                 -- Read address port
    NVM_WADDR                       : out   std_logic_vector(C_NVM_ADDR_W - 1 downto 0);                 -- Write address port
    NVM_DIN                         : out   std_logic_vector(C_NVM_DATA_W - 1 downto 0);                 -- Data input
    NVM_DOUT                        : in    std_logic_vector(C_NVM_DATA_W - 1 downto 0);                 -- Data output from read address

    SYS_STATUS                      : out   sys_status_t;
    SYS_ENRG_STATUS                 : in    sys_enrg_status_t;                                           -- System Energy status
    FIRST_RUN                       : in    std_logic;                                                   -- First system run
    ----------------------------------------------------------------------------
    -- debug
    DCTO1                           : out   std_logic_vector(C_1S_OUTDATA_W - 1 downto 0);               -- DCT output of first stage
    ODV1                            : out   std_logic                                                    -- Output data valid of first stage
  );
end entity I_2DDCT;

----------------------------- ARCHITECTURE -------------------------------------

architecture RTL of I_2DDCT is

  --########################### CONSTANTS 1 ####################################

  --########################### TYPES ##########################################

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################

  signal i_dct1s_waddr                                        : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM write address output
  signal i_dct1s_raddr                                        : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM read address
  signal i_dct1s_din                                          : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data input
  signal i_dct1s_dout                                         : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data out
  signal i_dct1s_we                                           : std_logic;                                                                                                             -- RAM write enable

  signal i_dct1s_block_cmplt                                  : std_logic;                                                                                                             -- Write memory select signal
  signal i_dct1s_varc_rdy                                     : std_logic;

  signal i_dct2s_waddr                                        : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM write address output
  signal i_dct2s_raddr                                        : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM read address
  signal i_dct2s_din                                          : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data input
  signal i_dct2s_dout                                         : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data out
  signal i_dct2s_we                                           : std_logic;                                                                                                             -- RAM write enable

  signal i_dct2s_data_ready_ack                               : std_logic;
  signal i_dct2s_block_cmplt                                  : std_logic;                                                                                                             -- Write memory select signal
  signal i_dct2s_varc_rdy                                     : std_logic;

  signal varc_rdy                                             : std_logic;
  signal sys_status_s                                         : sys_status_t;                                                                                                          -- System status value of sys_status_t
  signal sys_status_s_d                                       : sys_status_t;                                                                                                          -- System status value delay of sys_status_t
  signal data_sync                                            : std_logic;

  signal ram1_waddr, ram2_waddr                               : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM write address output
  signal ram1_raddr, ram2_raddr                               : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM read address
  signal ram1_din,   ram2_din                                 : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data input
  signal ram1_dout,  ram2_dout                                : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data out
  signal ram1_we,    ram2_we                                  : std_logic;                                                                                                             -- RAM write enable

  signal rome1_addr                                           : rom1_addr_t;                                                                                                           -- ROME address output
  signal romo1_addr                                           : rom1_addr_t;                                                                                                           -- ROMO address output
  signal rome1_dout                                           : rom1_data_t;                                                                                                           -- ROME data output
  signal romo1_dout                                           : rom1_data_t;                                                                                                           -- ROMO data output

  signal rome2_addr                                           : rom2_addr_t;                                                                                                           -- ROME address output
  signal romo2_addr                                           : rom2_addr_t;                                                                                                           -- ROMO address output
  signal rome2_dout                                           : rom2_data_t;                                                                                                           -- ROME data output
  signal romo2_dout                                           : rom2_data_t;                                                                                                           -- ROMO data output

  signal i_dbufctl_wmemsel                                    : std_logic;
  signal i_dbufctl_rmemsel                                    : std_logic;
  signal i_dbufctl_data_ready                                 : std_logic;

  signal i_dbufctl_start                                      : std_logic;
  signal i_dbufctl_tx                                         : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal i_dbufctl_rx                                         : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal i_dbufctl_ready                                      : std_logic;

  signal ram_pb_ram1_din                                      : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal ram_pb_ram2_din                                      : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal ram_pb_ram_waddr                                     : std_logic_vector(C_RAMADDR_W - 1 downto 0);
  signal ram_pb_ram_raddr                                     : std_logic_vector(C_RAMADDR_W - 1 downto 0);
  signal ram_pb_ram_we                                        : std_logic;
  signal ram_pb_ram1_dout                                     : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal ram_pb_ram2_dout                                     : std_logic_vector(C_RAMDATA_W - 1 downto 0);

  signal ram_pb_start                                         : std_logic;
  signal ram_pb_tx                                            : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal ram_pb_rx                                            : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal ram_pb_ready                                         : std_logic;

  --########################### ARCHITECTURE BEGIN #############################

begin

  --########################### ENTITY DEFINITION ##############################

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |IDCT1S|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_I_DCT1S : entity work.i_dct1s
    port map (
      CLK => CLK,
      RST => RST,
      ----------------------------------------------------------
      DCTI => DIN,
      IDV  => IDV,
      ----------------------------------------------------------
      ROME_ADDR => rome1_addr,
      ROMO_ADDR => romo1_addr,
      ROME_DOUT => rome1_dout,
      ROMO_DOUT => romo1_dout,
      ----------------------------------------------------------
      RAM_WADDR   => i_dct1s_waddr,
      RAM_RADDR   => i_dct1s_raddr,
      RAM_DIN     => i_dct1s_din,
      RAM_DOUT    => i_dct1s_dout,
      RAM_WE      => i_dct1s_we,
      BLOCK_CMPLT => i_dct1s_block_cmplt,
      -- debug -------------------------------------------------
      ODV  => ODV1,
      DCTO => DCTO1,
      -- Intermittent Enhancment Ports -------------------------
      SYS_STATUS => sys_status_s,
      VARC_RDY   => i_dct1s_varc_rdy
      ----------------------------------------------------------
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |IDCT2S|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_I_DCT2S : entity work.i_dct2s
    port map (
      CLK => CLK,
      RST => RST,
      ----------------------------------------------------------
      RAM_WADDR => i_dct2s_waddr,
      RAM_RADDR => i_dct2s_raddr,
      RAM_DIN   => i_dct2s_din,
      RAM_DOUT  => i_dct2s_dout,
      RAM_WE    => i_dct2s_we,
      ----------------------------------------------------------
      ROME_ADDR => rome2_addr,
      ROMO_ADDR => romo2_addr,
      ROME_DOUT => rome2_dout,
      ROMO_DOUT => romo2_dout,
      ----------------------------------------------------------
      ODV  => ODV,
      DCTO => DOUT,
      ----------------------------------------------------------
      BLOCK_CMPLT    => i_dct2s_block_cmplt,
      DATA_READY     => i_dbufctl_data_ready,
      DATA_READY_ACK => i_dct2s_data_ready_ack,
      -- Intermittent Enhancment Ports -------------------------
      SYS_STATUS     => sys_status_s,
      DCT1S_VARC_RDY => i_dct1s_varc_rdy,
      VARC_RDY       => i_dct2s_varc_rdy
      ----------------------------------------------------------
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |RAM1|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U1_RAM : entity work.ram
    generic map (
      DATA_W => C_RAMDATA_W,
      ADDR_W => C_RAMADDR_W
    )
    port map (
      CLK => CLK,

      DIN   => ram1_din,
      WADDR => ram1_waddr,
      RADDR => ram1_raddr,
      WE    => ram1_we,
      DOUT  => ram1_dout
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |RAM2|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U2_RAM : entity work.ram
    generic map (
      DATA_W => C_RAMDATA_W,
      ADDR_W => C_RAMADDR_W
    )
    port map (
      CLK => CLK,

      DIN   => ram2_din,
      WADDR => ram2_waddr,
      RADDR => ram2_raddr,
      WE    => ram2_we,
      DOUT  => ram2_dout
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |DBUFCTL|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_I_DBUFCTL : entity  work.i_dbufctl
    port map (
      CLK                 => clk,
      RST                 => rst,
      I_DCT1S_BLOCK_CMPLT => i_dct1s_block_cmplt,
      I_DCT2S_BLOCK_CMPLT => i_dct2s_block_cmplt,
      WMEMSEL             => i_dbufctl_wmemsel,
      RMEMSEL             => i_dbufctl_rmemsel,
      DATA_READY          => i_dbufctl_data_ready,
      DATA_READY_ACK      => i_dct2s_data_ready_ack,

      SYS_STATUS => sys_status_s,
      DATA_SYNC  => data_sync,
      PB_READY   => i_dbufctl_ready,
      RX         => i_dbufctl_rx,
      TX         => i_dbufctl_tx,
      PB_START   => i_dbufctl_start
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |First stage ROMs|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  G_ROM_ST1 : for i in 0 to 8 generate

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- |ROME|
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    U1_ROME : entity work.rome
      port map (
        ADDR => rome1_addr(i),
        CLK  => CLK,

        DOUT => rome1_dout(i)
      );

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- |ROMO|
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    U1_ROMO : entity work.romo
      port map (
        ADDR => romo1_addr(i),
        CLK  => CLK,

        DOUT => romo1_dout(i)
      );

  end generate G_ROM_ST1;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |Second stage ROMs|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  G_ROM_ST2 : for i in 0 to 10 generate

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- |ROME|
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    U2_ROME : entity work.rome
      port map (
        ADDR => rome2_addr(i),
        CLK  => CLK,

        DOUT => rome2_dout(i)
      );

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- |ROMO|
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    U2_ROMO : entity work.romo
      port map (
        ADDR => romo2_addr(i),
        CLK  => CLK,

        DOUT => romo2_dout(i)
      );

  end generate G_ROM_ST2;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |RAM_MUX|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  U_RAM_MUX : entity work.ram_mux
    port map (
      -- MUX control ports
      SYS_STATUS         => sys_status_s_d,
      I_DCT1S_VARC_READY => i_dct1s_varc_rdy,
      I_DCT2S_VARC_READY => i_dct2s_varc_rdy,
      I_DBUFCTL_WMEMSEL  => i_dbufctl_wmemsel,
      I_DBUFCTL_RMEMSEL  => i_dbufctl_rmemsel,
      -- TO/FROM RAM 1
      R1_DIN   => ram1_din,
      R1_WADDR => ram1_waddr,
      R1_RADDR => ram1_raddr,
      R1_WE    => ram1_we,
      R1_DOUT  => ram1_dout,
      -- TO/FROM RAM 2
      R2_DIN   => ram2_din,
      R2_WADDR => ram2_waddr,
      R2_RADDR => ram2_raddr,
      R2_WE    => ram2_we,
      R2_DOUT  => ram2_dout,
      -- I_DCT1S RAM ports
      I_DCT1S_DIN   => i_dct1s_din,
      I_DCT1S_WADDR => i_dct1s_waddr,
      I_DCT1S_RADDR => i_dct1s_raddr,
      I_DCT1S_WE    => i_dct1s_we,
      I_DCT1S_DOUT  => i_dct1s_dout,
      -- I_DCT2S RAM ports
      I_DCT2S_DIN   => i_dct2s_din,
      I_DCT2S_WADDR => i_dct2s_waddr,
      I_DCT2S_RADDR => i_dct2s_raddr,
      I_DCT2S_WE    => i_dct2s_we,
      I_DCT2S_DOUT  => i_dct2s_dout,
      -- RAM_PB RAM ports
      RAM_PB_RAM1_DIN  => ram_pb_ram1_din,
      RAM_PB_RAM2_DIN  => ram_pb_ram2_din,
      RAM_PB_RAM_WADDR => ram_pb_ram_waddr,
      RAM_PB_RAM_RADDR => ram_pb_ram_raddr,
      RAM_PB_RAM_WE    => ram_pb_ram_we,
      RAM_PB_RAM1_DOUT => ram_pb_ram1_dout,
      RAM_PB_RAM2_DOUT => ram_pb_ram2_dout
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |RAMP_PB|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  U_RAM_PB : entity work.ram_pb
    port map (
      CLK => CLK,
      RST => RST,
      ----------------------------------------------------------
      SYS_STATUS => sys_status_s,
      DATA_SYNC  => data_sync,
      ----------------------------------------------------------
      START => ram_pb_start,
      RX    => ram_pb_rx,
      TX    => ram_pb_tx,
      READY => ram_pb_ready,
      ----------------------------------------------------------
      RAM1_DIN  => ram_pb_ram1_din,
      RAM2_DIN  => ram_pb_ram2_din,
      RAM_WADDR => ram_pb_ram_waddr,
      RAM_RADDR => ram_pb_ram_raddr,
      RAM_WE    => ram_pb_ram_we,
      RAM1_DOUT => ram_pb_ram1_dout,
      RAM2_DOUT => ram_pb_ram2_dout
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |I_2DDCT_CTRL|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_I_2DDCT_CTRL : entity work.i_2ddct_ctrl
    port map (
      CLK => CLK,
      RST => RST,
      --------------------------------------------------------------------------
      NVM_BUSY     => NVM_BUSY,
      NVM_BUSY_SIG => NVM_BUSY_SIG,
      NVM_EN       => NVM_EN,
      NVM_WE       => NVM_WE,
      NVM_RADDR    => NVM_RADDR,
      NVM_WADDR    => NVM_WADDR,
      NVM_DIN      => NVM_DIN,
      NVM_DOUT     => NVM_DOUT,
      --------------------------------------------------------------------------
      SYS_ENRG_STATUS => SYS_ENRG_STATUS,
      FIRST_RUN       => FIRST_RUN,

      VARC_RDY   => varc_rdy,
      SYS_STATUS => sys_status_s,
      DATA_SYNC  => data_sync,

      DBUFCTL_START => i_dbufctl_start,
      DBUFCTL_TX    => i_dbufctl_tx,
      DBUFCTL_RX    => i_dbufctl_rx,
      DBUFCTL_READY => i_dbufctl_ready,

      RAM_PB_START => ram_pb_start,
      RAM_PB_TX    => ram_pb_tx,
      RAM_PB_RX    => ram_pb_rx,
      RAM_PB_READY => ram_pb_ready
    );

  --########################## OUTPUT PORTS WIRING #############################
  SYS_STATUS <= sys_status_s;

  --########################## COBINATORIAL FUNCTIONS ##########################
  varc_rdy <= i_dct1s_varc_rdy AND i_dct2s_varc_rdy;

  --########################## PROCESSES #######################################

  P_DELAYS : process (CLK) is
  begin

    if (CLK'event and CLK = '1') then
      sys_status_s_d <= sys_status_s;
    end if;

  end process P_DELAYS;

end architecture RTL;

----------------------------- ARCHITECTURE -------------------------------------
