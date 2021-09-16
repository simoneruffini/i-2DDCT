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
  use IEEE.MATH_REAL.all;

package i_2ddct_pkg is

  function max (x: integer; y:integer) return integer;

  function ilog2 (x: natural) return natural;

  -- Input data width
  constant C_INDATA_W : natural := 8;

  constant C_PRECISION : natural := 11;
  constant C_DYNAMIC_RANGE : natural := C_PRECISION + 1; -- (12) [-2^11,2^11-1]

  -- I DCT1S output data width
  constant C_1S_OUTDATA_W : natural := 10;
  -- Output data width
  constant C_OUTDATA_W : natural := 12; -- = C_DYNAMIC_RANGE
  -- Input block base size
  constant N : natural := 8;

  -- Number of data (words) in each rom
  constant C_ROM_SIZE : natural := 64;

  -- Size of a full block of data
  constant C_BLOCK_SIZE : natural := N * N;                                                            --(64)
  -- Size of DCT1S/2S checkpoint in RAM: DBUF + ROW_COL
  constant C_DCTxS_CHKPNT_RAM_SIZE : natural := N + 1;                                                 --(9)
  -- Amount of content inside RAM (number of words)
  constant C_RAM_CONTENT_AMOUNT : natural := C_BLOCK_SIZE + C_DCTxS_CHKPNT_RAM_SIZE;                   --(73)
  -- Amount of data to store inside NVM w.r.t RAM
  constant C_CHKPNT_NVM_RAM_AMOUNT : natural := C_RAM_CONTENT_AMOUNT;                                  --(73)
  -- Amount of data to store inside NVM w.r.t DBUFCTL
  constant C_CHKPNT_NVM_DBUFCTL_AMOUNT : natural := 1;                                                 --(1)
  -- Size of a system checkpoint (number of words): 1 data in DBUFCTL, 1 RAM size.
  constant C_CHKPNT_NVM_SYS_AMOUNT : natural := C_CHKPNT_NVM_DBUFCTL_AMOUNT + C_CHKPNT_NVM_RAM_AMOUNT; --(74)

  -- ROM data width
  constant C_ROMDATA_W : natural := C_OUTDATA_W + 2;   --(14) 
  -- +2 meaming:
  -- In the rom some constants are multiplied by 4, in the worst case scenario
  -- such constant could be 2^C_DYNAMIC_RANGE, hence if multiplied by 4:
  -- log2(2^C_DYNAMIC_RANGE*4)=log2(2^C_DYNAMIC_RANGE * 2^2) = C_DYNAMIC_RANGE + 2 

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
  -- xP positive value of x
  -- xN negative value of x
  constant AP : integer := integer(ROUND(COS(MATH_PI / 4.0)     * 2 ** C_PRECISION));  -- (1448)
  constant BP : integer := integer(ROUND(COS(MATH_PI / 8.0)     * 2 ** C_PRECISION));  -- (1892)
  constant CP : integer := integer(ROUND(COS(3 * MATH_PI / 8.0) * 2 ** C_PRECISION));  -- (784)
  constant DP : integer := integer(ROUND(COS(MATH_PI / 16.0)    * 2 ** C_PRECISION));  -- (2009)
  constant EP : integer := integer(ROUND(COS(3 * MATH_PI / 16.0) * 2 ** C_PRECISION)); -- (1703) 
  constant FP : integer := integer(ROUND(COS(5 * MATH_PI / 16.0) * 2 ** C_PRECISION)); -- (1138) 
  constant GP : integer := integer(ROUND(COS(7 * MATH_PI / 16.0) * 2 ** C_PRECISION)); -- (400) 
  constant AN : integer := -1*AP; -- (-1448)
  constant BN : integer := -1*BP; -- (-1892)
  constant CN : integer := -1*CP; -- (-784)
  constant DN : integer := -1*DP; -- (-2009)
  constant EN : integer := -1*EP; -- (-1703)
  constant FN : integer := -1*FP; -- (-1138)
  constant GN : integer := -1*GP; -- (-400) 

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
