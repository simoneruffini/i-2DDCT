--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
-- Create Date:     Mon Jul 19 15:17:41 CEST 2021
-- Design Name:     I_MDCT_TB
-- Module Name:     I_MDCT_TB.vhd - RTL
-- Project Name:    iMDCT
-- Description:     Intermittent Multidimensional Discrete Cosine Transform test bench
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
  use WORK.I_MDCT_PKG.all;
  --use WORK.NORM_PKG.all;
  -- use WORK.MDCTTB_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity I_MDCT_TB is
  --port (
  --);
end entity I_MDCT_TB;

----------------------------- ARCHITECTURE -------------------------------------

architecture RTL of I_MDCT_TB is

  --########################### CONSTANTS 1 ####################################
  constant C_CLK_FREQ_HZ            : natural := 1000000;                                                                                                    -- 1MHz
  constant C_CLK_PERIOD_NS          : time := 1e09 / C_CLK_FREQ_HZ * 1 ns;

  --########################### TYPES ##########################################

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################
  signal clk                        : std_logic;
  signal rst                        : std_logic;

  signal nvm_busy                   : std_logic;
  signal nvm_busy_s                 : std_logic;
  signal nvm_en                     : std_logic;
  signal nvm_we                     : std_logic;
  signal nvm_raddr                  : std_logic_vector(NVM_ADDR_W - 1 downto 0);
  signal nvm_waddr                  : std_logic_vector(NVM_ADDR_W - 1 downto 0);
  signal nvm_din                    : std_logic_vector(NVM_DATA_W - 1 downto 0);
  signal nvm_dout                   : std_logic_vector(NVM_DATA_W - 1 downto 0);

  signal sys_enrg_status            : sys_enrg_status_t;                                                                                                     -- System energy status

  signal varc_rdy                   : std_logic;
  signal sys_status                 : sys_status_t;                                                                                                          -- System status value of sys_status_t
  signal mdct_sync                  : std_logic;

  signal dbufctl_start              : std_logic;
  signal dbufctl_tx                 : std_logic_vector(NVM_DATA_W - 1 downto 0);
  signal dbufctl_rx                 : std_logic_vector(NVM_DATA_W - 1 downto 0);

  signal ram1_pb_start              : std_logic;
  signal ram1_pb_tx                 : std_logic_vector(NVM_DATA_W - 1 downto 0);
  signal ram1_pb_rx                 : std_logic_vector(NVM_DATA_W - 1 downto 0);

  signal ram2_pb_start              : std_logic;
  signal ram2_pb_tx                 : std_logic_vector(NVM_DATA_W - 1 downto 0);
  signal ram2_pb_rx                 : std_logic_vector(NVM_DATA_W - 1 downto 0);

  signal dcti                       : std_logic_vector(C_INDATA_W - 1 downto 0);                                                                             -- DCT input data
  signal idv                        : std_logic;                                                                                                             -- Input data valid

  signal rome_addr                  : rom1_addr_t;                                                                                                           -- ROME address output
  signal romo_addr                  : rom1_addr_t;                                                                                                           -- ROMO address output
  signal rome_dout                  : rom1_data_t;                                                                                                           -- ROME data output
  signal romo_dout                  : rom1_data_t;                                                                                                           -- ROMO data output

  signal ram1_waddr, ram2_waddr     : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM write address output
  signal ram1_raddr, ram2_raddr     : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM read address
  signal ram1_din,   ram2_din       : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data input
  signal ram1_dout,  ram2_dout      : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data out
  signal ram1_we,    ram2_we        : std_logic;                                                                                                             -- RAM write enable

  signal fram_cmplt                 : std_logic;                                                                                                             -- Write memory select signal

  signal i_dct1s_waddr              : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM write address output
  signal i_dct1s_raddr              : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM read address
  signal i_dct1s_din                : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data input
  signal i_dct1s_dout               : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data out
  signal i_dct1s_we                 : std_logic;                                                                                                             -- RAM write enable
  signal odv                        : std_logic;                                                                                                             -- Output data valid.
  signal dcto                       : std_logic_vector(C_1D_OUTDATA_W - 1 downto 0);                                                                         -- DCT data output.

  signal i_dct1s_varc_rdy           : std_logic;
  signal i_dct2d_varc_rdy           : std_logic;

  signal process_cnt                : natural;

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
  -- |NVM|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_NVM : entity work.nv_mem

    generic map (
      ADDR_W => C_NVM_ADDR_W,
      DATA_W => C_NVM_DATA_W
    )
    port map (
      CLK      => clk,
      RST      => rst,
      BUSY     => nvm_busy,
      BUSY_SIG => nvm_busy_s,
      -------------chage from here--------------
      EN    => nvm_en,
      WE    => nvm_we,
      RADDR => nvm_raddr,
      WADDR => nvm_waddr,
      DIN   => nvm_din,
      DOUT  => nvm_dout
      -------------chage to here----------------
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

      VARC_RDY   => varc_rdy,
      SYS_STATUS => sys_status,
      SYNC       => nvm_ctrl_sync,

      DBUFCTL_START => dbufctl_start,
      DBUFCTL_TX    => dbufctl_tx,
      DBUFCTL_RX    => (others => '0'),

      RAM1_PB_START => ram1_pb_start,
      RAM1_PB_TX    => ram1_pb_tx,
      RAM1_PB_RX    => ram1_pb_rx,

      RAM2_PB_START => ram2_pb_start,
      RAM2_PB_TX    => ram2_pb_tx,
      RAM2_PB_RX    => ram2_pb_rx
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |RAM_MUX|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  U_RAM_MUX : entity work.ram_mux
    port map (
      -- MUX control ports
      SYS_STATUS       => sys_status,
      I_DCT1S_VARC_RDY => i_dct1s_varc_rdy,
      I_DCT2S_VARC_RDY => '0',
      DBUFCTL_MEMSEL   => '0',
      RAM1_PB_EN       => open,
      RAM2_PB_EN       => open,
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
      I_DCT2S_DIN   => open,
      I_DCT2S_WADDR => open,
      I_DCT2S_RADDR => open,
      I_DCT2S_WE    => open,
      I_DCT2S_DOUT  => open,
      -- RAM_PB RAM ports
      RAM_PB_WADDR => open,
      RAM_PB_RADDR => open,
      RAM_PB_WE    => open,
      -- NVM_CTRL RAM ports
      NVM_CTRL_RAM1_TX => ram1_pb_tx,
      NVM_CTRL_RAM1_RX => ram1_pb_rx,
      NVM_CTRL_RAM2_TX => ram2_pb_tx,
      NVM_CTRL_RAM2_RX => ram2_pb_rx
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |IDCT1S|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_I_DCT1S : entity work.i_dct1s
    port map (
      CLK  => clk,
      RST  => rst,
      DCTI => dcti,
      IDV  => idv,
      ----------------------------------------------------------
      ROME_ADDR => rome_addr,
      ROMO_ADDR => romo_addr,
      ROME_DOUT => rome_dout,
      ROMO_DOUT => romo_dout,
      ----------------------------------------------------------
      RAM_WADDR   => i_dct1s_waddr,
      RAM_RADDR   => i_dct1s_raddr,
      RAM_DIN     => i_dct1s_din,
      RAM_DOUT    => i_dct1s_dout,
      RAM_WE      => i_dct1s_we,
      FRAME_CMPLT => fram_cmplt,
      -- debug -------------------------------------------------
      ODV  => odv,
      DCTO => dcto,
      -- Intermittent Enhancment Ports -------------------------
      SYS_STATUS => sys_status,
      VARC_RDY   => i_dct1s_varc_rdy
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
      CLK => clk,

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
      CLK => clk,

      DIN   => ram2_din,
      WADDR => ram2_waddr,
      RADDR => ram2_raddr,
      WE    => ram2_we,
      DOUT  => ram2_dout
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |FiRST stage ROMs|
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

  --########################## OUTPUT PORTS WIRING #############################

  --########################## COBINATORIAL FUNCTIONS ##########################
  varc_rdy <= i_dct1s_varc_rdy; -- AND i_dct2d_varc_redy AND ram1_varc_rdy AND ram2_varc_rdy AND dbufctl_varc_rdy;

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

  begin

    if (rst = '1') then
      dcti        <= (others => '0');
      idv         <= '0';
      process_cnt <= 0;
    elsif (clk'event AND clk = '1') then
      idv  <= '0';
      dcti <= (others => '0');
      if (sys_status = SYS_RUN) then
        idv         <= '1';
        dcti        <= std_logic_vector(to_unsigned(process_cnt, dcti'length));
        process_cnt <= process_cnt + 1;
      end if;
    end if;

  end process P_DCT_DATA_GEN;

  P_NVM_DOUT : process is
  begin

    nvm_dout <= (others => '1');
    wait for 22 * C_CLK_PERIOD_NS;
    nvm_dout <= (others => '0');
    wait;

  end process P_NVM_DOUT;

  P_SYS_ENRG_STAT_GEN : process is
  begin

    sys_enrg_status <= sys_enrg_hazard;
    wait for 20 * C_CLK_PERIOD_NS;
    sys_enrg_status <= sys_enrg_ok;
    wait for 300 * C_CLK_PERIOD_NS;
    sys_enrg_status <= sys_enrg_wrng;
    wait for 200 * C_CLK_PERIOD_NS;
    sys_enrg_status <= sys_enrg_ok;
    wait;

  end process P_SYS_ENRG_STAT_GEN;

end architecture RTL;

--------------------------------------------------------------------------------
