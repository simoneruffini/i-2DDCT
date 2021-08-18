--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
--
-- Create Date:     Mon Jul 26 17:11:08 CEST 2021
-- Design Name:     RAM_PB - RTL
-- Module Name:     RAM_PB.vhd
-- Project Name:    i-2DDCT
-- Description:
--
-- Revision:
-- Revision 00 - Simone Ruffini
--  * File Created
-- Additional Comments:
--
--------------------------------------------------------------------------------

----------------------------- PACKAGES/LIBRARIES -------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

-- User libraries

library WORK;
  use WORK.I_2DDCT_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity RAM_PB is
  port (
    CLK                                : in    std_logic;                                    -- Input clock
    RST                                : in    std_logic;                                    -- Positive reset
    START                              : in    std_logic;                                    -- Ram process block start
    READY                              : out   std_logic;                                    -- Proces Block ready signal
    SYS_STATUS                         : in    sys_status_t;                                 -- System status from NVM_CTRL
    NVM_CTRL_SYNC                      : in    std_logic;                                    -- Sync signal from NVM_CTRL
    RX                                 : in    std_logic_vector(C_NVM_DATA_W - 1 downto 0);  -- Dadta from NVM_CTRL
    TX                                 : out   std_logic_vector(C_NVM_DATA_W - 1 downto 0);  -- Data to NVM_CTRL
    -- Ram control Ports
    RAM1_DIN                           : out   std_logic_vector(C_RAMDATA_W - 1 downto 0);   -- Ram1 data input
    RAM2_DIN                           : out   std_logic_vector(C_RAMDATA_W - 1 downto 0);   -- Ram2 data input
    RAM_WADDR                          : out   std_logic_vector(C_RAMADDR_W - 1 downto 0);   -- Ram1/2 shared write address
    RAM_RADDR                          : out   std_logic_vector(C_RAMADDR_W - 1 downto 0);   -- Ram1/2 shared read address
    RAM_WE                             : out   std_logic;                                    -- Ram1/2 shared write enable
    RAM1_DOUT                          : in    std_logic_vector(C_RAMDATA_W - 1 downto 0);   -- Ram1 data output
    RAM2_DOUT                          : in    std_logic_vector(C_RAMDATA_W - 1 downto 0)    -- Ram2 data output
  );
end entity RAM_PB;

----------------------------- ARCHITECTURE -------------------------------------

architecture RTL of RAM_PB is

  --########################### CONSTANTS 1 ####################################

  --########################### TYPES ##########################################

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################
  signal nvm_ctrl_sync_d    : std_logic;                                              -- NVM_CTRL_SYNC delay
  signal start_d            : std_logic;                                              -- START delay
  --signal pb_task_on         : std_logic;                                      -- process block task[V2NV or NV2V] on
  signal ram_xaddr          : unsigned (C_RAMADDR_W - 1 downto 0);                    -- RAM [R/W]address
  signal sync_cnt           : natural range 0 to C_RAM_CONTENT_AMOUNT;                -- Counts number of sync signals
  signal ready_s            : std_logic;                                              -- Process block ready signal
  signal ram_incr_en        : std_logic;
  signal ram_dout_concat    : std_logic_vector(C_RAMDATA_W * 2 - 1 downto 0);         -- RAM1 dout + RAM2 dout concatenation (auxiliary signal)
  signal ram_dout_latch     : std_logic_vector(C_RAMDATA_W * 2 - 1 downto 0);         -- RAM_dout_concat latched

  --########################### ARCHITECTURE BEGIN #############################

begin

  --########################### ENTITY DEFINITION ##############################

  --########################## OUTPUT PORTS WIRING #############################

  READY <= ready_s;
  --RAM_WE    <= NVM_CTRL_SYNC when pb_task_on = '1' AND SYS_STATUS = SYS_PUSH_CHKPNT_NV2V else
  RAM_WE    <= NVM_CTRL_SYNC when SYS_STATUS = SYS_PUSH_CHKPNT_NV2V else
               '0';
  RAM_WADDR <= std_logic_vector(ram_xaddr);
  RAM_RADDR <= std_logic_vector(ram_xaddr);

  RAM1_DIN <= RX(RAM1_DIN'length - 1 downto 0);
  RAM2_DIN <= RX(RAM2_DIN'length - 1 + RAM1_DIN'length downto RAM1_DIN'length);

  ram_dout_concat <= RAM2_DOUT & RAM1_DOUT;
  TX              <= std_logic_vector(resize(unsigned(ram_dout_latch), TX'length));

  --########################## COBINATORIAL FUNCTIONS ##########################

  ram_incr_en <= nvm_ctrl_sync_d OR start_d;

  --########################## PROCESSES #######################################

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- PB Ready signal gen

  P_READY_GEN : process (CLK, RST) is
  begin

    if (RST='1') then
      ready_s  <= '1';
      sync_cnt <= 0;
    elsif (CLK'event and CLK = '1') then
      if (START = '1') then
        sync_cnt <= 0;
        if (SYS_STATUS = SYS_PUSH_CHKPNT_NV2V) then
          ready_s <= '0';
        elsif (SYS_STATUS = SYS_PUSH_CHKPNT_V2NV) then
          ready_s <= '0';
        else
          ready_s <= '1';
        end if;
      end if;

      -- -- Stop task and be ready for new request
      -- if (ram_xaddr = (C_RAM_CONTENT_AMOUNT - 1)) then
      --   -- RAM to NVM
      --   if (SYS_STATUS = SYS_PUSH_CHKPNT_NV2NV) then
      --     if (NVM_CTRL_SYNC = '1') then
      --       ready_s <= '1';
      --     end if;
      --   -- NVM to RAM
      --   elsif (SYS_STATUS = SYS_PUSH_CHKPNT_V2NV) then
      --     if (nvm_ctrl_sync_d = '1') then
      --       ready_s <= '1';
      --     end if;

      --   end if;
      -- end if;

      if (NVM_CTRL_SYNC = '1' and ready_s = '0') then
        sync_cnt <= sync_cnt + 1;
        if (sync_cnt = C_RAM_CONTENT_AMOUNT - 1) then
          ready_s  <= '1';
          sync_cnt <= 0;
        end if;
      end if;
    end if;

  end process P_READY_GEN;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- RAM xADDR gen

  P_XADDR : process (CLK, RST) is
  begin

    if (RST = '1') then
      ram_xaddr <= (others => '0');
    elsif (CLK'event and CLK = '1') then

      case SYS_STATUS is

        when SYS_PUSH_CHKPNT_V2NV =>
          if (START = '1' OR (NVM_CTRL_SYNC = '1' AND ready_s = '0')) then
            ram_xaddr <= ram_xaddr + 1;
          end if;
          if (ram_xaddr = C_RAM_CONTENT_AMOUNT - 1) then
            ram_xaddr <= ram_xaddr;
          end if;
        when SYS_PUSH_CHKPNT_NV2V =>
          if (NVM_CTRL_SYNC = '1' and ready_s = '0') then
            ram_xaddr <= ram_xaddr + 1;
          end if;
          if (ram_xaddr = C_RAM_CONTENT_AMOUNT - 1) then
            ram_xaddr <= ram_xaddr;
          end if;
        when others =>
          ram_xaddr <= (others => '0');

      end case;

    end if;

  end process P_XADDR;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- RAM DOUT latch-D

  P_RAM_DOUT_LATCH : process (ram_incr_en, ram_dout_concat) is
  begin

    if (ram_incr_en = '1') then
      ram_dout_latch <= ram_dout_concat;
    end if;

  end process P_RAM_DOUT_LATCH;

  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  -- Internal delays

  P_DELAYS : process (CLK, RST) is
  begin

    if (RST = '1') then
      nvm_ctrl_sync_d <= '0';
      start_d         <= '0';
    elsif (CLK'event and CLK = '1') then
      nvm_ctrl_sync_d <= NVM_CTRL_SYNC;
      start_d         <= START;
    end if;

  end process P_DELAYS;

end architecture RTL;

--------------------------------------------------------------------------------
