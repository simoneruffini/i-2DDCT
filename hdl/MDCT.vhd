--------------------------------------------------------------------------------
-- Engineer:  Michal Krepa
--            Simone Ruffini [simone.ruffini@tutanota.com]
--
-- Create Date:     Sat Feb 25 16:12 2006
-- Design Name:     MDCT
-- Module Name:     MDCT.vhd - RTL
-- Project Name:    MDCT
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
    MDCTI         : in    std_logic_vector(IP_W - 1 downto 0); -- MDCT data input
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

  signal ramdatao_s            : std_logic_vector(RAMDATA_W - 1 downto 0);
  signal ramraddro_s           : std_logic_vector(RAMADRR_W - 1 downto 0);
  signal ramwaddro_s           : std_logic_vector(RAMADRR_W - 1 downto 0);
  signal ramdatai_s            : std_logic_vector(RAMDATA_W - 1 downto 0);
  signal ramwe_s               : std_logic;

  signal romedatao_s           : t_rom1datao;
  signal romodatao_s           : t_rom1datao;
  signal romeaddro_s           : t_rom1addro;
  signal romoaddro_s           : t_rom1addro;

  signal rome2datao_s          : t_rom2datao;
  signal romo2datao_s          : t_rom2datao;
  signal rome2addro_s          : t_rom2addro;
  signal romo2addro_s          : t_rom2addro;

  signal trigger2_s            : std_logic;
  signal trigger1_s            : std_logic;
  signal ramdatao1_s           : std_logic_vector(RAMDATA_W - 1 downto 0);
  signal ramdatao2_s           : std_logic_vector(RAMDATA_W - 1 downto 0);
  signal ramwe1_s              : std_logic;
  signal ramwe2_s              : std_logic;
  signal memswitchrd_s         : std_logic;
  signal memswitchwr_s         : std_logic;
  signal wmemsel_s             : std_logic;
  signal rmemsel_s             : std_logic;
  signal dataready_s           : std_logic;
  signal datareadyack_s        : std_logic;

  --########################### ARCHITECTURE BEGIN #############################

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  --                             ramdatai_s
  --      +-------------------+  ramwaddro_s +------+  ramraddro_s +-------------------+
  --      |      U_DCT1D      |-----------+->|U1_RAM|<-+-----------|      U_DCT2D      |
  --      |                   |            \ +------+ /            |                   |
  --      |                   | <--------+  >+------+<             |                   |
  --      |                   |          |   |U2_RAM|              |                   |
  --      +-------------------+ <-----+  |   +------+       +----> +-------------------+
  --                |                 |  |  ramdatao1_s     |                |
  --     romeaddro_s|romoaddro_s      |  |  ramdatao2_s     |    rome2addro_s|romo2addro_s
  --     romedatao_s|romodatao_s      |  |     |  |         |    rome2datao_s|romo2datao_s
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
      ROMEDATAO => romedatao_s,
      ROMODATAO => romodatao_s,

      ODV       => ODV1,
      DCTO      => DCTO1,
      ROMEADDRO => romeaddro_s,
      ROMOADDRO => romoaddro_s,
      RAMWADDRO => ramwaddro_s,
      RAMDATAI  => ramdatai_s,
      RAMWE     => ramwe_s,
      WMEMSEL   => wmemsel_s
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |1D DCT|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_DCT2D : entity work.dct2d
    port map (
      CLK       => CLK,
      RST       => RST,
      ROMEDATAO => rome2datao_s,
      ROMODATAO => romo2datao_s,
      RAMDATAO  => ramdatao_s,
      DATAREADY => dataready_s,

      ODV          => ODV,
      DCTO         => MDCTO,
      ROMEADDRO    => rome2addro_s,
      ROMOADDRO    => romo2addro_s,
      RAMRADDRO    => ramraddro_s,
      RMEMSEL      => rmemsel_s,
      DATAREADYACK => datareadyack_s
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |RAM1|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U1_RAM : entity work.ram
    port map (
      D     => ramdatai_s,
      WADDR => ramwaddro_s,
      RADDR => ramraddro_s,
      WE    => ramwe1_s,
      CLK   => CLK,

      Q => ramdatao1_s
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |RAM2|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U2_RAM : entity work.ram
    port map (
      D     => ramdatai_s,
      WADDR => ramwaddro_s,
      RADDR => ramraddro_s,
      WE    => ramwe2_s,
      CLK   => CLK,

      Q => ramdatao2_s
    );

  -- double buffer switch
  ramwe1_s   <= ramwe_s when memswitchwr_s = '0' else
                '0';
  ramwe2_s   <= ramwe_s when memswitchwr_s = '1' else
                '0';
  ramdatao_s <= ramdatao1_s when memswitchrd_s = '0' else
                ramdatao2_s;

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
        ADDR => romeaddro_s(i),
        CLK  => CLK,

        DATAO => romedatao_s(i)
      );

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- |ROMO|
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    U1_ROMO : entity work.romo
      port map (
        ADDR => romoaddro_s(i),
        CLK  => CLK,

        DATAO => romodatao_s(i)
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
        ADDR => rome2addro_s(i),
        CLK  => CLK,

        DATAO => rome2datao_s(i)
      );

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- |ROMO|
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    U2_ROMO : entity work.romo
      port map (
        ADDR => romo2addro_s(i),
        CLK  => CLK,

        DATAO => romo2datao_s(i)
      );

  end generate G_ROM_ST2;

  --########################## PROCESSES #######################################

end architecture RTL;

----------------------------- ARCHITECTURE -------------------------------------
