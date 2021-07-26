--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
--
-- Create Date:     Wed Jun  9 14:39:11 CEST 2021
-- Design Name:     I_MDCT_PKG
-- Module Name:     I_MDCT_PKG.vhd
-- Project Name:    iMDCT
-- Description:     Package for Intermittent MDCT core
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

package i_mdct_pkg is

  function max (x: integer; y:integer) return integer;

  function ilog2 (x: natural) return natural;

  constant C_INDATA_W     : natural := 8;  -- Input data width
  constant C_1D_OUTDATA_W : natural := 10; -- I DCT1D output data width
  constant C_OUTDATA_W    : natural := 12; -- Output data width
  constant N              : natural := 8;  -- Input frame base size

  constant C_ROM_SIZE : natural := 64; -- Number of data (words) in each rom

  constant C_FRAME_SIZE        : natural := N * N; -- Size of a full frame of data
  constant C_DCT1D_CHKPNT_SIZE : natural := N + 1; -- Size of DCT1D checkpoint in RAM: DBUF + ROW_COL

  constant C_RAM_SIZE       : natural := C_FRAME_SIZE + C_DCT1D_CHKPNT_SIZE; -- Size of RAM (number of words)
  constant C_SYS_CHKPT_SIZE : natural := (C_RAM_SIZE * 2) + 1;               -- Size of a system checkpoint (number of words): 2 RAM sizes and data in DBUFCTL

  constant C_ROMDATA_W : natural := C_OUTDATA_W + 2;   -- ROM data width
  constant C_ROMADDR_W : natural := ilog2(C_ROM_SIZE); -- ROM address width

  constant C_RAMDATA_W : natural := C_1D_OUTDATA_W;    -- RAM data width
  constant C_RAMADDR_W : natural := ilog2(C_RAM_SIZE); -- RAM address width

  constant LEVEL_SHIFT  : natural := 128;                      -- probably (2^8)/2
  constant C_PL1_DATA_W : natural := C_ROMDATA_W + C_INDATA_W; -- Pipeline 1D data width
  constant C_PL2_DATA_W : natural := C_PL1_DATA_W + 2;         -- Pipeline 2D data width
  ------------------------------------------------------------------------------
  constant NVM_DATA_W : natural := max(C_RAMDATA_W, C_INDATA_W);
  constant NVM_ADDR_W : natural := (C_RAMADDR_W  * 2) + 1;     --


  -- 2's complement numbers

  constant AP : integer := 1448;
  constant BP : integer := 1892;
  constant CP : integer := 784;
  constant DP : integer := 2009;
  constant EP : integer := 1703;
  constant FP : integer := 1138;
  constant GP : integer := 400;
  constant AM : integer := - 1448;
  constant BM : integer := - 1892;
  constant CM : integer := - 784;
  constant DM : integer := - 2009;
  constant EM : integer := - 1703;
  constant FM : integer := - 1138;
  constant GM : integer := - 400;

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
    sys_enrg_wrng,   -- [2.8 -3.0]V
    sys_enrg_ok      -- [3.0 - ...]V
  );

  type rom1_data_t is array(0 to 8) of STD_LOGIC_VECTOR(C_ROMDATA_W - 1 downto 0);

  type rom1_addr_t is array(0 to 8) of STD_LOGIC_VECTOR(C_ROMADDR_W - 1 downto 0);

  type rom2_data_t is array(0 to 10) of STD_LOGIC_VECTOR(C_ROMDATA_W - 1 downto 0);

  type rom2_addr_t is array(0 to 10) of STD_LOGIC_VECTOR(C_ROMADDR_W - 1 downto 0);

end package i_mdct_pkg;

package body i_mdct_pkg is

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

end package body i_mdct_pkg;
