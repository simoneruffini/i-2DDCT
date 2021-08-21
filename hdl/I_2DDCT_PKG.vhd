--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
--
-- Create Date:     Wed Jun  9 14:39:11 CEST 2021
-- Design Name:     I_2DDCT_PKG
-- Module Name:     I_2DDCT_PKG.vhd
-- Project Name:    i-2DDCT
-- Description:     Package for Intermittent 2DDCT core
--
-- Revision:
-- Revision 00 - Simone Ruffini
--  * File Created
-- Additional Comments:
--
--------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;
  use IEEE.math_real.all;

package i_2ddct_pkg is

  function max (x: integer; y:integer) return integer;

  function ilog2 (x: natural) return natural;

  -- Input data width
  constant C_INDATA_W : natural := 8;
  -- I DCT1S output data width
  constant C_1S_OUTDATA_W : natural := 10;
  -- Output data width
  constant C_OUTDATA_W : natural := 12;
  -- Input frame base size
  constant N : natural := 8;

  -- Number of data (words) in each rom
  constant C_ROM_SIZE : natural := 64;

  -- Size of a full frame of data
  constant C_FRAME_SIZE : natural := N * N;                                                            --(64)
  -- Size of DCT1S checkpoint in RAM: DBUF + ROW_COL
  constant C_DCT1S_CHKPNT_RAM_SIZE : natural := N + 1;                                                 --(9)
  -- Amount of content inside RAM (number of words)
  constant C_RAM_CONTENT_AMOUNT : natural := C_FRAME_SIZE + C_DCT1S_CHKPNT_RAM_SIZE;                   --(73)
  -- Amount of data to store inside NVM w.r.t RAM
  constant C_CHKPNT_NVM_RAM_AMOUNT : natural := C_RAM_CONTENT_AMOUNT;                                  --(73)
  -- Amount of data to store inside NVM w.r.t DBUFCTL
  constant C_CHKPNT_NVM_DBUFCTL_AMOUNT : natural := 1;                                                 --(1)
  -- Size of a system checkpoint (number of words): 1 data in DBUFCTL, 1 RAM size.
  constant C_CHKPNT_NVM_SYS_AMOUNT : natural := C_CHKPNT_NVM_DBUFCTL_AMOUNT + C_CHKPNT_NVM_RAM_AMOUNT; --(74)

  -- ROM data width
  constant C_ROMDATA_W : natural := C_OUTDATA_W + 2;   --(14)
  -- ROM address width
  constant C_ROMADDR_W : natural := ilog2(C_ROM_SIZE); --(6)

  -- RAM data width
  constant C_RAMDATA_W : natural := C_1S_OUTDATA_W;              --(10)
  -- RAM address width
  constant C_RAMADDR_W : natural := ilog2(C_RAM_CONTENT_AMOUNT); --(7)

  -- Input value shift constant: from positive range [0,255] to one centered on zero [-128,127]
  constant LEVEL_SHIFT : natural := (2 ** N) / 2;              --(128)
  -- Pipeline 1S data width
  constant C_PL1_DATA_W : natural := C_ROMDATA_W + C_INDATA_W; --(22)
  -- Pipeline 2S data width
  constant C_PL2_DATA_W : natural := C_PL1_DATA_W + 2;         --(24)

  ------------------------------------------------------------------------------
  -- NVM constants
  ------------------------------------------------------------------------------
  constant C_NVM_DATA_W : natural := max(C_RAMDATA_W * 2, C_INDATA_W);
  constant C_NVM_ADDR_W : natural := ilog2(C_CHKPNT_NVM_SYS_AMOUNT);

  -- WARNING: keep this constant equal to the system speed
  constant C_CLK_FREQ_HZ : natural := 100000000; -- 100MHz master clk speed.

  -- NVM access time
  -- See https://www.cypress.com/file/46186/download FRAM-Technology brief
  -- and https://www.cypress.com/file/136446/download page 9 tRC ~ 130ns
  constant C_NV_MEM_ACCESS_TIME_NS : positive := 50; --130;

  -- 2's complement numbers
  -- xP positive/plus value of x
  -- xM negative/minus value of x
  constant AP : integer := 1448;   -- round(cos(pi/4)*(2^11))
  constant BP : integer := 1892;   -- round(cos(pi/8)*(2^11))
  constant CP : integer := 784;    -- round(sin(pi/8)*(2^11))
  constant DP : integer := 2009;   -- round(cos(pi/16)*(2^11))
  constant EP : integer := 1703;   -- round(cos(3*pi/16)*(2^11))
  constant FP : integer := 1138;   -- round(sin(3*pi/16)*(2^11))
  constant GP : integer := 400;    -- round(sin(pi/16)*(2^11))
  constant AM : integer := - 1448; -- -1* round(cos(pi/4)*(2^11))
  constant BM : integer := - 1892; -- -1* round(cos(pi/8)*(2^11))
  constant CM : integer := - 784;  -- -1* round(sin(pi/8)*(2^11))
  constant DM : integer := - 2009; -- -1* round(cos(pi/16)*(2^11))
  constant EM : integer := - 1703; -- -1* round(cos(3*pi/16)*(2^11))
  constant FM : integer := - 1138; -- -1* round(sin(3*pi/16)*(2^11))
  constant GM : integer := - 400;  -- -1* round(sin(pi/16)*(2^11))

  type sys_status_t is (
    SYS_RUN,
    SYS_PUSH_CHKPNT_NV2V,
    SYS_VARC_INIT_CHKPNT,
    SYS_VARC_PREP_CHKPNT,
    SYS_PUSH_CHKPNT_V2NV,
    SYS_HALT
  );

  type sys_enrg_status_t is (
    sys_enrg_hazard, -- [2.5 - 2.8]V
    sys_enrg_ok      -- [2.8 - >3.0]V
  );

  type rom1_data_t is array(0 to 8) of STD_LOGIC_VECTOR(C_ROMDATA_W - 1 downto 0);

  type rom1_addr_t is array(0 to 8) of STD_LOGIC_VECTOR(C_ROMADDR_W - 1 downto 0);

  type rom2_data_t is array(0 to 10) of STD_LOGIC_VECTOR(C_ROMDATA_W - 1 downto 0);

  type rom2_addr_t is array(0 to 10) of STD_LOGIC_VECTOR(C_ROMADDR_W - 1 downto 0);

end package i_2ddct_pkg;

package body i_2ddct_pkg is

  function max (x: integer; y:integer) return integer is
  begin

    if (x>y) then
      return x;
    else
      return y;
    end if;

  end max;

  function ilog2 (x:natural) return natural is
    -- Integer log2 (returs always the ceiling of the log2)
  begin
    return natural(ceil(log2(real(x))));
  end function;

end package body i_2ddct_pkg;
