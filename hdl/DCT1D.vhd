--------------------------------------------------------------------------------
-- Engineer:  Michal Krepa
--            Simone Ruffini [simone.ruffini@tutanota.com]
--
-- Create Date:     Sat Mar 5 7:37 2006
-- Design Name:     MDCT Core
-- Module Name:     DCT1D.vhd - RTL
-- Project Name:    iMDCT
-- Description:     1D Discrete Cosine Transform (1st stage)
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
  use IEEE.NUMERIC_STD.all;

-- User libraries

library WORK;
  use WORK.MDCT_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity DCT1D is
  port (
    CLK           : in    std_logic;                                -- Input clock
    RST           : in    std_logic;                                -- Positive reset
    DCTI          : in    std_logic_vector(IP_W - 1 downto 0);      -- DCT input data
    IDV           : in    std_logic;                                -- Input data valid
    ROME_DOUT     : in    t_rom1datao;                              -- ROME data output
    ROMO_DOUT     : in    t_rom1datao;                              -- ROMO data output

    -- debug -------------------------------------------------
    ODV           : out   std_logic;                                -- Output data valid
    DCTO          : out   std_logic_vector(OP_W - 1 downto 0);      -- DCT data output
    ----------------------------------------------------------
    ROME_ADDR     : out   t_rom1addro;                              -- ROME address output
    ROMO_ADDR     : out   t_rom1addro;                              -- ROMO address output
    RAM_WADDR     : out   std_logic_vector(RAMADRR_W - 1 downto 0); -- RAM write address output
    RAM_DIN       : out   std_logic_vector(RAMDATA_W - 1 downto 0); -- RAM data input
    RAM_WE        : out   std_logic;                                -- RAM write enable
    WMEMSEL       : out   std_logic                                 -- Write memory select signal
  );
end entity DCT1D;

----------------------------- ARCHITECTURE -------------------------------------

architecture RTL of DCT1D is

  --########################### CONSTANTS 1 ####################################

  --########################### TYPES ##########################################

  type input_data is array (N - 1 downto 0) of signed(IP_W downto 0);   -- NOTE: IP_W not IP_W-1, one bit extra

  type t_ram_waddr_delay is array (natural range <>) of std_logic_vector(RAMADRR_W - 1 downto 0);

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################

  signal databuf_reg         : input_data;
  signal latchbuf_reg        : input_data;
  signal col_cnt             : unsigned(RAMADRR_W / 2 - 1 downto 0);
  signal row_cnt             : unsigned(RAMADRR_W / 2 - 1 downto 0);
  signal inpt_cnt            : unsigned(RAMADRR_W / 2 - 1 downto 0);
  signal ram_we_s            : std_logic;
  signal wmemsel_reg         : std_logic;
  signal stage2_start        : std_logic;
  signal stage2_cnt          : unsigned(RAMADRR_W - 1 downto 0);        -- could be trasformed into: natural range (0 to N);
  signal col_cnt2            : unsigned(RAMADRR_W / 2 - 1 downto 0);
  signal ram_waddr_s         : std_logic_vector(RAMADRR_W - 1 downto 0);

  -- signal even_not_odd        : std_logic;
  -- signal even_not_odd_d1     : std_logic;
  -- signal even_not_odd_d2     : std_logic;
  -- signal even_not_odd_d3     : std_logic;
  signal is_even             : std_logic;                               -- if is_even = '1' then this stage in the pipeline is computing an even row, else, if '0' an odd one.
  signal is_even_d           : std_logic_vector(3 - 1 downto 0);

  -- signal ram_we_d1          : std_logic;
  -- signal ram_we_d2          : std_logic;
  -- signal ram_we_d3          : std_logic;
  -- signal ram_we_d4          : std_logic;
  signal ram_we_d            : std_logic_vector(4 - 1 downto 0);

  -- signal ram_waddr_d1        : std_logic_vector(RAMADRR_W - 1 downto 0);
  -- signal ram_waddr_d2        : std_logic_vector(RAMADRR_W - 1 downto 0);
  -- signal ram_waddr_d3        : std_logic_vector(RAMADRR_W - 1 downto 0);
  -- signal ram_waddr_d4        : std_logic_vector(RAMADRR_W - 1 downto 0);
  signal ram_waddr_d         : t_ram_waddr_delay (4 - 1 downto 0);

 -- signal wmemsel_d1          : std_logic;
 -- signal wmemsel_d2          : std_logic;
 -- signal wmemsel_d3          : std_logic;
 -- signal wmemsel_d4          : std_logic;
  signal wmemsel_d           : std_logic_vector(4 - 1 downto 0);

  signal rome_dout_d1        : t_rom1datao;
  signal romo_dout_d1        : t_rom1datao;
  signal rome_dout_d2        : t_rom1datao;
  signal romo_dout_d2        : t_rom1datao;
  signal rome_dout_d3        : t_rom1datao;
  signal romo_dout_d3        : t_rom1datao;
  signal dcto_1              : std_logic_vector(DA_W - 1 downto 0);
  signal dcto_2              : std_logic_vector(DA_W - 1 downto 0);
  signal dcto_3              : std_logic_vector(DA_W - 1 downto 0);
  signal dcto_4              : std_logic_vector(DA_W - 1 downto 0);

  --########################### ARCHITECTURE BEGIN #############################

begin

  --########################### ENTITY DEFINITION ##############################

  --########################## PROCESSES #######################################

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- combinational logic
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  --RAM_WADDR <= ram_waddr_d4;  
  RAM_WADDR <= ram_waddr_d(ram_waddr_d'length-1); -- 4 clock dealy

  -- RAM_WE    <= ram_we_d4;
  RAM_WE <= ram_we_d(ram_we_d'length - 1); -- 4 clock dealy
  -- ODV       <= ram_we_d4;
  ODV <= ram_we_d(ram_we_d'length - 1); -- 4 clock dealy

  RAM_DIN <= dcto_4(DA_W - 1 downto 12);
  DCTO    <= std_logic_vector(resize(signed(dcto_4(DA_W - 1 downto 12)), OP_W));

  --WMEMSEL <= wmemsel_d4;
  wmemsel <= wmemsel_d(wmemsel_d'length-1); -- 4 clock delay

  process (CLK, RST) is -- //TODO add label
  begin

    if (RST = '1') then
      inpt_cnt     <= (others => '0');
      latchbuf_reg <= (others => (others => '0'));
      databuf_reg  <= (others => (others => '0'));
      stage2_start <= '0';
      stage2_cnt   <= (others => '1');             -- NOTE: stage2_cnt starts from 63 because if 0 it triggers 2stage prematurely
      ram_we_s     <= '0';
      ram_waddr_s  <= (others => '0');
      col_cnt      <= (others => '0');
      row_cnt      <= (others => '0');
      wmemsel_reg  <= '0';
      col_cnt2     <= (others => '0');
    elsif (CLK = '1' and CLK'event) then
      stage2_start <= '0';
      ram_we_s     <= '0';

      --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      -- 1st stage
      --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      if (IDV = '1') then
        inpt_cnt <= inpt_cnt + 1;                  -- 0->7

        -- Input data is level shifted. This will range DC coeff to boundary 9 bits

        -- DCTI shift register: right shift input data
        latchbuf_reg(N - 2 downto 0) <= latchbuf_reg(N - 1 downto 1);
        latchbuf_reg(N - 1)          <= SIGNED('0' & DCTI) - LEVEL_SHIFT;

        if (inpt_cnt = N - 1) then
          -- after this sum databuf_reg is in range of -256 to 254 (min to max)
          databuf_reg(0) <= latchbuf_reg(1) + (SIGNED('0' & DCTI) - LEVEL_SHIFT);
          databuf_reg(1) <= latchbuf_reg(2) + latchbuf_reg(7);
          databuf_reg(2) <= latchbuf_reg(3) + latchbuf_reg(6);
          databuf_reg(3) <= latchbuf_reg(4) + latchbuf_reg(5);
          databuf_reg(4) <= latchbuf_reg(1) - (SIGNED('0' & DCTI) - LEVEL_SHIFT);
          databuf_reg(5) <= latchbuf_reg(2) - latchbuf_reg(7);
          databuf_reg(6) <= latchbuf_reg(3) - latchbuf_reg(6);
          databuf_reg(7) <= latchbuf_reg(4) - latchbuf_reg(5);
          stage2_start   <= '1';
        end if;
      end if;
      --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      -- 2nd stage
      --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      if (stage2_start = '1') then
        stage2_cnt <= (others => '0');

        -- row_cnt++ happens when col_cnt overloeads to 0 (see finished processing input row).
        -- So this needs to be triggered by logic and not by intialization, hence col_cnt starts from 1
        col_cnt <= (0=>'1', others => '0');

        col_cnt2 <= (others => '0');
      end if;

      if (stage2_cnt < N) then
        stage2_cnt <= stage2_cnt + 1;              -- theoretical 0->63, real 0->8

        -- write RAM
        ram_we_s <= '1';
        -- reverse col/row order for transposition purpose
        ram_waddr_s <= STD_LOGIC_VECTOR(col_cnt2 & row_cnt);
        -- increment column counter
        col_cnt  <= col_cnt + 1;                   -- 0->7
        col_cnt2 <= col_cnt2 + 1;                  -- 0->7

        -- finished processing one input row
        if (col_cnt = 0) then
          row_cnt <= row_cnt + 1;                  -- 0->7
          -- switch to 2nd memory
          if (row_cnt = N - 1) then
            wmemsel_reg <= not wmemsel_reg;
            col_cnt     <= (others => '0');
          end if;
        end if;
      end if;

      --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    end if;

  end process;

  -- output data pipeline
  P_DATA_OUT_PIPE : process (CLK, RST) is
  begin

    if (RST = '1') then
      -- even_not_odd    <= '0';
      -- even_not_odd_d1 <= '0';
      -- even_not_odd_d2 <= '0';
      -- even_not_odd_d3 <= '0';
      is_even   <= '0';
      is_even_d <= (others => '0');

      -- ram_we_d1 <= '0';
      -- ram_we_d2 <= '0';
      -- ram_we_d3 <= '0';
      -- ram_we_d4 <= '0';
      ram_we_d <= (others => '0');

      -- ram_waddr_d1 <= (others => '0');
      -- ram_waddr_d2 <= (others => '0');
      -- ram_waddr_d3 <= (others => '0');
      -- ram_waddr_d4 <= (others => '0');
      ram_waddr_d  <= (others => (others => '0'));

      --wmemsel_d1 <= '0';
      --wmemsel_d2 <= '0';
      --wmemsel_d3 <= '0';
      --wmemsel_d4 <= '0';
      wmemsel_d  <= (others => '0');

      dcto_1 <= (others => '0');
      dcto_2 <= (others => '0');
      dcto_3 <= (others => '0');
      dcto_4 <= (others => '0');
    elsif (CLK'event and CLK = '1') then
      -- even_not_odd    <= stage2_cnt(0);
      -- even_not_odd_d1 <= even_not_odd;
      -- even_not_odd_d2 <= even_not_odd_d1;
      -- even_not_odd_d3 <= even_not_odd_d2;

      -- stge2_cnt(0) represents even (=0) or odd (=1) row computation in the pipeline
      is_even <= not stage2_cnt(0);

      -- Is even delay with shift register
      is_even_d(is_even_d'length - 1 downto 1) <= is_even_d(is_even_d'length - 2 downto 0);
      is_even_d(0)                             <= is_even;

      -- ram_we_d1 <= ram_we_s;
      -- ram_we_d2 <= ram_we_d1;
      -- ram_we_d3 <= ram_we_d2;
      -- ram_we_d4 <= ram_we_d3;

      ram_we_d(ram_we_d'length - 1 downto 1 ) <= ram_we_d(ram_we_d'length - 2 downto 0);
      ram_we_d(0)                             <= ram_we_s;

      -- ram_waddr_d1 <= ram_waddr_s;
      -- ram_waddr_d2 <= ram_waddr_d1;
      -- ram_waddr_d3 <= ram_waddr_d2;
      -- ram_waddr_d4 <= ram_waddr_d3;

      ram_waddr_d(ram_waddr_d'length - 1 downto 1) <= ram_waddr_d(ram_waddr_d'length - 2 downto 0);
      ram_waddr_d(0)                               <= ram_waddr_s;

      -- wmemsel_d1 <= wmemsel_reg;
      -- wmemsel_d2 <= wmemsel_d1;
      -- wmemsel_d3 <= wmemsel_d2;
      -- wmemsel_d4 <= wmemsel_d3;

      wmemsel_d (wmemsel_d'length - 1 downto 1) <= wmemsel_d(wmemsel_d'length - 2 downto 0);
      wmemsel_d(0)                              <= wmemsel_reg;

      -- if (even_not_odd = '0') then
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

      -- if (even_not_odd_d1 = '0') then
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

      -- if (even_not_odd_d2 = '0') then
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

      -- if (even_not_odd_d3 = '0') then
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
                        databuf_reg(0)(i) &
                        databuf_reg(1)(i) &
                        databuf_reg(2)(i) &
                        databuf_reg(3)(i);
        -- odd
        ROMO_ADDR(i) <= STD_LOGIC_VECTOR(col_cnt(RAMADRR_W / 2 - 1 downto 1)) &
                        databuf_reg(4)(i) &
                        databuf_reg(5)(i) &
                        databuf_reg(6)(i) &
                        databuf_reg(7)(i);
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
