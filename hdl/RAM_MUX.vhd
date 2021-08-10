--------------------------------------------------------------------------------
-- Engineer:  Simone Ruffini [simone.ruffini@tutanota.com]
--
--
-- Create Date:    Wed Jul 28 10:45:46 CEST 2021
-- Design Name:    RAM_MUX - RTL
-- Module Name:    RAM_MUX.vhd
-- Project Name:   iMDCT
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
  use WORK.I_MDCT_PKG.all;

----------------------------- ENTITY -------------------------------------------

entity RAM_MUX is
  port (
    -- MUX control ports
    SYS_STATUS                                  : in    sys_status_t;                                           -- System status value of sys_status_t
    I_DCT1D_VARC_READY                          : in    std_logic;
    I_DCT2D_VARC_READY                          : in    std_logic;
    DBUFCTL_MEMSEL                              : in    std_logic;
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
    -- I_DCT1D RAM ports
    I_DCT1D_DIN                                 : in    std_logic_vector(C_RAMDATA_W - 1 downto 0);
    I_DCT1D_WADDR                               : in    std_logic_vector(C_RAMADDR_W - 1 downto 0);
    I_DCT1D_RADDR                               : in    std_logic_vector(C_RAMADDR_W - 1 downto 0);
    I_DCT1D_WE                                  : in    std_logic;
    I_DCT1D_DOUT                                : out   std_logic_vector(C_RAMDATA_W - 1 downto 0);
    -- I_DCT2D RAM ports
    I_DCT2D_DIN                                 : in    std_logic_vector(C_RAMDATA_W - 1 downto 0);
    I_DCT2D_WADDR                               : in    std_logic_vector(C_RAMADDR_W - 1 downto 0);
    I_DCT2D_RADDR                               : in    std_logic_vector(C_RAMADDR_W - 1 downto 0);
    I_DCT2D_WE                                  : in    std_logic;
    I_DCT2D_DOUT                                : out   std_logic_vector(C_RAMDATA_W - 1 downto 0);
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
  signal mux_raddr            : std_logic_vector(C_RAMADDR_W - 1 downto 0);
  signal mux_waddr            : std_logic_vector(C_RAMADDR_W - 1 downto 0);
  signal mux_din              : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal mux_r1_din           : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal mux_r2_din           : std_logic_vector(C_RAMDATA_W - 1 downto 0);
  signal mux_dout             : std_logic_vector(C_RAMDATA_W - 1 downto 0);

  signal demux_r1_we          : std_logic;
  signal demux_r2_we          : std_logic;
  signal mux_we               : std_logic;
  signal mux_r1_we            : std_logic;
  signal mux_r2_we            : std_logic;

  --########################### ARCHITECTURE BEGIN #############################

begin

  --########################### ENTITY DEFINITION ##############################

  --########################## OUTPUT PORTS WIRING #############################
  -- RAM1 and RAM2 share mux_raddr signal
  R1_RADDR <= mux_raddr;
  R2_RADDR <= mux_raddr;

  -- I_DCT1D and I_DCT2D share mux_dout signal
  I_DCT1D_DOUT <= mux_dout;
  I_DCT2D_DOUT <= mux_dout;
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
  mux_raddr <= I_DCT2D_RADDR when SYS_STATUS = SYS_RUN else
               I_DCT2D_RADDR when SYS_STATUS = SYS_VARC_INIT_CHKPNT AND I_DCT1D_VARC_READY = '1' AND I_DCT2D_VARC_READY = '0' else
               I_DCT1D_RADDR when SYS_STATUS = SYS_VARC_INIT_CHKPNT AND I_DCT1D_VARC_READY = '0' AND I_DCT2D_VARC_READY = '0' else
               RAM_PB_RAM_RADDR when SYS_STATUS = SYS_PUSH_CHKPNT_V2NV else
               (others => '1');
  -- DOUT mux
  mux_dout <= R1_DOUT when DBUFCTL_MEMSEL = '0' else
              R2_DOUT;

  -- WADDR mux
  mux_waddr <= I_DCT1D_WADDR when SYS_STATUS = SYS_RUN else
               I_DCT1D_WADDR when SYS_STATUS = SYS_VARC_PREP_CHKPNT AND I_DCT1D_VARC_READY = '0' AND I_DCT2D_VARC_READY = '0' else
               I_DCT2D_WADDR when SYS_STATUS = SYS_VARC_PREP_CHKPNT AND I_DCT1D_VARC_READY = '1' AND I_DCT2D_VARC_READY = '0' else
               RAM_PB_RAM_WADDR when SYS_STATUS = SYS_PUSH_CHKPNT_NV2V else
               (others => '1');
  -- DIN mux
  mux_din <= I_DCT1D_DIN when SYS_STATUS = SYS_RUN else
             I_DCT1D_DIN when SYS_STATUS = SYS_VARC_PREP_CHKPNT AND I_DCT1D_VARC_READY = '0' AND I_DCT2D_VARC_READY = '0' else
             I_DCT2D_DIN when SYS_STATUS = SYS_VARC_PREP_CHKPNT AND I_DCT1D_VARC_READY = '1' AND I_DCT2D_VARC_READY = '0' else
             (others => '1');

  mux_r1_din <= RAM_PB_RAM1_DIN when SYS_STATUS = SYS_PUSH_CHKPNT_NV2V else
                mux_din;
  mux_r2_din <= RAM_PB_RAM2_DIN when SYS_STATUS = SYS_PUSH_CHKPNT_NV2V else
                mux_din;

  -- WE mux 1
  mux_we <= I_DCT1D_WE when SYS_STATUS = SYS_RUN else
            I_DCT1D_WE when SYS_STATUS = SYS_VARC_PREP_CHKPNT AND I_DCT1D_VARC_READY = '0' AND I_DCT2D_VARC_READY = '0' else
            I_DCT2D_WE when SYS_STATUS = SYS_VARC_PREP_CHKPNT AND I_DCT1D_VARC_READY = '1' AND I_DCT2D_VARC_READY = '0' else
            '0';
  -- WE demux
  demux_r1_we <= mux_we when DBUFCTL_MEMSEL = '0' else
                 '0';
  demux_r1_we <= mux_we when DBUFCTL_MEMSEL = '1' else
                 '0';

  -- R1_WE mux
  mux_r1_we <= RAM_PB_RAM_WE when SYS_STATUS = SYS_PUSH_CHKPNT_NV2V  else
               demux_r1_we;

  -- R2_WE mux
  mux_r2_we <= RAM_PB_RAM_WE when SYS_STATUS = SYS_PUSH_CHKPNT_NV2V  else
               demux_r2_we;

  --########################## PROCESSES #######################################

end architecture RTL;

--------------------------------------------------------------------------------
