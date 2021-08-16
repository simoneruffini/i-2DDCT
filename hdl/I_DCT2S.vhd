--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
--
-- Create Date:     Tue Aug 10 19:56:09 CEST 2021
-- Design Name:     I_DCT2S
-- Module Name:     I_DCT2S.vhd -- Behavioral
-- Project Name:    iMDCT
-- Description:     intermittent Discrete Cosine Transform 2nd Stage
--
-- Revision:
-- Revision 00 - Simone Ruffini
--  * File Created
-- Additional Comments:
-- * Design adapted from work of Michal Krepa https://opencores.org/projects/mdct
--------------------------------------------------------------------------------

----------------------------- PACKAGES/LIBRARIES -------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

-- User libraries

library WORK;
  use WORK.I_MDCT_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity I_DCT2S is
  port (
    CLK          : in    std_logic;                                    -- Input Clock
    RST          : in    std_logic;                                    -- Reset signal (active high)
    ----------------------------------------------------------
    RAM_RADDR    : out   std_logic_vector(C_RAMADDR_W - 1 downto 0);   -- RAM read address output
    RAM_DOUT     : in    std_logic_vector(C_RAMDATA_W - 1 downto 0);   -- RAM data output input
    DATAREADY    : in    std_logic;                                    -- New data available from DCT1S (memories just switched)
    DATAREADYACK : out   std_logic;                                    -- Acknowledge data ready (don't know why)
    ----------------------------------------------------------
    ROME_ADDR    : out   rom2_addr_t;                                  -- ROME address output
    ROMO_ADDR    : out   rom2_addr_t;                                  -- ROMO address output
    ROME_DOUT    : in    rom2_data_t;                                  -- ROME data output
    ROMO_DOUT    : in    rom2_data_t;                                  -- ROMO data output
    ----------------------------------------------------------
    ODV          : out   std_logic;                                    -- Output Data Valid signal
    DCTO         : out   std_logic_vector(C_OUTDATA_W - 1 downto 0);   -- DCT output
    RMEMSEL      : out   std_logic;                                    -- Mem select read operation (changes ram_dout input from ram1 to ram2 and viceversa)
    ----------------------------------------------------------
    NEW_FRAME    : in    std_logic                                     -- New frame available il ram
  );
end entity I_DCT2S;

----------------------------- ARCHITECTURE -------------------------------------

architecture BEHAVIORAL of I_DCT2S is

  --########################### CONSTANTS 1 ####################################
  constant C_PIPELINE_STAGES                          : natural := 5;

  --########################### TYPES ##########################################

  type input_data2 is array (N - 1 downto 0) of signed(C_RAMDATA_W downto 0);                           -- One extra bit

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################

  signal dbuf                                         : input_data2;
  signal dcti_shift_reg                               : input_data2;

  --signal col_cnt         : UNsigned(C_RAMADDR_W/2-1 downto 0);
  -- signal row_cnt                                    : unsigned(C_RAMADDR_W / 2 - 1 downto 0); -- TODO delete, not used

  signal col_cnt                                      : unsigned(ilog2(N) - 1 downto 0);                -- Column of bufferized DCT1S frame counter
  -- NOTE: this is the current column fed to ROM from dbuf

  signal ram_col                                      : unsigned(ilog2(N) - 1 downto 0);
  signal ram_col2                                     : unsigned(ilog2(N) - 1 downto 0);
  signal ram_row                                      : unsigned(ilog2(N) - 1 downto 0);
  signal ram_row2                                     : unsigned(ilog2(N) - 1 downto 0);

  signal rmemsel_reg                                  : std_logic;
  signal stage1_en                                    : std_logic;
  signal stage2_en                                    : std_logic;
  signal stage2_cnt                                   : unsigned(C_RAMADDR_W - 1 downto 0);

  signal dataready_2_reg                              : std_logic;

  signal is_even                                      : std_logic;
  signal is_even_d                                    : std_logic_vector((C_PIPELINE_STAGES - 1) - 1 downto 0);

  signal odv_s                                        : std_logic;
  signal odv_d                                        : std_logic_vector(C_PIPELINE_STAGES - 1 downto 0);

  signal dcto_1                                       : std_logic_vector(C_PL2_DATA_W - 1 downto 0);
  signal dcto_2                                       : std_logic_vector(C_PL2_DATA_W - 1 downto 0);
  signal dcto_3                                       : std_logic_vector(C_PL2_DATA_W - 1 downto 0);
  signal dcto_4                                       : std_logic_vector(C_PL2_DATA_W - 1 downto 0);
  signal dcto_5                                       : std_logic_vector(C_PL2_DATA_W - 1 downto 0);
  signal rome_dout_d1                                 : rom2_data_t;
  signal romo_dout_d1                                 : rom2_data_t;
  signal rome_dout_d2                                 : rom2_data_t;
  signal romo_dout_d2                                 : rom2_data_t;
  signal rome_dout_d3                                 : rom2_data_t;
  signal romo_dout_d3                                 : rom2_data_t;
  signal rome_dout_d4                                 : rom2_data_t;
  signal romo_dout_d4                                 : rom2_data_t;

  signal last_dbuf_cmplt                                  : std_logic; -- Last data buffer was computed and pushed out completely from pipeline
  signal dbuf_cmplt_d                                : std_logic_vector((1+ C_PIPELINE_STAGES) - 1 downto 0);       -- Data Buffer Complete Delay : Once stage2_cnt = N-1 last data of dbuf goes first through ROM then in Pipleline and it's computation completes

  --########################### ARCHITECTURE BEGIN #############################

begin

  --########################### ENTITY DEFINITION ##############################

  --########################## OUTPUT PORTS WIRING #############################

  DCTO <= dcto_5(C_PL2_DATA_W - 1 downto 12);

  ODV <= odv_d(odv_d'length - 1); -- Output data valid 5 clock delay

  RAM_RADDR <= std_logic_vector(resize(ram_row & ram_col, RAM_RADDR'length));

  rmemsel <= rmemsel_reg;

  --########################## COBINATORIAL FUNCTIONS ##########################
  last_dbuf_cmplt <= dbuf_cmplt_d(dbuf_cmplt_d'length - 1);

  --########################## PROCESSES #######################################
  P_DATA_BUF_AND_CTRL : process (CLK, RST) is
  begin

    if (RST = '1') then
      dcti_shift_reg <= (others => (others => '0'));
      dbuf           <= (others => (others => '0'));

      stage2_cnt  <= (others => '1');
      rmemsel_reg <= '0';

      stage1_en <= '0';
      stage2_en <= '0';

      col_cnt <= (others => '0');
      --row_cnt         <= (others => '0');
      ram_col         <= (others => '0');
      ram_col2        <= (others => '0');
      ram_row         <= (others => '0');
      ram_row2        <= (others => '0');
      odv_s           <= '0';
      dataready_2_reg <= '0';       -- TODO delete
    elsif (CLK='1' and CLK'event) then
      stage2_en       <= '0';
      odv_s           <= '0';
      DATAREADYACK    <= '0';
      dataready_2_reg <= dataready; -- TODO delete

      ----------------------------------
      -- read DCT 1S to barrel shifer
      ----------------------------------
      if (stage1_en = '1') then
        -- right shift input data
        dcti_shift_reg(dcti_shift_reg'length - 2 downto 0) <= dcti_shift_reg(dcti_shift_reg'length  - 1 downto 1);
        dcti_shift_reg(dcti_shift_reg'length - 1)          <= resize(signed(RAM_DOUT), C_RAMDATA_W + 1);

        ram_col2 <= ram_col2 + 1;   -- 0->N-1 (7)
        ram_col  <= ram_col + 1;    -- 0->N-1 (7) (starts from 1)

        -- Last column is requested right now
        -- ram_col2 == 6-> 7
        -- ram_col  == 7-> 0
        -- Increase row
        if (ram_col2 = N - 2) then
          ram_row <= ram_row + 1;
        end if;

        -- A line was read now it goes into the pipeline
        if (ram_col2 = N - 1) then
          ram_row2 <= ram_row2 + 1;

          if (ram_row2 = N - 1) then
            stage1_en <= '0';
            ram_col   <= (others => '0');
            -- release memory
            rmemsel_reg <= not rmemsel_reg;
          end if;

          -- after this sum dbuf is in range of -256 to 254 (min to max)
          dbuf(0) <= dcti_shift_reg(1) + resize(signed(RAM_DOUT), C_RAMDATA_W + 1);
          dbuf(1) <= dcti_shift_reg(2) + dcti_shift_reg(7);
          dbuf(2) <= dcti_shift_reg(3) + dcti_shift_reg(6);
          dbuf(3) <= dcti_shift_reg(4) + dcti_shift_reg(5);
          dbuf(4) <= dcti_shift_reg(1) - resize(signed(RAM_DOUT), C_RAMDATA_W + 1);
          dbuf(5) <= dcti_shift_reg(2) - dcti_shift_reg(7);
          dbuf(6) <= dcti_shift_reg(3) - dcti_shift_reg(6);
          dbuf(7) <= dcti_shift_reg(4) - dcti_shift_reg(5);

          -- 8 point input latched
          stage2_en <= '1';
        end if;
      end if;
      --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      -- 2nd stage
      --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      if (stage2_cnt < N) then
        stage2_cnt <= stage2_cnt + 1;

        -- output data valid
        odv_s <= '1';

        -- increment column counter
        col_cnt <= col_cnt + 1;

        -- finished processing one input row
        -- not used
        --if (col_cnt = N - 1) then
        --  --  row_cnt <= row_cnt + 1;
        --end if;
        -- not used
      end if;

      if (stage2_en = '1') then
        stage2_cnt <= (others => '0');
        col_cnt    <= (0=>'1', others => '0');
      end if;
      --------------------------------

      ----------------------------------
      -- wait for new data
      ----------------------------------
      -- one of ram buffers has new data, process it
      --if (dataready = '1' and dataready_2_reg = '0') then
      --  stage1_en <= '1';
      --  -- to account for 1T RAM delay, increment RAM address counter
      --  ram_col2 <= (others => '0');
      --  ram_col  <= (0=>'1', others => '0');
      --  DATAREADYACK <= '1';
      --end if;
      if (NEW_FRAME = '1') then
        stage1_en <= '1';
        -- to account for 1T RAM delay, increment RAM address counter
        ram_col2 <= (others => '0');
        ram_col  <= (0=>'1', others => '0');
      end if;
      ----------------------------------
    end if;

  end process P_DATA_BUF_AND_CTRL;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Delays for internal signals

  P_DELAYS : process (CLK, RST) is
  begin

    if (RST='1') then
      is_even       <= '0';
      is_even_d     <= (others => '0');
      odv_d         <= (others => '0');
      dbuf_cmplt_d <= (others => '1');
    elsif (CLK'event and CLK = '1') then
      -- stge2_cnt first bit represents even (=0) or odd (=1) row computation in the pipeline
      is_even <= not stage2_cnt(0);

      -- Is even delay with shift register
      is_even_d(is_even_d'length - 1 downto 1) <= is_even_d(is_even_d'length - 2 downto 0);
      is_even_d(0)                             <= is_even;

      -- Output data valid delay
      odv_d(odv_d'length - 1 downto 1) <= odv_d(odv_d'length - 2 downto 0);
      odv_d(0)                         <= odv_s;

      dbuf_cmplt_d(dbuf_cmplt_d'length - 1 downto 1) <= dbuf_cmplt_d(dbuf_cmplt_d'length - 2 downto 0);

      -- If stage2_cnt counted 8 or more times (after reset) then
      -- a frame was completed/computed and pushed outside
      if (stage2_cnt >= N - 1) then
        dbuf_cmplt_d(0) <= '1';
      else
        dbuf_cmplt_d(0) <= '0';
      end if;
    end if;

  end process P_DELAYS;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Data Pipeline

  P_DATA_OUT_PIPE : process (CLK, RST) is
  begin

    if (RST = '1') then
      dcto_1 <= (others => '0');
      dcto_2 <= (others => '0');
      dcto_3 <= (others => '0');
      dcto_4 <= (others => '0');
      dcto_5 <= (others => '0');
    elsif (CLK'event and CLK = '1') then
      if (is_even = '0') then
        dcto_1 <= std_logic_vector(resize
                                   (resize(signed(ROME_DOUT(0)), C_PL2_DATA_W) +
                                     (resize(signed(ROME_DOUT(1)), C_PL2_DATA_W - 1) & '0') +
                                     (resize(signed(ROME_DOUT(2)), C_PL2_DATA_W - 2) & "00"),
                                     C_PL2_DATA_W));
      else
        dcto_1 <= std_logic_vector(resize
                                   (resize(signed(ROMO_DOUT(0)), C_PL2_DATA_W) +
                                     (resize(signed(ROMO_DOUT(1)), C_PL2_DATA_W - 1) & '0') +
                                     (resize(signed(ROMO_DOUT(2)), C_PL2_DATA_W - 2) & "00"),
                                     C_PL2_DATA_W));
      end if;

      if (is_even_d(C_PIPELINE_STAGES - C_PIPELINE_STAGES) = '0') then       -- is even 1 clock delay
        dcto_2 <= std_logic_vector(resize
                                   (signed(dcto_1) +
                                     (resize(signed(rome_dout_d1(3)), C_PL2_DATA_W - 3) & "000") +
                                     (resize(signed(rome_dout_d1(4)), C_PL2_DATA_W - 4) & "0000"),
                                     C_PL2_DATA_W));
      else
        dcto_2 <= std_logic_vector(resize
                                   (signed(dcto_1) +
                                     (resize(signed(romo_dout_d1(3)), C_PL2_DATA_W - 3) & "000") +
                                     (resize(signed(romo_dout_d1(4)), C_PL2_DATA_W - 4) & "0000"),
                                     C_PL2_DATA_W));
      end if;

      if (is_even_d(C_PIPELINE_STAGES - (C_PIPELINE_STAGES - 1)) = '0') then -- is even 2 clock delay
        dcto_3 <= std_logic_vector(resize
                                   (signed(dcto_2) +
                                     (resize(signed(rome_dout_d2(5)), C_PL2_DATA_W - 5) & "00000") +
                                     (resize(signed(rome_dout_d2(6)), C_PL2_DATA_W - 6) & "000000"),
                                     C_PL2_DATA_W));
      else
        dcto_3 <= std_logic_vector(resize
                                   (signed(dcto_2) +
                                     (resize(signed(romo_dout_d2(5)), C_PL2_DATA_W - 5) & "00000") +
                                     (resize(signed(romo_dout_d2(6)), C_PL2_DATA_W - 6) & "000000"),
                                     C_PL2_DATA_W));
      end if;

      if (is_even_d(C_PIPELINE_STAGES - (C_PIPELINE_STAGES - 2)) = '0') then -- is even 3 clock delay
        dcto_4 <= std_logic_vector(resize
                                   (signed(dcto_3) +
                                     (resize(signed(rome_dout_d3(7)), C_PL2_DATA_W - 7) & "0000000") +
                                     (resize(signed(rome_dout_d3(8)), C_PL2_DATA_W - 8) & "00000000"),
                                     C_PL2_DATA_W));
      else
        dcto_4 <= std_logic_vector(resize
                                   (signed(dcto_3) +
                                     (resize(signed(romo_dout_d3(7)), C_PL2_DATA_W - 7) & "0000000") +
                                     (resize(signed(romo_dout_d3(8)), C_PL2_DATA_W - 8) & "00000000"),
                                     C_PL2_DATA_W));
      end if;

      if (is_even_d(C_PIPELINE_STAGES - (C_PIPELINE_STAGES - 3)) = '0') then -- is even 4 clock delay
        dcto_5 <= std_logic_vector(resize
                                   (signed(dcto_4) +
                                     (resize(signed(rome_dout_d4(9)), C_PL2_DATA_W - 9) & "000000000") -
                                     (resize(signed(rome_dout_d4(10)), C_PL2_DATA_W - 10) & "0000000000"),
                                     C_PL2_DATA_W));
      else
        dcto_5 <= std_logic_vector(resize
                                   (signed(dcto_4) +
                                     (resize(signed(romo_dout_d4(9)), C_PL2_DATA_W - 9) & "000000000") -
                                     (resize(signed(romo_dout_d4(10)), C_PL2_DATA_W - 10) & "0000000000"),
                                     C_PL2_DATA_W));
      end if;
    end if;

  end process P_DATA_OUT_PIPE;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Rom address generator: read precomputed MAC results from LUT

  P_ROMX_ADDR : process (CLK, RST) is
  begin

    if (RST = '1') then
      ROME_ADDR <= (others => (others => '0'));
      ROMO_ADDR <= (others => (others => '0'));
    elsif (CLK'event and CLK = '1') then
      for i in 0 to 10 loop
        -- read precomputed MAC results from LUT
        ROME_ADDR(i) <= std_logic_vector(col_cnt(ilog2(C_FRAME_SIZE) / 2 - 1 downto 1)) &
                        dbuf(0)(i) &
                        dbuf(1)(i) &
                        dbuf(2)(i) &
                        dbuf(3)(i);
        -- odd
        --ROMO_ADDR(i) <= std_logic_vector(col_cnt(C_RAMADDR_W/2-1 downto 1)) &
        ROMO_ADDR(i) <= std_logic_vector(col_cnt(ilog2(C_FRAME_SIZE) / 2 - 1 downto 1)) &
                        dbuf(4)(i) &
                        dbuf(5)(i) &
                        dbuf(6)(i) &
                        dbuf(7)(i);
      end loop;
    end if;

  end process P_ROMX_ADDR;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Rom data output delay used by pipeline

  P_ROMX_DOUT_D : process (CLK, RST) is
  begin

    if (RST = '1') then
      rome_dout_d1 <= (others => (others => '0'));
      romo_dout_d1 <= (others => (others => '0'));
      rome_dout_d2 <= (others => (others => '0'));
      romo_dout_d2 <= (others => (others => '0'));
      rome_dout_d3 <= (others => (others => '0'));
      romo_dout_d3 <= (others => (others => '0'));
      rome_dout_d4 <= (others => (others => '0'));
      romo_dout_d4 <= (others => (others => '0'));
    elsif (CLK'event and CLK = '1') then
      rome_dout_d1 <= ROME_DOUT;
      romo_dout_d1 <= ROMO_DOUT;
      rome_dout_d2 <= rome_dout_d1;
      romo_dout_d2 <= romo_dout_d1;
      rome_dout_d3 <= rome_dout_d2;
      romo_dout_d3 <= romo_dout_d2;
      rome_dout_d4 <= rome_dout_d3;
      romo_dout_d4 <= romo_dout_d3;
    end if;

  end process P_ROMX_DOUT_D;

end architecture BEHAVIORAL;

--------------------------------------------------------------------------------

