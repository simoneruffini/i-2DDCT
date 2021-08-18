--------------------------------------------------------------------------------
--                                                                            --
--                          V H D L    F I L E                                --
--                          COPYRIGHT (C) 2006                                --
--                                                                            --
--------------------------------------------------------------------------------
--
-- Title       : DCT
-- Design      : 2DDCT Core
-- Author      : Michal Krepa
--
--------------------------------------------------------------------------------
--
-- File        : ROMO.VHD
-- Created     : Sat Mar 5 7:37 2006
-- Modified    : Dez. 30 2008 - Andreas Bergmann
--               Libs and Typeconversion fixed due Xilinx Synthesis errors
--
--------------------------------------------------------------------------------
--
--  Description : ROM for DCT matrix constant cosine coefficients (odd part)
--
--------------------------------------------------------------------------------

-- 5:0
-- 5:4 = select matrix row (1 out of 4)
-- 3:0 = select precomputed MAC ( 1 out of 16)

library IEEE; 
  use IEEE.STD_LOGIC_1164.all; 
--  use ieee.STD_LOGIC_signed.all; 
  use IEEE.STD_LOGIC_arith.all;
  use WORK.I_2DDCT_PKG.all;

entity ROMO is 
  port( 
       addr         : in  STD_LOGIC_VECTOR(C_ROMADDR_W-1 downto 0);
       clk          : in  STD_LOGIC;  
       
       datao        : out STD_LOGIC_VECTOR(C_ROMDATA_W-1 downto 0) 
  );          
  
end ROMO; 

architecture RTL of ROMO is  
  type ROM_TYPE is array (0 to 2**C_ROMADDR_W-1) 
            of STD_LOGIC_VECTOR(C_ROMDATA_W-1 downto 0);
  constant rom : ROM_TYPE := 
    (
       (others => '0'),
       conv_std_logic_vector( GP,C_ROMDATA_W ),
       conv_std_logic_vector( FP,C_ROMDATA_W ),
       conv_std_logic_vector( FP+GP,C_ROMDATA_W ),
       conv_std_logic_vector( EP,C_ROMDATA_W ),
       conv_std_logic_vector( EP+GP,C_ROMDATA_W ),
       conv_std_logic_vector( EP+FP,C_ROMDATA_W ),
       conv_std_logic_vector( EP+FP+GP,C_ROMDATA_W ),
       conv_std_logic_vector( DP,C_ROMDATA_W ),
       conv_std_logic_vector( DP+GP,C_ROMDATA_W ),
       conv_std_logic_vector( DP+FP,C_ROMDATA_W ),
       conv_std_logic_vector( DP+FP+GP,C_ROMDATA_W ),
       conv_std_logic_vector( DP+EP,C_ROMDATA_W ),
       conv_std_logic_vector( DP+EP+GP,C_ROMDATA_W ),
       conv_std_logic_vector( DP+EP+FP,C_ROMDATA_W ),
       conv_std_logic_vector( DP+EP+FP+GP,C_ROMDATA_W ),    
      
       (others => '0'),
       conv_std_logic_vector( FM,C_ROMDATA_W ),
       conv_std_logic_vector( DM,C_ROMDATA_W ),
       conv_std_logic_vector( DM+FM,C_ROMDATA_W ),
       conv_std_logic_vector( GM,C_ROMDATA_W ),
       conv_std_logic_vector( GM+FM,C_ROMDATA_W ),
       conv_std_logic_vector( GM+DM,C_ROMDATA_W ),
       conv_std_logic_vector( GM+DM+FM,C_ROMDATA_W ),
       conv_std_logic_vector( EP,C_ROMDATA_W ),
       conv_std_logic_vector( EP+FM,C_ROMDATA_W ),
       conv_std_logic_vector( EP+DM,C_ROMDATA_W ),
       conv_std_logic_vector( EP+DM+FM,C_ROMDATA_W ),
       conv_std_logic_vector( EP+GM,C_ROMDATA_W ),
       conv_std_logic_vector( EP+GM+FM,C_ROMDATA_W ),
       conv_std_logic_vector( EP+GM+DM,C_ROMDATA_W ),
       conv_std_logic_vector( EP+GM+DM+FM,C_ROMDATA_W ),
      
       (others => '0'),
       conv_std_logic_vector( EP,C_ROMDATA_W ),
       conv_std_logic_vector( GP,C_ROMDATA_W ),
       conv_std_logic_vector( EP+GP,C_ROMDATA_W ),
       conv_std_logic_vector( DM,C_ROMDATA_W ),
       conv_std_logic_vector( DM+EP,C_ROMDATA_W ),
       conv_std_logic_vector( DM+GP,C_ROMDATA_W ),
       conv_std_logic_vector( DM+GP+EP,C_ROMDATA_W ),
       conv_std_logic_vector( FP,C_ROMDATA_W ),
       conv_std_logic_vector( FP+EP,C_ROMDATA_W ),
       conv_std_logic_vector( FP+GP,C_ROMDATA_W ),
       conv_std_logic_vector( FP+GP+EP,C_ROMDATA_W ),
       conv_std_logic_vector( FP+DM,C_ROMDATA_W ),
       conv_std_logic_vector( FP+DM+EP,C_ROMDATA_W ),
       conv_std_logic_vector( FP+DM+GP,C_ROMDATA_W ),
       conv_std_logic_vector( FP+DM+GP+EP,C_ROMDATA_W ),
    
       (others => '0'),
       conv_std_logic_vector( DM,C_ROMDATA_W ),
       conv_std_logic_vector( EP,C_ROMDATA_W ),
       conv_std_logic_vector( EP+DM,C_ROMDATA_W ),
       conv_std_logic_vector( FM,C_ROMDATA_W ),
       conv_std_logic_vector( FM+DM,C_ROMDATA_W ),
       conv_std_logic_vector( FM+EP,C_ROMDATA_W ),
       conv_std_logic_vector( FM+EP+DM,C_ROMDATA_W ),
       conv_std_logic_vector( GP,C_ROMDATA_W ),
       conv_std_logic_vector( GP+DM,C_ROMDATA_W ),
       conv_std_logic_vector( GP+EP,C_ROMDATA_W ),
       conv_std_logic_vector( GP+EP+DM,C_ROMDATA_W ),
       conv_std_logic_vector( GP+FM,C_ROMDATA_W ),
       conv_std_logic_vector( GP+FM+DM,C_ROMDATA_W ),
       conv_std_logic_vector( GP+FM+EP,C_ROMDATA_W ),
       conv_std_logic_vector( GP+FM+EP+DM,C_ROMDATA_W )
       );

begin   
    
  process(clk)
  begin
   if clk = '1' and clk'event then
	  datao <= rom( CONV_INTEGER(UNSIGNED(addr)) ); 
   end if;
  end process;
      
end RTL;    
          

                

