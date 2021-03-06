--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
-- Create Date:     Mon Jul 19 15:17:41 CEST 2021
-- Design Name:     I_2DDCT_TB
-- Module Name:     I_2DDCT_TB.vhd - RTL
-- Project Name:    i-2DDCT
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
  use WORK.I_2DDCT_PKG.all;
  use WORK.I_2DDCTTB_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity I_2DDCT_TB is
  --port (
  --);
end entity I_2DDCT_TB;

----------------------------- ARCHITECTURE -------------------------------------

architecture RTL of I_2DDCT_TB is

  --########################### CONSTANTS 1 ####################################
  constant C_CLK_PERIOD_NS                             : time := 1e09 / C_CLK_FREQ_HZ * 1 ns;

  --########################### TYPES ##########################################

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################
  constant DCT1D_0                                     : i_matrix_type := COMPUTE_REF_DCT1D(input_data0, true);
  constant DCT2D_0                                     : i_matrix_type := COMPUTE_REF_DCT1D(DCT1D_0, false);
  constant DCT1D_1                                     : i_matrix_type := COMPUTE_REF_DCT1D(input_data1, true);
  constant DCT2D_1                                     : i_matrix_type := COMPUTE_REF_DCT1D(DCT1D_1, false);

  --########################### SIGNALS ########################################
  signal clk                                           : std_logic;
  signal rst                                           : std_logic;
  signal rst_s                                         : std_logic;

  signal nvm_busy                                      : std_logic;
  signal nvm_busy_s                                    : std_logic;
  signal nvm_en                                        : std_logic;
  signal nvm_we                                        : std_logic;
  signal nvm_raddr                                     : std_logic_vector(C_NVM_ADDR_W - 1 downto 0);
  signal nvm_waddr                                     : std_logic_vector(C_NVM_ADDR_W - 1 downto 0);
  signal nvm_din                                       : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal nvm_dout                                      : std_logic_vector(C_NVM_DATA_W - 1 downto 0);

  signal sys_enrg_status                               : sys_enrg_status_t;                                                                                                     -- System energy status
  signal first_run                                     : std_logic;

  signal varc_rdy                                      : std_logic;
  signal sys_status                                    : sys_status_t;                                                                                                          -- System status value of sys_status_t
  signal data_sync                                     : std_logic;

  signal i_dbufctl_start                               : std_logic;
  signal i_dbufctl_tx                                  : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal i_dbufctl_rx                                  : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal i_dbufctl_ready                               : std_logic;

  signal ram_pb_start                                  : std_logic;
  signal ram_pb_tx                                     : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal ram_pb_rx                                     : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal ram_pb_ready                                  : std_logic;

  signal ram_pb_ram1_din                               : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal ram_pb_ram2_din                               : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal ram_pb_ram_waddr                              : std_logic_vector(C_RAMADDR_W - 1 downto 0);
  signal ram_pb_ram_raddr                              : std_logic_vector(C_RAMADDR_W - 1 downto 0);
  signal ram_pb_ram_we                                 : std_logic;
  signal ram_pb_ram1_dout                              : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal ram_pb_ram2_dout                              : std_logic_vector(C_RAMDATA_W - 1 downto 0);

  signal dcti                                          : std_logic_vector(C_INDATA_W - 1 downto 0);                                                                             -- DCT input data
  signal idv                                           : std_logic;                                                                                                             -- Input data valid

  signal rome1_addr                                    : rom1_addr_t;                                                                                                           -- ROME address output
  signal romo1_addr                                    : rom1_addr_t;                                                                                                           -- ROMO address output
  signal rome1_dout                                    : rom1_data_t;                                                                                                           -- ROME data output
  signal romo1_dout                                    : rom1_data_t;                                                                                                           -- ROMO data output

  signal rome2_addr                                    : rom2_addr_t;                                                                                                           -- ROME address output
  signal romo2_addr                                    : rom2_addr_t;                                                                                                           -- ROMO address output
  signal rome2_dout                                    : rom2_data_t;                                                                                                           -- ROME data output
  signal romo2_dout                                    : rom2_data_t;                                                                                                           -- ROMO data output

  signal ram1_waddr, ram2_waddr                        : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM write address output
  signal ram1_raddr, ram2_raddr                        : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM read address
  signal ram1_din,   ram2_din                          : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data input
  signal ram1_dout,  ram2_dout                         : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data out
  signal ram1_we,    ram2_we                           : std_logic;                                                                                                             -- RAM write enable

  signal i_dct1s_block_cmplt                           : std_logic;                                                                                                             -- Write memory select signal
  signal i_dct2s_block_cmplt                           : std_logic;                                                                                                             -- Write memory select signal

  signal i_dct1s_waddr                                 : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM write address output
  signal i_dct1s_raddr                                 : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM read address
  signal i_dct1s_din                                   : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data input
  signal i_dct1s_dout                                  : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data out
  signal i_dct1s_we                                    : std_logic;                                                                                                             -- RAM write enable
  signal odv1                                          : std_logic;                                                                                                             -- Output data valid.
  signal dcto1                                         : std_logic_vector(C_1S_OUTDATA_W - 1 downto 0);                                                                         -- DCT data output.

  signal i_dct1s_varc_rdy                              : std_logic;

  signal odv                                           : std_logic;                                                                                                             -- Output data valid.
  signal dcto                                          : std_logic_vector(C_OUTDATA_W - 1 downto 0);                                                                            -- DCT data output.

  signal i_dct2s_waddr                                 : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM write address output
  signal i_dct2s_raddr                                 : std_logic_vector(C_RAMADDR_W - 1 downto 0);                                                                            -- RAM read address
  signal i_dct2s_din                                   : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data input
  signal i_dct2s_dout                                  : std_logic_vector(C_RAMDATA_W - 1 downto 0);                                                                            -- RAM data out
  signal i_dct2s_we                                    : std_logic;                                                                                                             -- RAM write enable

  signal i_dbufctl_data_ready                          : std_logic;
  signal i_dct2s_data_ready_ack                        : std_logic;
  signal i_dct2s_varc_rdy                              : std_logic;
  signal i_dbufctl_wmemsel                             : std_logic;
  signal i_dbufctl_rmemsel                             : std_logic;

  signal process_cnt                                   : natural;
  signal input_row_cnt                                 : natural;

  signal dct1d_cnt                                     : natural;
  signal dct2d_cnt                                     : natural;
  signal dct1d_data                                    : i_array_t (0 to 2 * (N * N) + 2);
  signal dct2d_data                                    : i_array_t (0 to 2 * (N * N) + 2);
  signal sys_status_d : sys_status_t;

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
  U_NV_MEM : entity work.nv_mem

    generic map (
      CLK_FREQ_HZ    => C_CLK_FREQ_HZ,
      ACCESS_TIME_NS => C_NV_MEM_ACCESS_TIME_NS,
      ADDR_W         => C_NVM_ADDR_W,
      DATA_W         => C_NVM_DATA_W
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
  -- |I_2DDCT_CTRL|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_I_2DDCT_CTRL : entity work.i_2ddct_ctrl
    port map (
      CLK => clk,
      RST => rst,
      --------------------------------------------------------------------------
      NVM_BUSY     => nvm_busy,
      NVM_BUSY_SIG => nvm_busy_s,
      NVM_EN       => nvm_en,
      NVM_WE       => nvm_we,
      NVM_RADDR    => nvm_raddr,
      NVM_WADDR    => nvm_waddr,
      NVM_DIN      => nvm_din,
      NVM_DOUT     => nvm_dout,
      --------------------------------------------------------------------------
      SYS_ENRG_STATUS => sys_enrg_status,
      FIRST_RUN       => first_run,

      VARC_RDY   => varc_rdy,
      SYS_STATUS => sys_status,
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

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |RAM_MUX|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  U_RAM_MUX : entity work.ram_mux
    port map (
      -- MUX control ports
      SYS_STATUS         => sys_status_d, --NOTE delayed version
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
  -- |IDCT1S|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_I_DCT1S : entity work.i_dct1s
    port map (
      CLK => clk,
      RST => rst,
      ----------------------------------------------------------
      DCTI => dcti,
      IDV  => idv,
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
      ODV  => odv1,
      DCTO => dcto1,
      -- Intermittent Enhancment Ports -------------------------
      SYS_STATUS => sys_status,
      VARC_RDY   => i_dct1s_varc_rdy
      ----------------------------------------------------------
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |IDCT2S|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_I_DCT2S : entity work.i_dct2s
    port map (
      CLK => clk,
      RST => rst,
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
      ODV  => odv,
      DCTO => dcto,
      ----------------------------------------------------------
      BLOCK_CMPLT    => i_dct2s_block_cmplt,
      DATA_READY     => i_dbufctl_data_ready,
      DATA_READY_ACK => i_dct2s_data_ready_ack,
      -- Intermittent Enhancment Ports -------------------------
      SYS_STATUS     => sys_status,
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
  -- |FIRST stage ROMs|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  G_ROM_ST1 : for i in 0 to 8 generate

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- |ROME|
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    U1_ROME : entity work.rome
      port map (
        ADDR => rome1_addr(i),
        CLK  => clk,

        DOUT => rome1_dout(i)
      );

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- |ROMO|
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    U1_ROMO : entity work.romo
      port map (
        ADDR => romo1_addr(i),
        CLK  => clk,

        DOUT => romo1_dout(i)
      );

  end generate G_ROM_ST1;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |SECOND stage ROMs|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  G_ROM_ST2 : for i in 0 to 10 generate

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- |ROME|
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    U2_ROME : entity work.rome
      port map (
        ADDR => rome2_addr(i),
        CLK  => clk,

        DOUT => rome2_dout(i)
      );

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- |ROMO|
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    U2_ROMO : entity work.romo
      port map (
        ADDR => romo2_addr(i),
        CLK  => clk,

        DOUT => romo2_dout(i)
      );

  end generate G_ROM_ST2;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |RAMP_PB|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  U_RAM_PB : entity work.ram_pb
    port map (
      CLK        => clk,
      RST        => rst,
      START      => ram_pb_start,
      READY      => ram_pb_ready,
      SYS_STATUS => sys_status,
      DATA_SYNC  => data_sync,
      RX         => ram_pb_rx,
      TX         => ram_pb_tx,
      RAM1_DIN   => ram_pb_ram1_din,
      RAM2_DIN   => ram_pb_ram2_din,
      RAM_WADDR  => ram_pb_ram_waddr,
      RAM_RADDR  => ram_pb_ram_raddr,
      RAM_WE     => ram_pb_ram_we,
      RAM1_DOUT  => ram_pb_ram1_dout,
      RAM2_DOUT  => ram_pb_ram2_dout
    );

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

      SYS_STATUS => sys_status,
      DATA_SYNC  => data_sync,
      PB_READY   => i_dbufctl_ready,
      RX         => i_dbufctl_rx,
      TX         => i_dbufctl_tx,
      PB_START   => i_dbufctl_start
    );

  --########################## OUTPUT PORTS WIRING #############################

  --########################## COBINATORIAL FUNCTIONS ##########################
  varc_rdy <= i_dct1s_varc_rdy AND i_dct2s_varc_rdy;

  --########################## PROCESSES #######################################
  P_DELAY : process (clk, rst) is 
  begin
    if(rst = '1') then
    elsif(rising_edge(clk))then
      sys_status_d <= sys_status;
    end if;
  end process;

  P_DCT_DATA_GEN : process (clk, rst_s) is
    variable already_computed : boolean ;
  begin

    if (rst_s = '1') then
      dcti          <= (others => '0');
      idv           <= '0';
      process_cnt   <= 0;
      input_row_cnt <= 0;
    elsif (clk'event AND clk = '1') then
      idv  <= '0';
      dcti <= (others => '0');

      if (sys_status = SYS_RUN) then
        already_computed := false;
        idv <= '1';
        if (process_cnt < input_data01'length) then
          dcti        <= std_logic_vector(to_unsigned(input_data01(process_cnt), dcti'length));
          process_cnt <= process_cnt + 1;
          if (process_cnt mod N = 0) then
            input_row_cnt <= input_row_cnt + 1;
          end if;
        elsif (process_cnt = input_data01'length) then
          idv <= '0';
        end if;
      else
        if(rst = '1' and already_computed = false) then
          if (process_cnt mod N /= 0) then
          --if (process_cnt mod N /= N-1) then
            process_cnt <= ((process_cnt / N) * N - 1) + 1;
          else
            process_cnt <= process_cnt + 1;
          end if;
          already_computed := true;
        end if;
      end if;
    end if;

  end process P_DCT_DATA_GEN;

  P_DCT_DATA_READ : process (clk, rst_s) is
  begin

    if (rst_s = '1') then
      dct1d_data <= (others => - 1);
      dct2d_data <= (others => - 1);
      dct1d_cnt  <= 0;
      dct2d_cnt  <= 0;
    elsif (clk'event and clk = '1') then
      if (odv1 = '1') then
        dct1d_data(dct1d_cnt) <= to_integer(signed(dcto1));
        dct1d_cnt             <= dct1d_cnt + 1;
      end if;

      if (odv = '1') then
        dct2d_data(dct2d_cnt) <= to_integer(signed(dcto));
        dct2d_cnt             <= dct2d_cnt + 1;
      end if;
    end if;

  end process P_DCT_DATA_READ;

  P_GLOBAL_SIG : process is
  begin

    rst             <= '1';
    rst_s           <= '1';
    wait for 20 * C_CLK_PERIOD_NS;
    sys_enrg_status <= sys_enrg_ok;
    first_run       <= '1';
    rst             <= '0';
    rst_s           <= '0';
    --wait for 100 * C_CLK_PERIOD_NS;
    wait for 108 * C_CLK_PERIOD_NS;
    first_run       <= '0';
    rst             <= '0';
    sys_enrg_status <= sys_enrg_hazard;
    wait for 450  * C_CLK_PERIOD_NS;
    rst             <= '1';
    wait for 2 * C_CLK_PERIOD_NS;
    rst             <= '0';
    sys_enrg_status <= sys_enrg_ok;

    --   rst             <= '0';
    --   sys_enrg_status <= sys_enrg_ok;
    --   first_run       <= '1';
    --   wait for 10 * C_CLK_PERIOD_NS;
    --   rst             <= '1';
    --   wait for C_CLK_PERIOD_NS;
    --   rst             <= '0';
    --   wait for 101 * C_CLK_PERIOD_NS;
    --   first_run       <= '0';
    --   sys_enrg_status <= sys_enrg_hazard;
    --   -- ~31 clks for varc push to ram
    --   -- ~372 clks for V2NV push
    --   wait for 450 * C_CLK_PERIOD_NS;
    --   rst             <= '1';
    --   sys_enrg_status <= sys_enrg_ok;
    --   wait for C_CLK_PERIOD_NS;
    --   rst             <= '0';
    --   --sys_enrg_status <= sys_enrg_ok;
    wait;
    --rst             <= '0';
    --sys_enrg_status <= sys_enrg_ok;
    --first_run       <= '1';
    --wait for 10 * C_CLK_PERIOD_NS;
    --rst             <= '1';
    --wait for C_CLK_PERIOD_NS;
    --rst             <= '0';
    --wait for 10* C_CLK_PERIOD_NS;
    --first_run       <= '0';
    --wait for 250* C_CLK_PERIOD_NS;
    --sys_enrg_status <= sys_enrg_hazard;
    ---- ~31 clks for varc push to ram
    ---- ~372 clks for V2NV push
    --wait for 450 * C_CLK_PERIOD_NS;
    --rst             <= '1';
    --sys_enrg_status <= sys_enrg_ok;
    --wait for C_CLK_PERIOD_NS;
    --rst             <= '0';
    --sys_enrg_status <= sys_enrg_ok;
    wait;

  end process P_GLOBAL_SIG;

end architecture RTL;

--------------------------------------------------------------------------------
