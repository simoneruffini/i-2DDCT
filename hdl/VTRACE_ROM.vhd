--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
-- Create Date:     Mon Sep  6 17:13:25 CEST 2021
-- Design Name:     VTRACE_ROM
-- Module Name:     VTRACE_ROM.vhd - Behavioral
-- Project Name:    i-2DDCT
-- Description:     Voltage Trace ROM for INT_EMU
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
  use IEEE.MATH_REAL.all;

----------------------------- ENTITY -------------------------------------------

entity VTRACE_ROM is
  generic (
    NUM_ELEMENTS_ROM : integer
  );
  port (
    CLK     : in    std_logic;
    RADDR   : in    natural range 0 to NUM_ELEMENTS_ROM - 1;
    DOUT    : out   integer
  );
end entity VTRACE_ROM;

----------------------------- ARCHITECTURE -------------------------------------

architecture BEHAVIORAL of VTRACE_ROM is

  --########################### CONSTANTS 1 ####################################
  constant C_MAX_VOLTAGE     : real := 3.3;
  constant C_START_DISCHARGE : real := 0.05;

  constant C_TRACE_DURATION  : natural := 5;

  constant C_STEP            : real := real(C_TRACE_DURATION) / real(NUM_ELEMENTS_ROM);

  --########################### TYPES ##########################################

  type rom_t is array (0 to NUM_ELEMENTS_ROM - 1) of integer;

  --########################### FUNCTIONS ######################################

  function trace_function (x : real) return real is
  begin

    if (x < C_START_DISCHARGE) then
      return C_MAX_VOLTAGE;
    elsif (x >= C_START_DISCHARGE AND x < (C_START_DISCHARGE + 1.0)) then
      return C_MAX_VOLTAGE * EXP(-x + C_START_DISCHARGE);
    else
      return C_MAX_VOLTAGE * (1.0 - EXP(-x + (C_START_DISCHARGE + 0.5)));
    end if;

  end function;

  impure function generate_trace return rom_t is
    variable vtrace_rom : rom_t;
  begin
    for i in 0 to NUM_ELEMENTS_ROM - 1 loop
      vtrace_rom(i) := integer(ceil(1000.0 * trace_function(C_STEP * i)));
    end loop;
    return vtrace_rom;
  end function;

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################

  signal rom                 : rom_t := generate_trace;

  --########################### ARCHITECTURE BEGIN #############################

begin

  --########################### ENTITY DEFINITION ##############################

  --########################## OUTPUT PORTS WIRING #############################

  --########################## COBINATORIAL FUNCTIONS ##########################

  --########################## PROCESSES #######################################

  P_OUTPUT : process (clk) is
  begin

    if (clk'event and clk = '1') then
      DOUT <= rom(RADDR);  --get the address read it as unsigned and convert to integer to get the value from ROM(integer)
    end if;

  end process P_OUTPUT;

end architecture BEHAVIORAL;
