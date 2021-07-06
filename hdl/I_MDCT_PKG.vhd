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
  use ieee.NUMERIC_STD.all;

package i_mdct_pkg is

  function max (x: integer, y:integer) return integer;

  -- //TODO: change all this constatns to G_C_constant_name
  constant C_INDATA_W        : natural := 8;  -- Input data width
  constant C_OUTDATA_W       : natural := 12; -- Output data width
  constant N                    : natural := 8;
  constant COE_W                : natural := 12; -- MDCT output entity width
  constant ROMDATA_W            : natural := COE_W + 2; -- ROM data width
  constant ROMADDR_W            : natural := 6; -- ROM address width
  constant RAMDATA_W            : natural := 10; -- RAM data width
  constant RAMADRR_W            : natural := 6; -- RAM address width
  constant COL_MAX              : natural := N - 1; -- // TODO remove not used
  constant ROW_MAX              : natural := N - 1; -- // TODO remove not used
  constant LEVEL_SHIFT          : natural := 128; -- probably (2^8)/2
  constant DA_W                 : natural := ROMDATA_W + IP_W; -- dct1d output width
  constant DA2_W                : natural := DA_W + 2; --dct 2d output width
  constant C_BUSDATA_W : natural := 32;
  ------------------------------------------------------------------------------
  constant NVM_DATA_W : natural := max(RAMDATA_W, C_INDATA_W);
  constant NVM_ADDR_W : natural := (RAMADDR_W + N + 1)*2;

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

  type t_rom1datao is array(0 to 8) of STD_LOGIC_VECTOR(ROMDATA_W - 1 downto 0);

  type t_rom1addro is array(0 to 8) of STD_LOGIC_VECTOR(ROMADDR_W - 1 downto 0);

  type t_rom2datao is array(0 to 10) of STD_LOGIC_VECTOR(ROMDATA_W - 1 downto 0);

  type t_rom2addro is array(0 to 10) of STD_LOGIC_VECTOR(ROMADDR_W - 1 downto 0);

end package i_mdct_pkg;

package body i_mdct_pkg is

  function max (x: integer, y:integer) return integer is
  begin

    if (x>y) then
      return x;
    else
      return y;
    end if;

  end max;

end package body i_mdct_pkg;
