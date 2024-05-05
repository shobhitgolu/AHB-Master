

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity testbench is
end testbench;

architecture behavioral of testbench is

component spiPacketHndlr is
 port (
	--system signals
    clk  			: in  std_logic;--should be 4 times spi-clk
    rstn			: in  std_logic;
    --data from spi interface
	regWrAddr		: out std_logic_vector(31 downto 0);
	regWrData		: out std_logic_vector(31 downto 0);
	regWrpls		: out std_logic;
	--data to spi interface`
	regRdAddr		: out std_logic_vector(31 downto 0);
	regRdData		: in std_logic_vector(31 downto 0);
	regRdOccpls		: out std_logic;
    -- SPI signals
    sclk 			: in  std_logic;
    scs 			: in  std_logic;
    mosi   			: in  std_logic;
    miso   			: out std_logic
    );
end component;


signal clk  				: std_logic:='0'; 
signal rstn		        	: std_logic; 
signal regWrAddr	    	: std_logic_vector(31 downto 0); 
signal regWrData	    	: std_logic_vector(31 downto 0); 
signal regWrpls	        	: std_logic; 
signal regRdAddr	    	: std_logic_vector(31 downto 0); 
signal regRdData	    	: std_logic_vector(31 downto 0):=(others=>'0'); 
signal regRdOccpls	    	: std_logic; 
signal sclk 		    	: std_logic:='0'; 
signal scs 		       	 	: std_logic; 
signal mosi   		   	 	: std_logic:='0'; 
signal miso   		    	: std_logic; 


procedure SPIWr (constant WrData : in std_logic_vector(7 downto 0); 
                 signal mosi: out std_logic);
procedure SPIRd (constant  SRLoadData:in std_logic_vector(7 downto 0); 
				 signal RdData : out std_logic_vector(7 downto 0);
				 signal spi_reg_in_ss : out std_logic_vector(7 downto 0);
				 signal dataip_wr_pls_o : out std_logic);

procedure Rd    (constant rd1: in std_logic_vector(31 downto 0);
				 signal regRdData0 :out std_logic_vector(31 downto 0));

procedure SPIWr( constant WrData : in std_logic_vector(7 downto 0);
				 signal mosi: out std_logic ) is
     -- procedure declarative part (constants, variables etc.)
	-- variable mosi: std_logic;
begin

     -- Sequential instructions 
	 wait until ((sclk'event) and (sclk = '1'));
	 MOSI<=WrData(7);
	 wait until ((sclk'event) and (sclk = '1'));
	 MOSI<=WrData(6);
	 wait until ((sclk'event) and (sclk = '1'));
	 MOSI<=WrData(5);
	 wait until ((sclk'event) and (sclk = '1'));
	 MOSI<=WrData(4);
	 wait until ((sclk'event) and (sclk = '1'));
	 MOSI<=WrData(3);
	 wait until ((sclk'event) and (sclk = '1'));
	 MOSI<=WrData(2);
	 wait until ((sclk'event) and (sclk = '1'));
	 MOSI<=WrData(1);
	 wait until ((sclk'event) and (sclk = '1'));
	 MOSI<=WrData(0);
	 
	 
	 -- for x in 7 to 0 loop
		-- wait until ((sclk'event) and (sclk = '1'));
		-- MOSI<=WrData(x);	
	 -- end loop;
end SPIWr;


procedure Rd    (constant rd1: in std_logic_vector(31 downto 0);
				 signal regRdData0 :out std_logic_vector(31 downto 0)
				 ) is 
begin
	wait until ((sclk'event) and (sclk = '1'));
	regRdData0<=rd1;
	
end Rd;
	
procedure SPIRd(constant SRLoadData:in std_logic_vector(7 downto 0);
                signal RdData : out std_logic_vector(7 downto 0);
				signal spi_reg_in_ss : out std_logic_vector(7 downto 0);
				signal dataip_wr_pls_o : out std_logic
				) is
     -- procedure declarative part (constants, variables etc.)
	 variable RdDataSH: std_logic_vector(7 downto 0);
	 variable dataip_wr_pls: std_logic;
begin
    -- DUT Signals
	dataip_wr_pls_o <= '1';
	spi_reg_in_ss <=SRLoadData;
	wait until ((sclk'event) and (sclk = '1'));
	dataip_wr_pls_o <= '0';
     
	 
	 -- Testbench functions
	 wait until ((sclk'event) and (sclk = '1'));
     RdDataSH(7):= miso;
	 wait until ((sclk'event) and (sclk = '1'));
	 RdDataSH(6):= miso;
	 wait until ((sclk'event) and (sclk = '1'));
	 RdDataSH(5):= miso;
	 wait until ((sclk'event) and (sclk = '1'));
	 RdDataSH(4):= miso;
	 wait until ((sclk'event) and (sclk = '1'));
	 RdDataSH(3):= miso;
	 wait until ((sclk'event) and (sclk = '1'));
	 RdDataSH(2):= miso;
	 wait until ((sclk'event) and (sclk = '1'));
	 RdDataSH(1):= miso;
	 wait until ((sclk'event) and (sclk = '1'));
	 RdDataSH(0):= miso;
	 RdData <=RdDataSH;
end SPIRd;

 
 
 begin


clk  <= not clk after 12.5 ns;
sclk <= not sclk after 50 ns;
rstn   <= '0', '1' after 250 ns;
scs   <= '1', '0' after 350 ns;

bfm:	process
	begin
	wait until rstn='1';
	-- Master to Slave
	
	SPIWr(x"03", mosi);
	SPIWr(x"04", mosi);
	SPIWr(x"40", mosi);
	SPIWr(x"00", mosi);
	SPIWr(x"00", mosi);
	SPIWr(x"01", mosi);
	SPIWr(x"A3", mosi);
	-- SPIWr(x"12", mosi);
	-- SPIWr(x"34", mosi);
	-- SPIWr(x"56", mosi);
	-- SPIWr(x"78", mosi);
	
	
	
	Rd(x"52645678", regRdData);
	
	
	
	--SPIRd(x"A5",ReadoutData,spi_reg_in,dataip_wr_pls_s);
	
	
	end process;




    -- Instantiate Unit Under Test:  spiPacketHndlr
   spiPacketHndlr_0: spiPacketHndlr 
  port map(
	clk  			=> clk  	,		
    rstn			=> rstn		,	    
    regWrAddr		=> regWrAddr	,	
    regWrData		=> regWrData,		
    regWrpls		=> regWrpls	,	    
    regRdAddr		=> regRdAddr,		
    regRdData		=> regRdData,		
    regRdOccpls		=> regRdOccpls,		
    sclk 			=> sclk ,			
    scs 			=> scs, 			
    mosi   			=> mosi ,  			
    miso   			=> miso   			
   );
    

end behavioral;

