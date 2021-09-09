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
  use WORK.NORM_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity TOP_LEVEL_TB is
  --port (
  --);
end entity TOP_LEVEL_TB;

----------------------------- ARCHITECTURE -------------------------------------

architecture BEHAVIORAL of TOP_LEVEL_TB is

  --########################### CONSTANTS 1 ####################################
  constant C_CLK_PERIOD_NS                                   : time := 1e09 / C_CLK_FREQ_HZ * 1 ns;
  constant C_INT_EMU_PRESSCALER                              : natural := 18;
  constant C_RST_EMU_THRESH_VALUE                            : natural := 1500;
  constant C_HAZARD_THRESH_VALUE                             : natural := 2700;
  constant C_INT_EMU_RST_EMU_THRESH_INDX                     : natural := 0;

  constant C_NUM_OF_DCTI_INP_DATA                            : natural := 4 * N * N;

  constant C_DCT1D_0                                         : i_matrix_type := COMPUTE_REF_DCT1D(input_data0, true);
  constant C_DCT2D_0                                         : i_matrix_type := COMPUTE_REF_DCT1D(C_DCT1D_0, false);
  constant C_DCT1D_1                                         : i_matrix_type := COMPUTE_REF_DCT1D(input_data1, true);
  constant C_DCT2D_1                                         : i_matrix_type := COMPUTE_REF_DCT1D(C_DCT1D_1, false);
  constant C_DCT1D_2                                         : i_matrix_type := COMPUTE_REF_DCT1D(input_data3, true);
  constant C_DCT2D_2                                         : i_matrix_type := COMPUTE_REF_DCT1D(C_DCT1D_2, false);
  constant C_DCT1D_3                                         : i_matrix_type := COMPUTE_REF_DCT1D(input_data4, true);
  constant C_DCT2D_3                                         : i_matrix_type := COMPUTE_REF_DCT1D(C_DCT1D_3, false);

  --########################### TYPES ##########################################

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################

  signal clk                                                 : std_logic;
  --signal clk_s                         : std_logic;
  --signal gate_clk_s                    : std_logic;

  signal rst                                                 : std_logic;
  --signal rst_s                         : std_logic;

  signal din                                                 : std_logic_vector(C_INDATA_W - 1 downto 0);
  signal idv                                                 : std_logic;
  signal dout                                                : std_logic_vector(C_OUTDATA_W - 1 downto 0);
  signal odv                                                 : std_logic;

  signal odv1                                                : std_logic;
  signal dcto1                                               : std_logic_vector(C_1S_OUTDATA_W - 1 downto 0);

  signal nvm_busy                                            : std_logic;
  signal nvm_busy_s                                          : std_logic;
  signal nvm_en                                              : std_logic;
  signal nvm_we                                              : std_logic;
  signal nvm_raddr                                           : std_logic_vector(C_NVM_ADDR_W - 1 downto 0);
  signal nvm_waddr                                           : std_logic_vector(C_NVM_ADDR_W - 1 downto 0);
  signal nvm_din                                             : std_logic_vector(C_NVM_DATA_W - 1 downto 0);
  signal nvm_dout                                            : std_logic_vector(C_NVM_DATA_W - 1 downto 0);

  signal sys_status                                          : sys_status_t;                                                                                                          -- System status value of sys_status_t
  signal sys_enrg_status                                     : sys_enrg_status_t;                                                                                                     -- System energy status
  signal first_run                                           : std_logic;

  --signal testend                       : boolean;

  signal input_send_en                                       : std_logic;
  signal process_cnt                                         : natural;
  signal input_row_cnt                                       : natural;

  signal dct1d_cnt                                           : natural;
  signal dct2d_cnt                                           : natural;
  signal dct1d_data                                          : i_array_t (0 to C_NUM_OF_DCTI_INP_DATA);
  signal dct2d_data                                          : i_array_t (0 to C_NUM_OF_DCTI_INP_DATA);

  signal int_emu_en                                          : std_logic;
  signal int_emu_init                                        : std_logic;
  signal rst_emu                                             : std_logic;
  signal int_emu_thresh_stats                                : std_logic_vector(C_NUM_THRESHOLDS - 1 downto 0);
  signal int_emu_thresh_values                               : thresh_values_t(C_NUM_THRESHOLDS - 1 downto 0) := (0=>C_RST_EMU_THRESH_VALUE, 1=>C_HAZARD_THRESH_VALUE);
  signal int_emu_vtrace_rom_start_indx                       : natural;
  signal int_emu_vtrace_rom_samples                          : natural;
  signal vtrace_rom_raddr                                    : natural;
  signal vtrace_rom_dout                                     : integer;

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

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |INT-EMU|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_INT_EMU : entity work.int_emu
    generic map (
      VTRACE_ROM_NUM_ELEMENTS => C_VTRACE_ROM_NUM_ELEMENTS,
      NUM_THRESHOLDS          => C_NUM_THRESHOLDS,
      SAMPLES_PRESCALER       => C_INT_EMU_PRESSCALER
    )
    port map (
      CLK                   => clk,
      RST                   => rst,
      EN                    => int_emu_en,
      INIT                  => int_emu_init,
      RST_EMU               => rst_emu,
      THRESH_STATS          => int_emu_thresh_stats,
      THRESH_VALUES         => int_emu_thresh_values,
      RST_EMU_THRESH_INDX   => C_INT_EMU_RST_EMU_THRESH_INDX,
      VTRACE_ROM_START_INDX => int_emu_vtrace_rom_start_indx,
      VTRACE_ROM_SAMPLES    => int_emu_vtrace_rom_samples,
      VTRACE_ROM_RADDR      => vtrace_rom_raddr,
      VTRACE_ROM_DOUT       => vtrace_rom_dout
    );

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- |VTRACE-ROM|
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  U_VTRACE_ROM : entity work.vtrace_rom
    generic map (
      NUM_ELEMENTS_ROM => C_VTRACE_ROM_NUM_ELEMENTS
    )
    port map (
      CLK   => clk,
      RADDR => vtrace_rom_raddr,
      DOUT  => vtrace_rom_dout
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

  sys_enrg_status <= sys_enrg_hazard when int_emu_thresh_stats(1) = '1' else
                     sys_enrg_ok;

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
      first_run     <= '1';
    elsif (clk'event AND clk = '1') then
      idv <= '0';
      din <= (others => '0');
      if (sys_status = SYS_RUN AND input_send_en = '1') then
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
            --process_cnt <= process_cnt + 1;
            --do nothing alreay exact value
          end if;
          if (process_cnt > N * N - 1) then
            first_run <= '0';
          end if;
          already_computed := true;
        end if;
      end if;
    end if;

  end process P_DCT_DATA_GEN;

  P_DCT_DATA_READ : process (clk, rst) is
  begin

    if (rst = '1') then
      dct1d_data <= (others => - 101010);
      dct2d_data <= (others => - 101010);
      dct1d_cnt  <= 0;
      dct2d_cnt  <= 0;
    elsif (clk'event and clk = '1') then
      if (odv1 = '1') then
        --dct1d_data(dct1d_cnt) <= to_integer(signed(dcto1));
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

    rst                           <= '0';
    int_emu_vtrace_rom_start_indx <= 0;
    int_emu_vtrace_rom_samples    <= C_VTRACE_ROM_NUM_ELEMENTS;
    int_emu_en                    <= '0';
    int_emu_init                  <= '1';
    rst                           <= '0';
    input_send_en                 <= '0';
    wait for 10  * C_CLK_PERIOD_NS;
    rst                           <= '1';
    wait for 10 * C_CLK_PERIOD_NS;
    int_emu_en                    <= '1';
    rst                           <= '0';
    wait for 1 * C_CLK_PERIOD_NS;
    int_emu_init                  <= '0';
    wait for 107 * C_CLK_PERIOD_NS;
    input_send_en                 <= '1';
    wait;

  end process P_TB;

end architecture BEHAVIORAL;

-----------------------------------

