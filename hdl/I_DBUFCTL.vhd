--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
-- Create Date:     Sat Aug 21 22:39:40 CEST 2021
-- Design Name:     I_DBUFCTL
-- Module Name:     I_DBUFCTL.vhd - Behavioral
-- Project Name:    i-2DDCT
-- Description:     Intermittent Double Buffer Controller
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

-- User libraries

library WORK;
  use WORK.I_2DDCT_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity I_DBUFCTL is
  port (
    CLK                       : in    std_logic;
    RST                       : in    std_logic;
    I_DCT1S_BLOCK_CMPLT       : in    std_logic;
    I_DCT2S_BLOCK_CMPLT       : in    std_logic;
    WMEMSEL                   : out   std_logic;
    RMEMSEL                   : out   std_logic;
    DATA_READY                : out   std_logic;
    DATA_READY_ACK            : in    std_logic;

    SYS_STATUS                : in    sys_status_t;
    DATA_SYNC                 : in    std_logic;
    PB_START                  : in    std_logic;
    RX                        : in    std_logic_vector(C_NVM_DATA_W - 1 downto 0);
    TX                        : out   std_logic_vector(C_NVM_DATA_W - 1 downto 0);
    PB_READY                  : out   std_logic
  );
end entity I_DBUFCTL;
----------------------------- ARCHITECTURE -------------------------------------

architecture BEHAVIORAL of I_DBUFCTL is

  --########################### CONSTANTS 1 ####################################

  --########################### TYPES ##########################################

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################
  signal wmemsel_s   : std_logic;
  signal rmemsel_s   : std_logic;
  signal pb_ready_s  : std_logic;

  --########################### ARCHITECTURE BEGIN #############################

begin

  --########################### ENTITY DEFINITION ##############################

  --########################## OUTPUT PORTS WIRING #############################
  WMEMSEL  <= wmemsel_s;
  RMEMSEL  <= rmemsel_s;
  PB_READY <= pb_ready_s;

  --########################## COBINATORIAL FUNCTIONS ##########################

  --########################## PROCESSES #######################################

  MEM_SWITCH_AND_PB : process (CLK, RST) is
  begin

    if (RST = '1') then
      wmemsel_s  <= '0'; -- initially mem 1 is selected
      rmemsel_s  <= '0'; -- initially mem 1 is selected
      pb_ready_s <= '1';
      TX         <= (others => '0');
      DATA_READY <= '0';
    elsif (CLK = '1' and clk'event) then
      if (SYS_STATUS = SYS_PUSH_CHKPNT_NV2V) then
        if (PB_START = '1') then
          pb_ready_s <= '0';
        end if;
        if (pb_ready_s = '0' AND DATA_SYNC = '1') then
          wmemsel_s  <= RX(0);
          rmemsel_s  <= RX(1);
          pb_ready_s <= '1';
        end if;
      elsif (SYS_STATUS = SYS_PUSH_CHKPNT_V2NV) then
        TX <= (1=>rmemsel_s, 0=>wmemsel_s, others => '0');

        if (PB_START = '1') then
          pb_ready_s <= '0';
        end if;
        if (pb_ready_s = '0' AND DATA_SYNC = '1') then
          pb_ready_s <= '1';
        end if;
      else               --if (SYS_STATUS = SYS_RUN or others) then
        if (I_DCT1S_BLOCK_CMPLT = '1') then
          wmemsel_s  <= not wmemsel_s;
          DATA_READY <= '1';
        end if;
        if (I_DCT2S_BLOCK_CMPLT = '1') then
          rmemsel_s <= not rmemsel_s;
        end if;
        if (DATA_READY_ACK = '1') then
          DATA_READY <= '0';
        end if;
      end if;
    end if;

  end process MEM_SWITCH_AND_PB;

end architecture BEHAVIORAL;

--------------------------------------------------------------------------------
