--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
-- Create Date:     Fri Aug 20 20:57:09 CEST 2021
-- Design Name:     TOP_LEVEL_TB
-- Module Name:     TOP_LEVEL_TB.vhd - Behavioral
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
  use IEEE.NUMERIC_STD.all;

-- User libraries

library WORK;
  use WORK.I_2DDCT_PKG.all;
  use WORK.I_2DDCTTB_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity TOP_LEVEL_TB is
  --port (
  --);
end entity TOP_LEVEL_TB;

----------------------------- ARCHITECTURE -------------------------------------

architecture BEHAVIORAL of TOP_LEVEL_TB is

  --########################### CONSTANTS 1 ####################################
  constant C_CLK_PERIOD_NS                             : time := 1e09 / C_CLK_FREQ_HZ * 1 ns;

  --########################### TYPES ##########################################

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################

  signal clk                                           : std_logic;
  --signal clk_s                         : std_logic;
  --signal gate_clk_s                    : std_logic;

  signal rst                                           : std_logic;
  signal rst_emu                                       : std_logic;
  --signal rst_s                         : std_logic;

  signal din                                           : std_logic_vector(C_INDATA_W - 1 downto 0);
  signal idv                                           : std_logic;
  signal dout                                          : std_logic_vector(C_OUTDATA_W - 1 downto 0);
  signal odv                                           : std_logic;

  signal odv1                                          : std_logic;
  signal dcto1                                         : std_logic_vector(C_1S_OUTDATA_W - 1 downto 0);

  signal nvm_busy                                      : std_logic;
  signal nvm_busy_s                                    : std_logic;
  signal nvm_en                                        : std_logic;
  signal nvm_we                                        : std_logic;
  signal nvm_raddr                                     : std_logic_vector(C_NVM_ADDR_W - 1 downto 0);
  signal nvm_waddr                                     : std_logic_vector(C_NVM_ADDR_W - 1 downto 0);
  signal nvm_din                                       : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal nvm_dout                                      : std_logic_vector(C_NVM_DATA_W - 1 downto 0);

  signal sys_status                                    : sys_status_t;                                                                                                          -- System status value of sys_status_t
  signal sys_enrg_status                               : sys_enrg_status_t;                                                                                                     -- System energy status
  signal first_run                                     : std_logic;

  --signal testend                       : boolean;

  signal process_cnt                                   : natural;
  signal input_row_cnt                                 : natural;

  signal dct1d_cnt                                     : natural;
  signal dct2d_cnt                                     : natural;
  signal dct1d_data                                    : i_array_t (0 to 2 * (N * N) - 1);
  signal dct2d_data                                    : i_array_t (0 to 2 * (N * N) - 1);

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
      CLK => clk,
      RST => rst_emu,
      --------------------------------------------------------------------------
      DIN  => din,
      IDV  => idv,
      DOUT => dout,
      ODV  => odv,
      --------------------------------------------------------------------------
      -- Intermitent enhancement ports
      NVM_BUSY     => nvm_busy,
      NVM_BUSY_SIG => nvm_busy_s,
      NVM_EN       => nvm_en,
      NVM_WE       => nvm_we,
      NVM_RADDR    => nvm_raddr,
      NVM_WADDR    => nvm_waddr,
      NVM_DIN      => nvm_din,
      NVM_DOUT     => nvm_dout,

      SYS_STATUS      => sys_status,
      SYS_ENRG_STATUS => sys_enrg_status,
      FIRST_RUN       => first_run,
      --------------------------------------------------------------------------
      -- debug
      DCTO1 => dcto1,
      ODV1  => odv1
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

  -- --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- -- |INP_IMG_GEN|
  -- --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- U_INPIMAGE : entity work.inp_img_gen
  --   port map (
  --     CLK        => clk_s,
  --     RST_EMU    => rst_emu,
  --     ODV1       => odv1,
  --     DCTO1      => dcto1,
  --     ODV        => odv,
  --     DCTO       => dout,
  --     SYS_STATUS => sys_status,

  --     RST     => rst_s,
  --     IMAGEO  => din,
  --     DV      => idv,
  --     TESTEND => testend
  --   );

  --########################## OUTPUT PORTS WIRING #############################

  --########################## COBINATORIAL FUNCTIONS ##########################

  --gate_clk_s <= '0' when testend = false else
  --              '1';

  --clk_s <= clk AND (not gate_clk_s);
  --rst   <= rst_s OR rst_emu;

  --########################## PROCESSES #######################################

  P_DCT_DATA_GEN : process (clk, rst) is

    variable already_computed : boolean;

  begin

    if (rst = '1') then
      din           <= (others => '0');
      idv           <= '0';
      process_cnt   <= 0;
      input_row_cnt <= 0;
    elsif (clk'event AND clk = '1') then
      idv <= '0';
      din <= (others => '0');

      if (sys_status = SYS_RUN) then
        already_computed := false;
        idv <= '1';
        if (process_cnt < input_data01'length) then
          din         <= std_logic_vector(to_unsigned(input_data01(process_cnt), din'length));
          process_cnt <= process_cnt + 1;
          if (process_cnt mod N = 0) then
            input_row_cnt <= input_row_cnt + 1;
          end if;
        elsif (process_cnt = input_data01'length) then
          idv <= '0';
        end if;
      else
        if (rst_emu = '1' and already_computed = false) then
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

  P_DCT_DATA_READ : process (clk, rst) is
  begin

    if (rst = '1') then
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
        dct2d_data(dct2d_cnt) <= to_integer(signed(dout));
        dct2d_cnt             <= dct2d_cnt + 1;
      end if;
    end if;

  end process P_DCT_DATA_READ;

  P_TB : process is
  begin

    sys_enrg_status <= sys_enrg_ok;
    first_run       <= '1';
    rst_emu         <= '0';
    wait for 210 * C_CLK_PERIOD_NS;
    first_run       <= '0';
    rst_emu         <= '0';
    sys_enrg_status <= sys_enrg_hazard;
    wait for 400  * C_CLK_PERIOD_NS;
    rst_emu         <= '1';
    wait for 2 * C_CLK_PERIOD_NS;
    rst_emu         <= '0';
    sys_enrg_status <= sys_enrg_ok;
    --wait for C_CLK_PERIOD_NS;
    --rst_emu             <= '0';
    --wait for 10 * C_CLK_PERIOD_NS;
    --first_emu_run <= '0';
    --wait for 300 * C_CLK_PERIOD_NS;
    --sys_enrg_status <= sys_enrg_hazard;
    --wait for 400 * C_CLK_PERIOD_NS;
    --rst_emu             <= '1';
    --sys_enrg_status <= sys_enrg_ok;
    --wait for C_CLK_PERIOD_NS;
    --rst_emu             <= '0';
    --sys_enrg_status <= sys_enrg_ok;
    wait;

  end process P_TB;

end architecture BEHAVIORAL;

-----------------------------------

