--------------------------------------------------------------------------------
-- Engineer: Michal Krepa 
--           Simone Ruffini [simone.ruffini@tutanota.com]
--
--
-- Create Date:     Sat Mar 5 7:37 2006
-- Design Name:     RAM
-- Module Name:     RAM.vhd - RTL
-- Project Name:    iMDCT
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

-- User libraries

----------------------------- ENTITY -------------------------------------------
entity RAM is
  generic (
    DATA_W : natural;
    ADDR_W : natural
  );
  port (
    D                 : in    std_logic_vector(DATA_W - 1 downto 0);
    WADDR             : in    std_logic_vector(ADDR_W - 1 downto 0);
    RADDR             : in    std_logic_vector(ADDR_W - 1 downto 0);
    WE                : in    std_logic;
    CLK               : in    std_logic;
    Q                 : out   std_logic_vector(DATA_W - 1 downto 0)
  );
end entity RAM;

----------------------------- ARCHITECTURE -------------------------------------


architecture RTL of RAM is

  --########################### CONSTANTS 1 ####################################

  --########################### TYPES ##########################################

  type mem_type is array ((2 ** ADDR_W) - 1 downto 0) of std_logic_vector(DATA_W - 1 downto 0);

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################

  signal mem                    : mem_type;
  signal read_addr              : std_logic_vector(ADDR_W - 1 downto 0);

  --########################### ARCHITECTURE BEGIN #############################

begin

  --########################### ENTITY DEFINITION ##############################

  --########################## OUTPUT PORTS WIRING #############################
  Q <= mem(to_integer(unsigned(read_addr)));

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
        mem(to_integer(unsigned(WADDR))) <= D;
      end if;
    end if;

  end process P_WRITE;

end architecture RTL;
--------------------------------------------------------------------------------
