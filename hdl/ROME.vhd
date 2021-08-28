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
-- File        : ROME.VHD
-- Created     : Sat Mar 5 7:37 2006
--
--------------------------------------------------------------------------------
--
--  Description : ROM for DCT matrix constant cosine coefficients (even part)
--
--------------------------------------------------------------------------------

-- 5:0
-- 5:4 = select matrix row (1 out of 4)
-- 3:0 = select precomputed MAC ( 1 out of 16)

library IEEE; 
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.STD_LOGIC_arith.all;
  use WORK.I_2DDCT_PKG.all;

entity ROME is 
  port( 
       addr         : in  STD_LOGIC_VECTOR(C_ROMADDR_W-1 downto 0); 
       clk          : in  STD_LOGIC; 
       
       dout        : out STD_LOGIC_VECTOR(C_ROMDATA_W-1 downto 0) 
  );         
  
end ROME; 

architecture RTL of ROME is  
  
  type ROM_TYPE is array (0 to (2**C_ROMADDR_W)-1) 
            of STD_LOGIC_VECTOR(C_ROMDATA_W-1 downto 0);
  constant rom : ROM_TYPE := 
    (
    (others => '0'),                
     conv_std_logic_vector( AP,C_ROMDATA_W ),         
     conv_std_logic_vector( AP,C_ROMDATA_W ),         
     conv_std_logic_vector( AP+AP,C_ROMDATA_W ),      
     conv_std_logic_vector( AP,C_ROMDATA_W ),         
     conv_std_logic_vector( AP+AP,C_ROMDATA_W ),      
     conv_std_logic_vector( AP+AP,C_ROMDATA_W ),      
     conv_std_logic_vector( AP+AP+AP,C_ROMDATA_W ),   
     conv_std_logic_vector( AP,C_ROMDATA_W ),         
     conv_std_logic_vector( AP+AP,C_ROMDATA_W ),      
     conv_std_logic_vector( AP+AP,C_ROMDATA_W ),      
     conv_std_logic_vector( AP+AP+AP,C_ROMDATA_W ),   
     conv_std_logic_vector( AP+AP,C_ROMDATA_W ),      
     conv_std_logic_vector( AP+AP+AP,C_ROMDATA_W ),   
     conv_std_logic_vector( AP+AP+AP,C_ROMDATA_W ),   
     conv_std_logic_vector( AP+AP+AP+AP,C_ROMDATA_W ),
                                     
                                     
     (others => '0'),                
     conv_std_logic_vector( BN,C_ROMDATA_W ),         
     conv_std_logic_vector( CN,C_ROMDATA_W ),         
     conv_std_logic_vector( CN+BN,C_ROMDATA_W ),      
     conv_std_logic_vector( CP,C_ROMDATA_W ),         
     conv_std_logic_vector( CP+BN,C_ROMDATA_W ),      
     (others => '0'),                
     conv_std_logic_vector( BN,C_ROMDATA_W ),         
     conv_std_logic_vector( BP,C_ROMDATA_W ),         
     (others => '0'),                
     conv_std_logic_vector( BP+CN,C_ROMDATA_W ),      
     conv_std_logic_vector( CN,C_ROMDATA_W ),         
     conv_std_logic_vector( BP+CP,C_ROMDATA_W ),      
     conv_std_logic_vector( CP,C_ROMDATA_W ),         
     conv_std_logic_vector( BP,C_ROMDATA_W ),         
     (others => '0'),                
                                     
                                     
     (others => '0'),                
     conv_std_logic_vector( AP,C_ROMDATA_W ),         
     conv_std_logic_vector( AN,C_ROMDATA_W ),         
     (others => '0'),                
     conv_std_logic_vector( AN,C_ROMDATA_W ),         
     (others => '0'),                
     conv_std_logic_vector( AN+AN,C_ROMDATA_W ),      
     conv_std_logic_vector( AN,C_ROMDATA_W ),         
     conv_std_logic_vector( AP,C_ROMDATA_W ),         
     conv_std_logic_vector( AP+AP,C_ROMDATA_W ),      
     (others => '0'),                
     conv_std_logic_vector( AP,C_ROMDATA_W ),         
     (others => '0'),                
     conv_std_logic_vector( AP,C_ROMDATA_W ),         
     conv_std_logic_vector( AN,C_ROMDATA_W ),         
     (others => '0'),                
                                     
                                     
     (others => '0'),                
     conv_std_logic_vector( CN,C_ROMDATA_W ),         
     conv_std_logic_vector( BP,C_ROMDATA_W ),         
     conv_std_logic_vector( BP+CN,C_ROMDATA_W ),      
     conv_std_logic_vector( BN,C_ROMDATA_W ),         
     conv_std_logic_vector( BN+CN,C_ROMDATA_W ),      
     (others => '0'),                
     conv_std_logic_vector( CN,C_ROMDATA_W ),         
     conv_std_logic_vector( CP,C_ROMDATA_W ),         
     (others => '0'),                
     conv_std_logic_vector( CP+BP,C_ROMDATA_W ),      
     conv_std_logic_vector( BP,C_ROMDATA_W ),         
     conv_std_logic_vector( CP+BN,C_ROMDATA_W ),      
     conv_std_logic_vector( BN,C_ROMDATA_W ),         
     conv_std_logic_vector( CP,C_ROMDATA_W ),         
     (others => '0')
     );                
  
begin 

  
  process(clk)
  begin
   if clk = '1' and clk'event then
    dout <= rom(CONV_INTEGER(UNSIGNED(addr)) ); 
   end if;
  end process;  
      
end RTL;    

                

