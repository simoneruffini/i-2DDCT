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
    CLK                             : in    std_logic;                                       -- Input clock
    RST                             : in    std_logic;                                       -- Positive reset
    ----------------------------------------------------------------------------
    DIN                             : in    std_logic_vector(C_INDATA_W - 1 downto 0);       -- 2DDCT data input
    IDV                             : in    std_logic;                                       -- Input data valid
    DOUT                            : out   std_logic_vector(C_OUTDATA_W - 1 downto 0);      -- 2DDCT data output
    ODV                             : out   std_logic;                                       -- Output data valid
    ----------------------------------------------------------------------------
    -- Intermitent enhancement ports
    FIRST_RUN                       : in    std_logic;
    DATA_SYNC                   : in    std_logic;
    SYS_STATUS                      : in    sys_status_t;
    VARC_READY                      : out   std_logic;

    RAM_PB_START                    : in    std_logic;
    RAM_PB_RX                       : in    std_logic_vector(C_NVM_DATA_W - 1 downto 0);
    RAM_PB_TX                       : out   std_logic_vector(C_NVM_DATA_W - 1 downto 0);
    RAM_PB_READY                    : out   std_logic;

    DBUFCTL_START                   : in    std_logic;
    DBUFCTL_RX                      : in    std_logic_vector(C_NVM_DATA_W - 1 downto 0);
    DBUFCTL_TX                      : out   std_logic_vector(C_NVM_DATA_W - 1 downto 0);
    DBUFCTL_READY                   : out   std_logic;
    ----------------------------------------------------------------------------
    -- debug
    DCTO1                           : out   std_logic_vector(C_1S_OUTDATA_W - 1 downto 0);   -- DCT output of first stage
    ODV1                            : out   std_logic                                        -- Output data valid of first stage
  );
end entity I_2DDCT;

----------------------------- ARCHITECTURE -------------------------------------

architecture RTL of I_2DDCT is

  --########################### CONSTANTS 1 ####################################

  --########################### TYPES ##########################################

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################

  signal i_dct1s_waddr                 : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM write address output
  signal i_dct1s_raddr                 : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM read address
  signal i_dct1s_din                   : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data input
  signal i_dct1s_dout                  : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data out
  signal i_dct1s_we                    : std_logic;                                                                                                             -- RAM write enable

  signal frame_cmplt                   : std_logic;                                                                                                             -- Write memory select signal

  signal i_dct1s_varc_rdy              : std_logic;

  signal i_dct2s_waddr                 : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM write address output
  signal i_dct2s_raddr                 : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM read address
  signal i_dct2s_din                   : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data input
  signal i_dct2s_dout                  : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data out
  signal i_dct2s_we                    : std_logic;                                                                                                             -- RAM write enable

  signal i_dct2s_varc_rdy              : std_logic;

  signal ram1_waddr, ram2_waddr        : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM write address output
  signal ram1_raddr, ram2_raddr        : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM read address
  signal ram1_din,   ram2_din          : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data input
  signal ram1_dout,  ram2_dout         : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data out
  signal ram1_we,    ram2_we           : std_logic;                                                                                                             -- RAM write enable

  signal rome1_addr                    : rom1_addr_t;                                                                                                           -- ROME address output
  signal romo1_addr                    : rom1_addr_t;                                                                                                           -- ROMO address output
  signal rome1_dout                    : rom1_data_t;                                                                                                           -- ROME data output
  signal romo1_dout                    : rom1_data_t;                                                                                                           -- ROMO data output

  signal rome2_addr                    : rom2_addr_t;                                                                                                           -- ROME address output
  signal romo2_addr                    : rom2_addr_t;                                                                                                           -- ROMO address output
  signal rome2_dout                    : rom2_data_t;                                                                                                           -- ROME data output
  signal romo2_dout                    : rom2_data_t;                                                                                                           -- ROMO data output

  signal dbufctl_memsel                : std_logic;

  signal ram_pb_ram1_din               : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal ram_pb_ram2_din               : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal ram_pb_ram_waddr              : std_logic_vector(C_RAMADDR_W - 1 downto 0);
  signal ram_pb_ram_raddr              : std_logic_vector(C_RAMADDR_W - 1 downto 0);
  signal ram_pb_ram_we                 : std_logic;
  signal ram_pb_ram1_dout              : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal ram_pb_ram2_dout              : std_logic_vector(C_RAMDATA_W - 1 downto 0);

  -- TODO delete
  signal dbufctl_pb_ready_s            : std_logic;
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
      FRAME_CMPLT => frame_cmplt,
      -- debug -------------------------------------------------
      ODV  => odv1,
      DCTO => dcto1,
      -- Intermittent Enhancment Ports -------------------------
      SYS_STATUS => SYS_STATUS,
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
      NEW_FRAME => frame_cmplt,
      -- Intermittent Enhancment Ports -------------------------
      SYS_STATUS     => SYS_STATUS,
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

  ----~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ---- |DBUFCTL|
  ----~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  --U_DBUFCTL : entity work.dbufctl
  --  port map (
  --    CLK          => CLK,
  --    RST          => RST,
  --    WMEMSEL      => wmemsel_s,
  --    RMEMSEL      => rmemsel_s,
  --    DATAREADYACK => datareadyack_s,

  --    MEMSWITCHWR => memswitchwr_s,
  --    MEMSWITCHRD => memswitchrd_s,
  --    DATAREADY   => dataready_s
  --  );

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
      SYS_STATUS         => SYS_STATUS,
      I_DCT1S_VARC_READY => i_dct1s_varc_rdy,
      I_DCT2S_VARC_READY => i_dct2s_varc_rdy,
      DBUFCTL_MEMSEL     => dbufctl_memsel,
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
      SYS_STATUS    => SYS_STATUS,
      DATA_SYNC => DATA_SYNC,
      ----------------------------------------------------------
      START => RAM_PB_START,
      RX    => RAM_PB_RX,
      TX    => RAM_PB_TX,
      READY => RAM_PB_READY,
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
  -- |DBUFCTL_PB|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  P_DBUFCTL : process (clk, rst) is
  begin

    if (rst = '1') then
      dbufctl_memsel <= '0';
      dbufctl_ready  <= '1';
      dbufctl_ready  <= '1';
    elsif (clk'event AND clk = '1') then
      if (frame_cmplt = '1') then
        dbufctl_memsel <= not dbufctl_memsel;
      end if;
      if (DBUFCTL_START = '1') then
        dbufctl_pb_ready_s <= '0';
        DBUFCTL_TX         <= (0=>dbufctl_memsel, others => '0');
      end if;
      if (dbufctl_pb_ready_s = '0') then
        if (data_sync = '0') then
          dbufctl_pb_ready_s <= '1';
        end if;
      end if;
    end if;

  end process P_DBUFCTL;

  --########################## OUTPUT PORTS WIRING #############################
  VARC_READY    <= i_dct1s_varc_rdy AND i_dct2s_varc_rdy;
  DBUFCTL_READY <= dbufctl_pb_ready_s;

  --########################## COBINATORIAL FUNCTIONS ##########################

  --########################## PROCESSES #######################################

end architecture RTL;

----------------------------- ARCHITECTURE -------------------------------------
