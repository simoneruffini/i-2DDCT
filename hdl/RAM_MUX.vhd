--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
--
-- Create Date:    Wed Jul 28 10:45:46 CEST 2021
-- Design Name:    RAM_MUX - RTL
-- Module Name:    RAM_MUX.vhd
-- Project Name:   i-2DDCT
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

entity RAM_MUX is
  port (
    -- MUX control ports
    CLK                                         : in    std_logic;
    SYS_STATUS                                  : in    sys_status_t;                                           -- System status value of sys_status_t
    I_DCT1S_VARC_READY                          : in    std_logic;
    I_DCT2S_VARC_READY                          : in    std_logic;
    I_DBUFCTL_WMEMSEL                           : in    std_logic;
    I_DBUFCTL_RMEMSEL                           : in    std_logic;
    -- TO/FROM RAM 1
    R1_DIN                                      : out   std_logic_vector(C_RAMDATA_W - 1 downto 0);
    R1_WADDR                                    : out   std_logic_vector(C_RAMADDR_W - 1 downto 0);
    R1_RADDR                                    : out   std_logic_vector(C_RAMADDR_W - 1 downto 0);
    R1_WE                                       : out   std_logic;
    R1_DOUT                                     : in    std_logic_vector(C_RAMDATA_W - 1 downto 0);
    -- TO/FROM RAM 2
    R2_DIN                                      : out   std_logic_vector(C_RAMDATA_W - 1 downto 0);
    R2_WADDR                                    : out   std_logic_vector(C_RAMADDR_W - 1 downto 0);
    R2_RADDR                                    : out   std_logic_vector(C_RAMADDR_W - 1 downto 0);
    R2_WE                                       : out   std_logic;
    R2_DOUT                                     : in    std_logic_vector(C_RAMDATA_W - 1 downto 0);
    -- I_DCT1S RAM ports
    I_DCT1S_DIN                                 : in    std_logic_vector(C_RAMDATA_W - 1 downto 0);
    I_DCT1S_WADDR                               : in    std_logic_vector(C_RAMADDR_W - 1 downto 0);
    I_DCT1S_RADDR                               : in    std_logic_vector(C_RAMADDR_W - 1 downto 0);
    I_DCT1S_WE                                  : in    std_logic;
    I_DCT1S_DOUT                                : out   std_logic_vector(C_RAMDATA_W - 1 downto 0);
    -- I_DCT2S RAM ports
    I_DCT2S_DIN                                 : in    std_logic_vector(C_RAMDATA_W - 1 downto 0);
    I_DCT2S_WADDR                               : in    std_logic_vector(C_RAMADDR_W - 1 downto 0);
    I_DCT2S_RADDR                               : in    std_logic_vector(C_RAMADDR_W - 1 downto 0);
    I_DCT2S_WE                                  : in    std_logic;
    I_DCT2S_DOUT                                : out   std_logic_vector(C_RAMDATA_W - 1 downto 0);
    -- RAM_PB RAM ports
    RAM_PB_RAM1_DIN                             : in    std_logic_vector(C_RAMDATA_W - 1 downto 0);
    RAM_PB_RAM2_DIN                             : in    std_logic_vector(C_RAMDATA_W - 1 downto 0);
    RAM_PB_RAM_WADDR                            : in    std_logic_vector(C_RAMADDR_W - 1 downto 0);
    RAM_PB_RAM_RADDR                            : in    std_logic_vector(C_RAMADDR_W - 1 downto 0);
    RAM_PB_RAM_WE                               : in    std_logic;
    RAM_PB_RAM1_DOUT                            : out   std_logic_vector(C_RAMDATA_W - 1 downto 0);
    RAM_PB_RAM2_DOUT                            : out   std_logic_vector(C_RAMDATA_W - 1 downto 0)
  );
end entity RAM_MUX;

----------------------------- ARCHITECTURE -------------------------------------

architecture RTL of RAM_MUX is

  --########################### CONSTANTS 1 ####################################

  --########################### TYPES ##########################################

  --########################### FUNCTIONS ######################################

  --########################### CONSTANTS 2 ####################################

  --########################### SIGNALS ########################################
  signal sys_status_d                 : sys_status_t;
  signal mux_raddr                    : std_logic_vector(C_RAMADDR_W - 1 downto 0);
  signal mux_waddr                    : std_logic_vector(C_RAMADDR_W - 1 downto 0);
  signal mux_din                      : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal mux_r1_din                   : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal mux_r2_din                   : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal dct1s_mux_dout               : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal dct2s_mux_dout               : std_logic_vector(C_RAMDATA_W - 1 downto 0);

  signal run_mux_r1_we                : std_logic;
  signal run_mux_r2_we                : std_logic;
  signal dct1s_push_mux_r1_we         : std_logic;
  signal dct1s_push_mux_r2_we         : std_logic;
  signal dct2s_push_mux_r1_we         : std_logic;
  signal dct2s_push_mux_r2_we         : std_logic;

  signal mux_r1_we                    : std_logic;
  signal mux_r2_we                    : std_logic;

  --########################### ARCHITECTURE BEGIN #############################

begin

  --########################### ENTITY DEFINITION ##############################

  --########################## OUTPUT PORTS WIRING #############################
  -- RAM1 and RAM2 share mux_raddr signal
  R1_RADDR <= mux_raddr;
  R2_RADDR <= mux_raddr;

  -- I_DCT1S and I_DCT2S share mux_dout signal
  I_DCT1S_DOUT <= dct1s_mux_dout;
  I_DCT2S_DOUT <= dct2s_mux_dout;
  -- RAM PB takes RAM1 and RAM2 douts
  RAM_PB_RAM1_DOUT <= R1_DOUT;
  RAM_PB_RAM2_DOUT <= R2_DOUT;

  -- RAM1 and RAM2 share mux_waddr value
  R1_WADDR <= mux_waddr;
  R2_WADDR <= mux_waddr;

  -- RAM1 mux
  R1_DIN <= mux_r1_din;
  -- RAM2 mux
  R2_DIN <= mux_r2_din;

  -- RAM1 we
  R1_WE <= mux_r1_we;
  -- RAM2 we
  R2_WE <= mux_r2_we;
  --########################## COBINATORIAL FUNCTIONS ##########################

  -- RADDR mux
  mux_raddr <= I_DCT2S_RADDR when sys_status_d = SYS_RUN else
               I_DCT2S_RADDR when sys_status_d = SYS_VARC_INIT_CHKPNT AND I_DCT1S_VARC_READY = '1' AND I_DCT2S_VARC_READY = '0' else
               I_DCT1S_RADDR when sys_status_d = SYS_VARC_INIT_CHKPNT AND I_DCT1S_VARC_READY = '0' AND I_DCT2S_VARC_READY = '0' else
               RAM_PB_RAM_RADDR when sys_status_d = SYS_PUSH_CHKPNT_V2NV else
               I_DCT2S_RADDR;
  -- DOUT mux
  dct2s_mux_dout <= R1_DOUT when I_DBUFCTL_RMEMSEL = '0' else
                    R2_DOUT;
  dct1s_mux_dout <= R1_DOUT when I_DBUFCTL_RMEMSEL = '1' else
                    R2_DOUT;

  -- WADDR mux
  mux_waddr <= I_DCT1S_WADDR when sys_status_d = SYS_RUN else
               I_DCT1S_WADDR when sys_status_d = SYS_VARC_PREP_CHKPNT AND I_DCT1S_VARC_READY = '0' AND I_DCT2S_VARC_READY = '0' else
               I_DCT2S_WADDR when sys_status_d = SYS_VARC_PREP_CHKPNT AND I_DCT1S_VARC_READY = '1' AND I_DCT2S_VARC_READY = '0' else
               RAM_PB_RAM_WADDR when sys_status_d = SYS_PUSH_CHKPNT_NV2V else
               (others => '1');
  -- DIN mux
  mux_din <= I_DCT1S_DIN when sys_status_d = SYS_RUN else
             I_DCT1S_DIN when sys_status_d = SYS_VARC_PREP_CHKPNT AND I_DCT1S_VARC_READY = '0' AND I_DCT2S_VARC_READY = '0' else
             I_DCT2S_DIN when sys_status_d = SYS_VARC_PREP_CHKPNT AND I_DCT1S_VARC_READY = '1' AND I_DCT2S_VARC_READY = '0' else
             (others => '1');

  mux_r1_din <= RAM_PB_RAM1_DIN when sys_status_d = SYS_PUSH_CHKPNT_NV2V else
                mux_din;
  mux_r2_din <= RAM_PB_RAM2_DIN when sys_status_d = SYS_PUSH_CHKPNT_NV2V else
                mux_din;

  -- WE mux during RUN (DCT1S controls we)
  run_mux_r1_we <= I_DCT1S_WE when I_DBUFCTL_WMEMSEL = '0' else
                   '0';
  run_mux_r2_we <= I_DCT1S_WE when I_DBUFCTL_WMEMSEL = '1' else
                   '0';

  -- WE mux during DCT1S ram push
  dct1s_push_mux_r1_we <= I_DCT1S_WE when I_DBUFCTL_WMEMSEL = '0' else
                          '0';
  dct1s_push_mux_r2_we <= I_DCT1S_WE when I_DBUFCTL_WMEMSEL = '1' else
                          '0';

  -- WE mux during DCT2S ram push
  dct2s_push_mux_r1_we <= I_DCT2S_WE when I_DBUFCTL_WMEMSEL = '1' else
                          '0';
  dct2s_push_mux_r2_we <= I_DCT2S_WE when I_DBUFCTL_WMEMSEL = '0' else
                          '0';
  -- R1_WE mux
  mux_r1_we <= run_mux_r1_we when sys_status_d = SYS_RUN else
               dct1s_push_mux_r1_we when sys_status_d = SYS_VARC_PREP_CHKPNT AND I_DCT1S_VARC_READY = '0' AND I_DCT2S_VARC_READY = '0' else
               dct2s_push_mux_r1_we when sys_status_d = SYS_VARC_PREP_CHKPNT AND I_DCT1S_VARC_READY = '1' AND I_DCT2S_VARC_READY = '0' else
               RAM_PB_RAM_WE when sys_status_d = SYS_PUSH_CHKPNT_NV2V  else
               '0';

  -- R2_WE mux
  mux_r2_we <= run_mux_r2_we when sys_status_d = SYS_RUN else
               dct1s_push_mux_r2_we when sys_status_d = SYS_VARC_PREP_CHKPNT AND I_DCT1S_VARC_READY = '0' AND I_DCT2S_VARC_READY = '0' else
               dct2s_push_mux_r2_we when sys_status_d = SYS_VARC_PREP_CHKPNT AND I_DCT1S_VARC_READY = '1' AND I_DCT2S_VARC_READY = '0' else
               RAM_PB_RAM_WE when sys_status_d = SYS_PUSH_CHKPNT_NV2V  else
               '0';

  --########################## PROCESSES #######################################

  P_DELAYS : process (CLK) is
  begin

    if (CLK'event and CLK = '1') then
      sys_status_d <= SYS_STATUS;
    end if;

  end process P_DELAYS;

end architecture RTL;

--------------------------------------------------------------------------------
