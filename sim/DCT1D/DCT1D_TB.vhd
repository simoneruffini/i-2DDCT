--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
-- Create Date:     Mon Jun 07 18:38 2021
-- Design Name:     DCT1D_TB
-- Module Name:     DCT1D_TB.vhd - RTL
-- Project Name:    iMDCT
-- Description:     1D Discrete Cosine Transform (1st stage) test bench
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
  use IEEE.NUMERIC_STD.all;

-- User libraries

library WORK;
  use WORK.MDCT_PKG.all;
  use WORK.MDCTTB_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity DCT1D_TB is
  --port (
  --);
end entity DCT1D_TB;

----------------------------- ARCHITECTURE -------------------------------------

architecture RTL of DCT1D_TB is

  --########################### CONSTANTS 1 ####################################
  constant C_CLK_FREQ_HZ   : natural := 1000000;                      -- 1MHz
  constant C_CLK_PERIOD_NS : time := 1e09 / C_CLK_FREQ_HZ * 1 ns;

  --########################### TYPES ##########################################

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################
  signal clk               : std_logic;
  signal rst               : std_logic;

  signal dcti              : std_logic_vector(IP_W - 1 downto 0);       -- DCT input data
  signal idv               : std_logic;                                 -- Input data valid
  signal rome_dout         : t_rom1datao;                               -- ROME data output
  signal romo_dout         : t_rom1datao;                               -- ROMO data output

  signal odv               : std_logic;                                 -- Output data valid.
  signal dcto              : std_logic_vector(OP_W - 1 downto 0);       -- DCT data output.
  signal rome_addr         : t_rom1addro;                               -- ROME address output
  signal romo_addr         : t_rom1addro;                               -- ROMO address output
  signal ram_waddr         : std_logic_vector(RAMADRR_W - 1 downto 0);  -- RAM write address output
  signal ram_din           : std_logic_vector(RAMDATA_W - 1 downto 0);  -- RAM data input
  signal ram_we            : std_logic;                                 -- RAM write enable
  signal wmemsel           : std_logic;                                 -- Write memory select signal

  signal ram_raddr         : std_logic_vector(RAMADRR_W - 1 downto 0);
  signal ram_dout          : std_logic_vector(RAMDATA_W - 1 downto 0);

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
  -- |DBUFCTL|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_DCT1D : entity work.dct1d
    port map (
      CLK       => clk,
      RST       => rst,
      DCTI      => dcti,
      IDV       => idv,
      ROME_DOUT => rome_dout,
      ROMO_DOUT => romo_dout,
      -- debug -------------------------------------------------
      ODV  => odv,
      DCTO => dcto,
      ----------------------------------------------------------
      ROME_ADDR => rome_addr,
      ROMO_ADDR => romo_addr,
      RAM_WADDR => ram_waddr,
      RAM_DIN   => ram_din,
      RAM_WE    => ram_we,
      WMEMSEL   => wmemsel
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |RAM1|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U1_RAM : entity work.ram
    port map (
      D     => ram_din,
      WADDR => ram_waddr,
      RADDR => ram_raddr,
      WE    => ram_we,
      CLK   => clk,

      Q => ram_dout
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
        ADDR => rome_addr(i),
        CLK  => clk,

        DOUT => rome_dout(i)
      );

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- |ROMO|
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    U1_ROMO : entity work.romo
      port map (
        ADDR => romo_addr(i),
        CLK  => clk,

        DATAO => romo_dout(i)
      );

  end generate G_ROM_ST1;

  --########################## PROCESSES #######################################
  P_RESET_GEN : process is
  begin

    rst <= '0';
    wait for 10 * C_CLK_PERIOD_NS;
    rst <= '1';
    wait for C_CLK_PERIOD_NS;
    rst <= '0';
    wait;

  end process P_RESET_GEN;

  P_DCT_DATA_GEN : process (clk, rst) is
    variable process_cnt : natural ;
  begin

    if (rst = '1') then
      dcti <= (others => '0');
      idv  <= '0';
      process_cnt := 0;
    elsif (clk'event AND clk = '1') then
      idv  <= '0';
      dcti <= (others => '0');
      if  (process_cnt >=10) then
        idv <= '1';
        dcti <= std_logic_vector(to_unsigned(process_cnt,dcti'length));
      end if;

      process_cnt := process_cnt + 1;
    end if;

  end process P_DCT_DATA_GEN;

end architecture RTL;

--------------------------------------------------------------------------------
