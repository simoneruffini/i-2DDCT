--------------------------------------------------------------------------------
-- Engineer:  Michal Krepa
--            Simone Ruffini [simone.ruffini@tutanota.com]
--
-- Create Date:     Sat Feb 25 16:12 2006
-- Design Name:     MDCT core
-- Module Name:     MDCT.vhd - RTL
-- Project Name:    iMDCT
-- Description:     Multidimensional Discrite Cosine Transform module
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
  use WORK.MDCT_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity MDCT is
  port (
    CLK           : in    std_logic;                             -- Input clock
    RST           : in    std_logic;                             -- Positive reset
    MDCTI         : in    std_logic_vector(IP_W - 1 downto 0);   -- MDCT data input
    IDV           : in    std_logic;                             -- Input data valid

    MDCTO         : out   std_logic_vector(COE_W - 1 downto 0);  -- MDCT data output
    ODV           : out   std_logic;                             -- Output data valid
    -- debug
    DCTO1         : out   std_logic_vector(OP_W - 1 downto 0);   -- DCT output of first stage
    ODV1          : out   std_logic                              -- Output data valid of first stage
  );
end entity MDCT;

----------------------------- ARCHITECTURE -------------------------------------

architecture RTL of MDCT is

  --########################### CONSTANTS 1 ####################################

  --########################### TYPES ##########################################

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################

  signal ram_dout_s              : std_logic_vector(RAMDATA_W - 1 downto 0);
  signal ram_raddr_s             : std_logic_vector(RAMADRR_W - 1 downto 0);
  signal ram_waddr_s             : std_logic_vector(RAMADRR_W - 1 downto 0);
  signal ram_din_s               : std_logic_vector(RAMDATA_W - 1 downto 0);
  signal ram_we_s                : std_logic;

  signal rome_dout_s             : t_rom1datao;
  signal romo_dout_s             : t_rom1datao;
  signal rome_addr_s             : t_rom1addro;
  signal romo_addr_s             : t_rom1addro;

  signal rome2_dout_s            : t_rom2datao;
  signal romo2_dout_s            : t_rom2datao;
  signal rome2_addr_s            : t_rom2addro;
  signal romo2_addr_s            : t_rom2addro;

  signal trigger2_s              : std_logic;
  signal trigger1_s              : std_logic;
  signal ram1_dout_s             : std_logic_vector(RAMDATA_W - 1 downto 0);
  signal ram2_dout_s             : std_logic_vector(RAMDATA_W - 1 downto 0);
  signal ram1_we_s               : std_logic;
  signal ram2_we_s               : std_logic;
  signal memswitchrd_s           : std_logic;
  signal memswitchwr_s           : std_logic;
  signal wmemsel_s               : std_logic;
  signal rmemsel_s               : std_logic;
  signal dataready_s             : std_logic;
  signal datareadyack_s          : std_logic;

  --########################### ARCHITECTURE BEGIN #############################

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  --                             ram_din_s
  --      +-------------------+  ram_waddr_s +------+  ram_raddr_s +-------------------+
  --      |      U_DCT1D      |-----------+->|U1_RAM|<-+-----------|      U_DCT2D      |
  --      |                   |            \ +------+ /            |                   |
  --      |                   | <--------+  >+------+<             |                   |
  --      |                   |          |   |U2_RAM|              |                   |
  --      +-------------------+ <-----+  |   +------+       +----> +-------------------+
  --                |                 |  |  ram1_dout_s     |                |
  --     rome_addr_s|romo_addr_s      |  |  ram2_dout_s     |    rome2_addr_s|romo2_addr_s
  --     rome_dout_s|romo_dout_s      |  |     |  |         |    rome2_dout_s|romo2_dout_s
  --                |                 |  |     v  v         |                |
  --                |                 |  |   --------       |                |
  --    +-----------v-----------+     |  |   \      /<-+    |    +-----------v-----------+
  --    | U1_ROME     U1_ROMO   |     |  |    ------   |    |    | U2_ROME     U2_ROMO   |
  --    |    +--+       +--+    |     |  +------+      |    |    |    +--+       +--+    |
  --    |    |+--+      |+--+   |     |                |    |    |    |+--+      |+--+   |
  --    |  \ +|+--+   \ +|+--+  |     +---------------------+    |  \ +|+--+   \ +|+--+  |
  --    |   \ +|+--+   \ +|+--+ |     |      U_DBUFCTL      |    |   \ +|+--+   \ +|+--+ |
  --    | 9x \ +|-+| 9x \ +|-+| |     |                     |    | 9x \ +|-+| 9x \ +|-+| |
  --    |     - +--+     - +--+ |     +---------------------+    |     - +--+     - +--+ |
  --    +-----------------------+                                +-----------------------+
  --
  --
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

begin

  --########################### ENTITY DEFINITION ##############################

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |1D DCT|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_DCT1D : entity work.dct1d
    port map (
      CLK       => CLK,
      RST       => RST,
      DCTI      => MDCTI,
      IDV       => IDV,
      ROME_DOUT => rome_dout_s,
      ROMO_DOUT => romo_dout_s,

      ODV       => ODV1,
      DCTO      => DCTO1,
      ROME_ADDR => rome_addr_s,
      ROMO_ADDR => romo_addr_s,
      RAM_WADDR => ram_waddr_s,
      RAM_DIN   => ram_din_s,
      RAM_WE    => ram_we_s,
      WMEMSEL   => wmemsel_s
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |1D DCT|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_DCT2D : entity work.dct2d
    port map (
      CLK       => CLK,
      RST       => RST,
      ROME_DOUT => rome2_dout_s,
      ROMO_DOUT => romo2_dout_s,
      RAMDATAO  => ram_dout_s,
      DATAREADY => dataready_s,

      ODV          => ODV,
      DCTO         => MDCTO,
      ROMEADDRO    => rome2_addr_s,
      ROMOADDRO    => romo2_addr_s,
      RAMRADDRO    => ram_raddr_s,
      RMEMSEL      => rmemsel_s,
      DATAREADYACK => datareadyack_s
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |RAM1|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U1_RAM : entity work.ram
    port map (
      D     => ram_din_s,
      WADDR => ram_waddr_s,
      RADDR => ram_raddr_s,
      WE    => ram1_we_s,
      CLK   => CLK,

      Q => ram1_dout_s
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |RAM2|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U2_RAM : entity work.ram
    port map (
      D     => ram_din_s,
      WADDR => ram_waddr_s,
      RADDR => ram_raddr_s,
      WE    => ram2_we_s,
      CLK   => CLK,

      Q => ram2_dout_s
    );

  -- double buffer switch
  ram1_we_s  <= ram_we_s when memswitchwr_s = '0' else
                '0';
  ram2_we_s  <= ram_we_s when memswitchwr_s = '1' else
                '0';
  ram_dout_s <= ram1_dout_s when memswitchrd_s = '0' else
                ram2_dout_s;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |DBUFCTL|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_DBUFCTL : entity work.dbufctl
    port map (
      CLK          => CLK,
      RST          => RST,
      WMEMSEL      => wmemsel_s,
      RMEMSEL      => rmemsel_s,
      DATAREADYACK => datareadyack_s,

      MEMSWITCHWR => memswitchwr_s,
      MEMSWITCHRD => memswitchrd_s,
      DATAREADY   => dataready_s
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
        ADDR => rome_addr_s(i),
        CLK  => CLK,

        DATAO => rome_dout_s(i)
      );

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- |ROMO|
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    U1_ROMO : entity work.romo
      port map (
        ADDR => romo_addr_s(i),
        CLK  => CLK,

        DATAO => romo_dout_s(i)
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
        ADDR => rome2_addr_s(i),
        CLK  => CLK,

        DOUT => rome2_dout_s(i)
      );

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- |ROMO|
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    U2_ROMO : entity work.romo
      port map (
        ADDR => romo2_addr_s(i),
        CLK  => CLK,

        DOUT => romo2_dout_s(i)
      );

  end generate G_ROM_ST2;

  --########################## PROCESSES #######################################

end architecture RTL;

----------------------------- ARCHITECTURE -------------------------------------
