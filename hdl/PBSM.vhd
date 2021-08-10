--------------------------------------------------------------------------------
-- Company:
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
--
-- Create Date:     Wed Jun 30 23:43:08 CEST 2021
-- Design Name:     PBSM
-- Module Name:     PBSM.vhd - RTL
-- Project Name:    i-MDCT
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
    CLK                : in    std_logic; -- System Clock
    RST                : in    std_logic; -- System Reset (active high)
    NVM_BUSY_SIG       : in    std_logic; -- NVM busy signal (for async processes)
    -- from/to PBSM(m-1)
    START_I            : in    std_logic; -- Start this process block state machine
    -- from/to PBSM(m+1)
    START_O            : out   std_logic; -- Start next process block state machine
    -- from/to processing block
    PB_RDY_I           : in    std_logic; -- Redy signal from process block: '0' when PB is computing '1' otherwise
    PB_START_O         : out   std_logic  -- Start process block tied to this State Machine
  );
end entity PBSM;

----------------------------- ARCHITECTURE -------------------------------------

architecture RTL of PBSM is

  --########################### CONSTANTS 1 ####################################

  --########################### TYPES ##########################################

  type pbsm_state_t is (S_PBSM_WAIT_START, S_PBSM_WAIT_NVM_BUSY, S_PBSM_START_O, S_PBSM_RUN, S_PBSM_WAIT_BLK_RDY);

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ##########################################

  signal pbsm_pstate  : pbsm_state_t;
  signal pbsm_fstate  : pbsm_state_t;

  --########################### ARCHITECTURE BEGIN ###############################

begin

  --########################### COMBINATORIAL LOGIC ##############################

  --########################### PROCESSES ########################################

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- sequential process for fsm (synthesizes FFs)

  P_FSM_SEQ : process (CLK, RST) is
  begin

    if (RST = '1') then
      pbsm_pstate <= S_PBSM_WAIT_START;
    elsif (CLK'event and CLK = '1') then
      pbsm_pstate <= pbsm_fstate;
    end if;

  end process P_FSM_SEQ;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Future state computation for fsm (combinatorial process)

  P_FSM_FUT_S : process (pbsm_pstate, START_I, PB_RDY_I, NVM_BUSY_SIG) is
  begin

    -- Default
    pbsm_fstate <= pbsm_pstate;

    case pbsm_pstate is

      when S_PBSM_WAIT_START =>

        if (START_I = '1') then
          if (NVM_BUSY_SIG = '1') then
            pbsm_fstate <= S_PBSM_WAIT_NVM_BUSY;
          elsif (PB_RDY_I = '1') then
            pbsm_fstate <= S_PBSM_START_O;
          else
            pbsm_fstate <= S_PBSM_WAIT_BLK_RDY;
          end if;
        end if;

      when S_PBSM_WAIT_NVM_BUSY =>

        if (NVM_BUSY_SIG = '1') then
          pbsm_fstate <= S_PBSM_WAIT_NVM_BUSY;
        elsif (PB_RDY_I = '1') then
          pbsm_fstate <= S_PBSM_START_O;
        else
          pbsm_fstate <= S_PBSM_WAIT_BLK_RDY;
        end if;

      when S_PBSM_WAIT_BLK_RDY =>

        if (PB_RDY_I = '1') then
          pbsm_fstate <= S_PBSM_RUN;
        end if;

      when S_PBSM_START_O =>
        pbsm_fstate <= S_PBSM_RUN;

      when S_PBSM_RUN =>

        if (PB_RDY_I = '1') then
          pbsm_fstate <= S_PBSM_WAIT_START;
        end if;

    end case;

  end process P_FSM_FUT_S;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Output generator for a mealy fsm (output depends on input)

  P_FSM_OUTPS : process (pbsm_pstate,  PB_RDY_I) is
  begin

    -- defaults
    -- By defining them the synthesizer produces a combinatrial logic without FFs
    PB_START_O <= '0';
    START_O    <= '0';

    case pbsm_pstate is

      when S_PBSM_WAIT_START =>
      when S_PBSM_WAIT_NVM_BUSY =>
      when S_PBSM_WAIT_BLK_RDY =>
      when S_PBSM_START_O =>
        PB_START_O <= '1';

      when S_PBSM_RUN =>

        if (PB_RDY_I = '1') then
          START_O <= '1';
        end if;

    end case;

  end process P_FSM_OUTPS;

end architecture RTL;
