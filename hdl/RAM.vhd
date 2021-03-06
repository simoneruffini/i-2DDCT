--------------------------------------------------------------------------------
-- Engineer: Michal Krepa
--           Simone Ruffini [simone.ruffini@tutanota.com]
--
--
-- Create Date:     Sat Mar 5 7:37 2006
-- Design Name:     RAM
-- Module Name:     RAM.vhd - RTL
-- Project Name:    i-2DDCT
-- Description:     RAM
--
-- Revision:
-- Revision 00 - Michal Krepa
--  * File Creation
-- Revision 01 - Simone Ruffini
--  * Refactoring and generics
-- Additional Comments:
--
--------------------------------------------------------------------------------

----------------------------- PACKAGES/LIBRARIES -------------------------------
-- 5:3 row select
-- 2:0 col select

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;
  use IEEE.STD_LOGIC_TEXTIO.all; --synopsis

library STD;
  use STD.TEXTIO.all;

-- User libraries

----------------------------- ENTITY -------------------------------------------

entity RAM is
  generic (
    DATA_W : natural;
    ADDR_W : natural
  );
  port (
    DIN                  : in    std_logic_vector(DATA_W - 1 downto 0);
    WADDR                : in    std_logic_vector(ADDR_W - 1 downto 0);
    RADDR                : in    std_logic_vector(ADDR_W - 1 downto 0);
    WE                   : in    std_logic;
    CLK                  : in    std_logic;
    DOUT                 : out   std_logic_vector(DATA_W - 1 downto 0)
  );
end entity RAM;

----------------------------- ARCHITECTURE -------------------------------------

architecture RTL of RAM is

  --########################### CONSTANTS 1 ####################################

  --########################### TYPES ##########################################

  type mem_type is array ((2 ** ADDR_W) - 1 downto 0) of std_logic_vector(DATA_W - 1 downto 0);

  --########################### FUNCTIONS ######################################

  -- Takes 32 hexadecimal values from RamFileName  and returns an array of them
  -- NOTE: values must be 32bit hex

  impure function initramfromfile (RamFileName : in string) return mem_type is
    file     RamFile     : text is in RamFileName;
    variable ramfileline : line;
    variable tmpword     : std_logic_vector(31 downto 0);
    variable ram         : mem_type;
  begin
    for I in 0 to (2 ** ADDR_W) - 1 loop
      readline (RamFile, ramfileline);
      hread(ramfileline, tmpword);
      ram(i) := std_logic_vector(resize(unsigned(tmpword), DATA_W));

    end loop;
    return ram;
  end function;

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################

  signal mem                    : mem_type; --:= initramfromfile("ramInit10bit.txt");
  signal read_addr              : std_logic_vector(ADDR_W - 1 downto 0);

  --########################### ARCHITECTURE BEGIN #############################

begin

  --########################### ENTITY DEFINITION ##############################

  --########################## OUTPUT PORTS WIRING #############################
  DOUT <= mem(to_integer(unsigned(read_addr)));

  --########################## COBINATORIAL FUNCTIONS ##########################

  --########################## PROCESSES #######################################

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- register read address
  P_READ : process (CLK) is
  begin

    if (CLK = '1' and CLK'event) then
      read_addr <= RADDR;
    end if;

  end process P_READ;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- write access
  P_WRITE : process (CLK) is
  begin

    if (CLK = '1' and CLK'event) then
      if (WE = '1') then
        mem(to_integer(unsigned(WADDR))) <= DIN;
      end if;
    end if;

  end process P_WRITE;

end architecture RTL;

--------------------------------------------------------------------------------
