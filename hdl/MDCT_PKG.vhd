--------------------------------------------------------------------------------
--                                                                            --
--                          V H D L    F I L E                                --
--                          COPYRIGHT (C) 2006                                --
--                                                                            --
--------------------------------------------------------------------------------
--
-- Title       : MDCT_PKG
-- Design      : MDCT Core
-- Author      : Michal Krepa
--
--------------------------------------------------------------------------------
--
-- File        : MDCT_PKG.VHD
-- Created     : Sat Mar 5 2006
--
--------------------------------------------------------------------------------
--
--  Description : Package for MDCT core
--
--------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use ieee.numeric_std.all;
  
package MDCT_PKG is

  -- //TODO: change all this constatns to G_C_constant_name
  constant IP_W                 : INTEGER := 8;  -- Input data width
  constant OP_W                 : INTEGER := 12; -- Output data width 
  constant N                    : INTEGER := 8;
  constant COE_W                : INTEGER := 12; -- MDCT output entity width
  constant ROMDATA_W            : INTEGER := COE_W+2; -- ROM data width
  constant ROMADDR_W            : INTEGER := 6; -- ROM address width
  constant RAMDATA_W            : INTEGER := 10; -- RAM data width
  constant RAMADRR_W            : INTEGER := 6; -- RAM address width
  constant COL_MAX              : INTEGER := N-1; -- // TODO remove not used
  constant ROW_MAX              : INTEGER := N-1; -- // TODO remove not used
  constant LEVEL_SHIFT          : INTEGER := 128; -- probably (2^8)/2
  constant DA_W                 : INTEGER := ROMDATA_W+IP_W; -- dct1d output width
  constant DA2_W                : INTEGER := DA_W+2; --dct 2d output width
  -- 2's complement numbers

	constant AP : INTEGER := 1448;
	constant BP : INTEGER := 1892;
	constant CP : INTEGER := 784;
	constant DP : INTEGER := 2009;
	constant EP : INTEGER := 1703;
	constant FP : INTEGER := 1138;
	constant GP : INTEGER := 400;
	constant AM : INTEGER := -1448;
	constant BM : INTEGER := -1892;
	constant CM : INTEGER := -784;
	constant DM : INTEGER := -2009;
	constant EM : INTEGER := -1703;
	constant FM : INTEGER := -1138;
	constant GM : INTEGER := -400;
	
  type T_ROM1DATAO  is array(0 to 8) of STD_LOGIC_VECTOR(ROMDATA_W-1 downto 0);
  type T_ROM1ADDRO  is array(0 to 8) of STD_LOGIC_VECTOR(ROMADDR_W-1 downto 0);
  
  type T_ROM2DATAO  is array(0 to 10) of STD_LOGIC_VECTOR(ROMDATA_W-1 downto 0);
  type T_ROM2ADDRO  is array(0 to 10) of STD_LOGIC_VECTOR(ROMADDR_W-1 downto 0);
  

end MDCT_PKG;