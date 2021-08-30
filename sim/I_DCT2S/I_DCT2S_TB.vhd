--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
-- Create Date:     Mon Jun 07 18:38 2021
-- Design Name:     I_DCT2S_TB
-- Module Name:     I_DCT2S_TB.vhd - RTL
-- Project Name:    i-2DDCT
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
  use IEEE.STD_LOGIC_TEXTIO.all; --synopsis

library STD;
  use STD.TEXTIO.all;

-- User libraries

library WORK;
  use WORK.I_2DDCT_PKG.all;
  --use WORK.I_2DDCTTB_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity I_DCT2S_TB is
  --port (
  --);
end entity I_DCT2S_TB;

----------------------------- ARCHITECTURE -------------------------------------

architecture RTL of I_DCT2S_TB is

  --########################### CONSTANTS 1 ####################################
  constant C_CLK_FREQ_HZ    : natural := 1000000;                            -- 1MHz
  constant C_CLK_PERIOD_NS  : time := 1e09 / C_CLK_FREQ_HZ * 1 ns;

  --########################### TYPES ##########################################

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################
  signal clk                : std_logic;
  signal rst                : std_logic;
  signal odv                : std_logic;                                     -- Output data valid.
  signal dcto               : std_logic_vector(C_OUTDATA_W - 1 downto 0);    -- DCT data output.
  signal rome_addr          : rom2_addr_t;                                   -- ROME address output
  signal romo_addr          : rom2_addr_t;                                   -- ROMO address output
  signal rome_dout          : rom2_data_t;                                   -- ROME data output
  signal romo_dout          : rom2_data_t;                                   -- ROMO data output
  signal ram_waddr          : std_logic_vector(C_RAMADDR_W - 1 downto 0);    -- RAM write address output
  signal ram_din            : std_logic_vector(C_RAMDATA_W - 1 downto 0);    -- RAM data input
  signal ram_we             : std_logic;                                     -- RAM write enable
  signal wmemsel            : std_logic;                                     -- Write memory select signal
  signal rmemsel            : std_logic;                                     -- Write memory select signal

  signal dataready          : std_logic;
  signal datareadyack       : std_logic;
  signal new_block          : std_logic;

  signal ram_raddr          : std_logic_vector(C_RAMADDR_W - 1 downto 0);
  signal ram_dout           : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal process_cnt        : natural;

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
  -- |I_DCT2S|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |I_DCT2S|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_IDCT2S : entity work.i_dct2s
    port map (
      CLK => clk,
      RST => rst,
      ----------------------------------------------------------
      RAM_RADDR    => ram_raddr,
      RAM_DOUT     => ram_dout,
      DATAREADY    => dataready,
      DATAREADYACK => datareadyack,
      ----------------------------------------------------------
      ROME_ADDR => rome_addr,
      ROMO_ADDR => romo_addr,
      ROME_DOUT => rome_dout,
      ROMO_DOUT => romo_dout,
      ----------------------------------------------------------
      ODV     => odv,
      DCTO    => dcto,
      RMEMSEL => rmemsel,
      ----------------------------------------------------------
      SYS_STATUS => sys_status,
      NEW_BLOCK => new_block
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |RAM2|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U1_RAM : entity work.ram
    generic map (
      DATA_W => C_RAMDATA_W,
      ADDR_W => C_RAMADDR_W
    )
    port map (
      DIN   => ram_din,
      WADDR => ram_waddr,
      RADDR => ram_raddr,
      WE    => ram_we,
      CLK   => clk,

      DOUT  => ram_dout
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |First stage ROMs|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  G_ROM_ST1 : for i in 0 to 10 generate

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

        DOUT => romo_dout(i)
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

  P_NEW_BLOCK : process (clk, rst) is

  begin

    if (rst = '1') then
      process_cnt <= 0;
    elsif (clk'event AND clk = '1') then
      new_block <= '0';
      if (process_cnt =10) then
        new_block <= '1';
      end if;

      process_cnt <= process_cnt + 1;
    end if;

  end process P_NEW_BLOCK;

end architecture RTL;

--------------------------------------------------------------------------------
