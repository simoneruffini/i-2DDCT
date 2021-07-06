--------------------------------------------------------------------------------
-- Company:
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
--
-- Create Date:     Wed Jun 30 23:43:08 CEST 2021
-- Design Name:     PBSM
-- Module Name:     PBSM.vhd - RTL
-- Project Name:    iMDCT
-- Description:     Process Block State Machine used to control consecutive processes
--
-- Revision:
-- Revision 00 - Simone Ruffini
--  * Refactoring + comments
-- Additional Comments:
--
--------------------------------------------------------------------------------

----------------------------- PACKAGES/LIBRARIES -------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;

----------------------------- ENTITY -------------------------------------------

entity PBSM is
  port (
    CLK                : in    std_logic;
    RST                : in    std_logic;
    -- from/to PBSM(m-1)
    START_I            : in    std_logic;
    -- from/to PBSM(m+1)
    START_O            : out   std_logic;
    -- from/to processing block
    PB_RDY_I           : in    std_logic;
    PB_START_O         : out   std_logic
  );
end entity PBSM ;

----------------------------- ARCHITECTURE -------------------------------------

architecture RTL of PBSM is

  --########################### CONSTANTS 1 ####################################

  --########################### TYPES ##########################################

  type state_t is (S_INIT, S_WAIT_START, S_WAIT_BLK_RDY);

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ##########################################

  signal pres_state : state_t;
  signal fut_state  : state_t;

  --########################### ARCHITECTURE BEGIN ###############################

begin

  --########################### COMBINATORIAL LOGIC ##############################

  --########################### PROCESSES ########################################

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- sequential process for fsm (synthesized FFs)

  P_FSM_SEQ : process (CLK, RST) is
  begin

    if (RST = '1') then
      pres_state <= S_INIT;
    elsif (CLK'event and CLK = '1') then
      pres_state <= fut_state;
    end if;

  end process P_FSM_SEQ;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Future state computation for fsm (combinatorial process)

  P_FSM_FUT_S : process (pres_state, START_I, PB_RDY_I) is
  begin

    case pres_state is

      when S_INIT =>
        fut_state <= S_WAIT_START;
      when S_WAIT_START =>

        if (START_I = '1') then
          fut_state <= S_WAIT_BLK_RDY;
        end if;

      when S_WAIT_BLK_RDY =>

        if (PB_RDY_I = '1') then
          fut_state <= S_INIT;
        end if;

    end case;

  end process P_FSM_FUT_S;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Output generator for a mealy fsm (output depends on input)

  P_FSM_OUTPS : process (pres_state, START_I, PB_RDY_I) is
  begin

    -- defaults
    -- By defining them the synthesizer produces a combinatrial logic without FFs
    PB_START_O <= '0';
    START_O    <= '0';

    case pres_state is

      when S_INIT =>
      when S_WAIT_START =>

        if (START_I = '1') then
          PB_START_O <= '0';
        end if;

      when S_WAIT_BLK_RDY =>

        if (PB_RDY_I = '1') then
          START_O <= '1';
        end if;

    end case;

  end process P_FSM_OUTPS;

end architecture RTL;
