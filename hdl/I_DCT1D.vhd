--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
--
-- Create Date:     Wed Jun  9 14:39:11 CEST 2021
-- Design Name:     I_DCT1D
-- Module Name:     I_DCT1D.vhd - RTL
-- Project Name:    iMDCT
-- Description:     intermittent 1D Discrete Cosine Transform (1st stage)
--
-- Revision:
-- Revision 00 - Simone Ruffini
--  * File Created
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

----------------------------- ENTITY -------------------------------------------

entity I_DCT1D is
  port (
    CLK                     : in    std_logic;                                          -- Input clock
    RST                     : in    std_logic;                                          -- Positive reset
    DCTI                    : in    std_logic_vector(C_INDATA_W - 1 downto 0);          -- DCT input data
    IDV                     : in    std_logic;                                          -- Input data valid
    ROME_DOUT               : in    t_rom1datao;                                        -- ROME data output
    ROMO_DOUT               : in    t_rom1datao;                                        -- ROMO data output

    ROME_ADDR               : out   t_rom1addro;                                        -- ROME address output
    ROMO_ADDR               : out   t_rom1addro;                                        -- ROMO address output
    RAM_WADDR               : out   std_logic_vector(RAMADRR_W - 1 downto 0);           -- RAM write address output
    RAM_DIN                 : out   std_logic_vector(RAMDATA_W - 1 downto 0);           -- RAM data input
    RAM_WE                  : out   std_logic;                                          -- RAM write enable
    FRAME_CMPLT             : out   std_logic;                                          -- Write memory select signal

    -- Debug -------------------------------------------------
    ODV                     : out   std_logic;                                          -- Output data valid
    DCTO                    : out   std_logic_vector(C_OUTDATA_W - 1 downto 0);         -- DCT data output
    ----------------------------------------------------------
    -- Intermittent Enhancment Ports -------------------------
    BUS_MSYNC               : in    std_logic;                                          --master sync signal
    BUS_MISO                : in    std_logic_vector(G_C_BUSDATA_W - 1 downto 0);
    BUS_MOSI                : out   std_logic_vector(G_C_BUSDATA_W - 1 downto 0);
    BUS_SSYNC               : out   std_logic;                                          --slave sync signal
    NV_MEM_BUSY             : in    std_logi -- ro remove
    ----------------------------------------------------------
  );
end entity I_DCT1D;

----------------------------- ARCHITECTURE -------------------------------------

architecture RTL of I_DCT1D is

  --########################### CONSTANTS 1 ####################################
  constant C_NV_DATA_BUF_DATA_W           : natural := C_INDATA_W + 1;

  --########################### TYPES ##########################################

  type input_data is array (N - 1 downto 0) of signed(C_INDATA_W downto 0);                  -- NOTE: C_INDATA_W not C_INDATA_W-1, one bit extra

  type ram_waddr_delay_t is array (natural range <>) of std_logic_vector(RAMADRR_W - 1 downto 0);

  type nvfsm_t is (
    S_init,
    S_wait,
    S_bus_msync_1time,
    S_chkpnt_push,
    S_chkpnt_load,
    S_data_buf0,
    S_data_buf1,
    S_data_buf2,
    S_data_buf3,
    S_data_buf4,
    S_data_buf5,
    S_data_buf6,
    S_data_buf7,
    S_row_cnt,
    S_nv_proc_end
  );

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################

  signal data_buf                         : input_data;
  signal dcti_shift_reg                   : input_data;

  signal col_cnt                          : unsigned(RAMADRR_W / 2 - 1 downto 0);

  signal row_cnt                          : unsigned(RAMADRR_W / 2 - 1 downto 0);
  signal inpt_cnt                         : unsigned(RAMADRR_W / 2 - 1 downto 0);
  signal ram_we_s                         : std_logic;
  signal frame_cmplt_s                    : std_logic;
  signal stage2_start                     : std_logic;
  signal stage2_cnt                       : unsigned(RAMADRR_W - 1 downto 0);                -- could be trasformed into: natural range (0 to N);
  signal col_cnt2                         : unsigned(RAMADRR_W / 2 - 1 downto 0);
  signal ram_waddr_s                      : std_logic_vector(RAMADRR_W - 1 downto 0);

  signal is_even                          : std_logic;                                       -- if is_even = '1' then this stage in the pipeline is computing an even row, else, if '0' an odd one.
  signal is_even_d                        : std_logic_vector(3 - 1 downto 0);
  signal ram_we_d                         : std_logic_vector(4 - 1 downto 0);
  signal ram_waddr_d                      : ram_waddr_delay_t (4 - 1 downto 0);
  signal frame_cmplt_s_d                  : std_logic_vector(4 - 1 downto 0);

  signal rome_dout_d1                     : t_rom1datao;
  signal romo_dout_d1                     : t_rom1datao;
  signal rome_dout_d2                     : t_rom1datao;
  signal romo_dout_d2                     : t_rom1datao;
  signal rome_dout_d3                     : t_rom1datao;
  signal romo_dout_d3                     : t_rom1datao;
  signal dcto_1                           : std_logic_vector(DA_W - 1 downto 0);
  signal dcto_2                           : std_logic_vector(DA_W - 1 downto 0);
  signal dcto_3                           : std_logic_vector(DA_W - 1 downto 0);
  signal dcto_4                           : std_logic_vector(DA_W - 1 downto 0);

  signal nvfsm_pres_state                 : is nvfsm_t;
  signal nvfsm_fut_state                  : is nvfsm_t;

  signal chkpnt_save_en                   : std_logic;
  signal chkpnt_load_en                   : std_logic;
  signal chkpnt_load_en_ff                : std_logic;
  signal chkpnt_push_en_ff                : std_logic;
  --########################### ARCHITECTURE BEGIN #############################

begin

  --########################### ENTITY DEFINITION ##############################

  --########################## OUTPUT PORTS WIRING #############################

  RAM_WADDR   <= ram_waddr_d(ram_waddr_d'length - 1);             -- 4 clock dealy
  RAM_WE      <= ram_we_d(ram_we_d'length - 1);                   -- 4 clock dealy
  ODV         <= ram_we_d(ram_we_d'length - 1);                   -- 4 clock dealy
  RAM_DIN     <= dcto_4(DA_W - 1 downto 12);
  DCTO        <= std_logic_vector(resize(signed(dcto_4(DA_W - 1 downto 12)), C_OUTDATA_W));
  FRAME_CMPLT <= frame_cmplt_s_d(frame_cmplt_s_d'length - 1);     -- 4 clock delay

  --########################## PROCESSES #######################################

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- sequential process for fsm (synthesized FFs)

  P_NVFSM_SEQ : process (CLK, RST) is
  begin

    if (RST = '1') then
      nvfsm_pres_state <= S_init;
    elsif (CLK'event and CLK = '1') then
      present_state <= nvfsm_fut_state;
    end if;

  end process P_NVFSM_SEQ;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Future state computation for nvfsm (combinatorial process)

  P_NVFSM_FUT_S : process (nvfsm_pres_state, BUS_MSYNC) is
  begin

    case nvfsm_pres_state is

      when S_init =>
        nvfsm_fut_state <= S_wait;

      when S_wait =>

        if (BUS_MSYNC = '1') then
          nvfsm_fut_state <= S_bus_msync_1time;
        end if;

      when S_bus_msync_1time =>

        if (BUS_MSYNC = '1') then
          nvfsm_fut_state <= S_chkpnt_load;
        else
          nvfsm_fut_state <= S_chkpnt_push;
        end if;

      when S_chkpnt_push =>
        nvfsm_fut_state <= S_data_buf0;
      when S_chkpnt_load =>
        nvfsm_fut_state <= S_data_buf0;
      when S_data_buf0 =>

        if (NV_MEM_BUSY = '0') then
          nvfsm_fut_state <= S_data_buf1;
        end if;

      when S_data_buf1 =>

        if (NV_MEM_BUSY = '0') then
          nvfsm_fut_state <= S_data_buf2;
        end if;

      when S_data_buf2 =>

        if (NV_MEM_BUSY = '0') then
          nvfsm_fut_state <= S_data_buf3;
        end if;

      when S_data_buf3 =>

        if (NV_MEM_BUSY = '0') then
          nvfsm_fut_state <= S_data_buf4;
        end if;

      when S_data_buf4 =>

        if (NV_MEM_BUSY = '0') then
          nvfsm_fut_state <= S_data_buf5;
        end if;

      when S_data_buf5 =>

        if (NV_MEM_BUSY = '0') then
          nvfsm_fut_state <= S_data_buf6;
        end if;

      when S_data_buf6 =>

        if (NV_MEM_BUSY = '0') then
          nvfsm_fut_state <= S_data_buf7;
        end if;

      when S_data_buf7 =>

        if (NV_MEM_BUSY = '0') then
          nvfsm_fut_state <= S_row_cnt;
        end if;

      when S_row_cnt =>

        if (NV_MEM_BUSY = '0') then
          nvfsm_fut_state <= S_nv_proc_end;
        end if;

      when S_nv_proc_end =>
        nvfsm_fut_state <= S_wait;

    end case;

  end process P_NVFSM_FUT_S;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Output generator for a mealy fsm (output depends on input)

  P_NVFSM_OUTPUTS : process (nvfsm_pres_state, BUS_MSYNC) is
  begin

    -- defaults
    -- By defining them the synthesizer produces a combinatrial logic without FFs
    chkpnt_load_en <= '0';
    chkpnt_push_en <= '0';

    case nvfsm_pres_state is

      when S_chkpnt_push =>

        if (BUS_MSYNC = '1') then
          chkpnt_push_en <= '1';
        end if;

      when S_chkpnt_load =>

        if (BUS_MSYNC = '1') then
          chkpnt_load_en <= '1';
        end if;

    end case;

  end process P_NVFSM_OUTPUTS;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Keep non volatile push/load tasks on after signaling

  P_KEEP_NVTASKS_ON : process (RST, CLK) is
  begin

    if (RST= '1') then
      chkpnt_load_en_ff <= '0';
      chkpnt_push_en_ff <= '0';
    elsif (CLK'event and CLK = '1') then
      if (chkpnt_load_en = '1') then
        chkpnt_load_en_ff <= '1';
      end if;
      if (chkpnt_push_en = '1') then
        chkpnt_push_en_ff <= '1';
      end if;

      if (nvfsm_pres_state = S_nv_proc_end) then
        chkpnt_load_en_ff <= '0';
        chkpnt_push_en_ff <= '0';
      end if;
    end if;

  end process P_KEEP_NVTASKS_ON;

  process (CLK, RST) is -- //TODO add label
  begin

    if (RST = '1') then
      inpt_cnt       <= (others => '0');
      dcti_shift_reg <= (others => (others => '0'));
      data_buf       <= (others => (others => '0'));
      stage2_start   <= '0';
      stage2_cnt     <= (others => '1');               -- NOTE: stage2_cnt starts from 63 because if 0 it triggers 2stage prematurely
      ram_we_s       <= '0';
      ram_waddr_s    <= (others => '0');
      col_cnt        <= (others => '0');
      row_cnt        <= (others => '0');
      frame_cmplt_s  <= '0';
      col_cnt2       <= (others => '0');
    elsif (CLK = '1' and CLK'event) then
      if (chkpnt_load_en = '1') then
      -- when in row_cnt ram_waddr_s <=row_cnt
      elsif (chkpnt_save_en \= '1') then
        stage2_start  <= '0';
        ram_we_s      <= '0';
        frame_cmplt_s <= '0';

        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        -- 1st stage
        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if (IDV = '1') then
          inpt_cnt <= inpt_cnt + 1;                    -- 0->7

          -- Input data is level shifted. This will range DC coeff to boundary 9 bits

          -- DCTI shift register: right shift input data
          dcti_shift_reg(N - 2 downto 0) <= dcti_shift_reg(N - 1 downto 1);
          dcti_shift_reg(N - 1)          <= SIGNED('0' & DCTI) - LEVEL_SHIFT;

          if (inpt_cnt = N - 1) then
            -- after this sum data_buf is in range of -256 to 254 (min to max)
            data_buf(0) <= dcti_shift_reg(1) + (SIGNED('0' & DCTI) - LEVEL_SHIFT);
            data_buf(1) <= dcti_shift_reg(2) + dcti_shift_reg(7);
            data_buf(2) <= dcti_shift_reg(3) + dcti_shift_reg(6);
            data_buf(3) <= dcti_shift_reg(4) + dcti_shift_reg(5);
            data_buf(4) <= dcti_shift_reg(1) - (SIGNED('0' & DCTI) - LEVEL_SHIFT);
            data_buf(5) <= dcti_shift_reg(2) - dcti_shift_reg(7);
            data_buf(6) <= dcti_shift_reg(3) - dcti_shift_reg(6);
            data_buf(7) <= dcti_shift_reg(4) - dcti_shift_reg(5);

            stage2_start <= '1';
          end if;
        end if;
        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        -- 2nd stage
        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        --This code is wanky //TODO: should be revisited
        if (stage2_cnt < N) then
          stage2_cnt <= stage2_cnt + 1;                -- theoretical 0->63, real 0->8

          -- write RAM
          ram_we_s <= '1';
          -- reverse col/row order for transposition purpose
          ram_waddr_s <= STD_LOGIC_VECTOR(col_cnt2 & row_cnt);
          -- increment column counter
          col_cnt  <= col_cnt + 1;                     -- 0->7
          col_cnt2 <= col_cnt2 + 1;                    -- 0->7

          -- finished processing one input row
          if (col_cnt = 0) then
            row_cnt <= row_cnt + 1;                    -- 0->7
            -- Signal a complete frame to DBUFCTL (resultin in switch to 2nd memory)
            if (row_cnt = N - 1) then
              frame_cmplt_s <= '1';
              col_cnt       <= (others => '0');
            end if;
          end if;
        end if;

        if (stage2_start = '1') then
          stage2_cnt <= (others => '0');

          -- row_cnt++ happens when col_cnt overloeads to 0 (see finished processing input row).
          -- So this needs to be triggered by logic and not by intialization, hence col_cnt starts from 1
          col_cnt <= (0=>'1', others => '0');

          col_cnt2 <= (others => '0');
        end if;

        --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      end if;
    end if;

  end process;

  -- output data pipeline
  P_DATA_OUT_PIPE : process (CLK, RST) is
  begin

    if (RST = '1') then
      is_even         <= '0';
      is_even_d       <= (others => '0');
      ram_we_d        <= (others => '0');
      ram_waddr_d     <= (others => (others => '0'));
      frame_cmplt_s_d <= (others => '0');

      dcto_1 <= (others => '0');
      dcto_2 <= (others => '0');
      dcto_3 <= (others => '0');
      dcto_4 <= (others => '0');
    elsif (CLK'event and CLK = '1') then
      -- stge2_cnt(0) represents even (=0) or odd (=1) row computation in the pipeline
      is_even <= not stage2_cnt(0);

      -- Is even delay with shift register
      is_even_d(is_even_d'length - 1 downto 1) <= is_even_d(is_even_d'length - 2 downto 0);
      is_even_d(0)                             <= is_even;

      ram_we_d(ram_we_d'length - 1 downto 1 ) <= ram_we_d(ram_we_d'length - 2 downto 0);
      ram_we_d(0)                             <= ram_we_s;

      ram_waddr_d(ram_waddr_d'length - 1 downto 1) <= ram_waddr_d(ram_waddr_d'length - 2 downto 0);
      ram_waddr_d(0)                               <= ram_waddr_s;

      frame_cmplt_s_d (frame_cmplt_s_d'length - 1 downto 1) <= frame_cmplt_s_d(frame_cmplt_s_d'length - 2 downto 0);
      frame_cmplt_s_d(0)                                    <= frame_cmplt_s;

      if (is_even = '1') then          -- is even
        dcto_1 <= STD_LOGIC_VECTOR(RESIZE
                                   (RESIZE(SIGNED(ROME_DOUT(0)), DA_W) +
                                     (RESIZE(SIGNED(ROME_DOUT(1)), DA_W - 1) & '0') +
                                     (RESIZE(SIGNED(ROME_DOUT(2)), DA_W - 2) & "00"),
                                     DA_W));
      else
        dcto_1 <= STD_LOGIC_VECTOR(RESIZE
                                   (RESIZE(SIGNED(ROMO_DOUT(0)), DA_W) +
                                     (RESIZE(SIGNED(ROMO_DOUT(1)), DA_W - 1) & '0') +
                                     (RESIZE(SIGNED(ROMO_DOUT(2)), DA_W - 2) & "00"),
                                     DA_W));
      end if;

      if (is_even_d(1 - 1) = '1') then -- is even 1 clk delay
        dcto_2 <= STD_LOGIC_VECTOR(RESIZE
                                   (signed(dcto_1) +
                                     (RESIZE(SIGNED(rome_dout_d1(3)), DA_W - 3) & "000") +
                                     (RESIZE(SIGNED(rome_dout_d1(4)), DA_W - 4) & "0000"),
                                     DA_W));
      else
        dcto_2 <= STD_LOGIC_VECTOR(RESIZE
                                   (signed(dcto_1) +
                                     (RESIZE(SIGNED(romo_dout_d1(3)), DA_W - 3) & "000") +
                                     (RESIZE(SIGNED(romo_dout_d1(4)), DA_W - 4) & "0000"),
                                     DA_W));
      end if;

      if (is_even_d(2 - 1) = '1') then -- is even 2 clock delay
        dcto_3 <= STD_LOGIC_VECTOR(RESIZE
                                   (signed(dcto_2) +
                                     (RESIZE(SIGNED(rome_dout_d2(5)), DA_W - 5) & "00000") +
                                     (RESIZE(SIGNED(rome_dout_d2(6)), DA_W - 6) & "000000"),
                                     DA_W));
      else
        dcto_3 <= STD_LOGIC_VECTOR(RESIZE
                                   (signed(dcto_2) +
                                     (RESIZE(SIGNED(romo_dout_d2(5)), DA_W - 5) & "00000") +
                                     (RESIZE(SIGNED(romo_dout_d2(6)), DA_W - 6) & "000000"),
                                     DA_W));
      end if;

      if (is_even_d(3 - 1) = '1') then -- is even 3 clock delay
        dcto_4 <= STD_LOGIC_VECTOR(RESIZE
                                   (signed(dcto_3) +
                                     (RESIZE(SIGNED(rome_dout_d3(7)), DA_W - 7) & "0000000") -
                                     (RESIZE(SIGNED(rome_dout_d3(8)), DA_W - 8) & "00000000"),
                                     DA_W));
      else
        dcto_4 <= STD_LOGIC_VECTOR(RESIZE
                                   (signed(dcto_3) +
                                     (RESIZE(SIGNED(romo_dout_d3(7)), DA_W - 7) & "0000000") -
                                     (RESIZE(SIGNED(romo_dout_d3(8)), DA_W - 8) & "00000000"),
                                     DA_W));
      end if;
    end if;

  end process P_DATA_OUT_PIPE;

  -- read precomputed MAC results from LUT
  P_ROMADDR : process (CLK, RST) is
  begin

    if (RST = '1') then
      ROME_ADDR <= (others => (others => '0'));
      ROMO_ADDR <= (others => (others => '0'));
    elsif (CLK'event and CLK = '1') then
      for i in 0 to 8 loop
        -- even
        ROME_ADDR(i) <= STD_LOGIC_VECTOR(col_cnt(RAMADRR_W / 2 - 1 downto 1)) &
                        data_buf(0)(i) &
                        data_buf(1)(i) &
                        data_buf(2)(i) &
                        data_buf(3)(i);
        -- odd
        ROMO_ADDR(i) <= STD_LOGIC_VECTOR(col_cnt(RAMADRR_W / 2 - 1 downto 1)) &
                        data_buf(4)(i) &
                        data_buf(5)(i) &
                        data_buf(6)(i) &
                        data_buf(7)(i);
      end loop;
    end if;

  end process P_ROMADDR;

  P_ROMDATAO_D1 : process (CLK, RST) is
  begin

    if (RST = '1') then
      rome_dout_d1 <= (others => (others => '0'));
      romo_dout_d1 <= (others => (others => '0'));
      rome_dout_d2 <= (others => (others => '0'));
      romo_dout_d2 <= (others => (others => '0'));
      rome_dout_d3 <= (others => (others => '0'));
      romo_dout_d3 <= (others => (others => '0'));
    elsif (CLK'event and CLK = '1') then
      rome_dout_d1 <= ROME_DOUT;
      romo_dout_d1 <= ROMO_DOUT;
      rome_dout_d2 <= rome_dout_d1;
      romo_dout_d2 <= romo_dout_d1;
      rome_dout_d3 <= rome_dout_d2;
      romo_dout_d3 <= romo_dout_d2;
    end if;

  end process P_ROMDATAO_D1;

end architecture RTL;

--------------------------------------------------------------------------------
