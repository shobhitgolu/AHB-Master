

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;


library gnr;
use gnr.misc.all;

entity DMA_AHBM is 
  generic (
    hindex  : integer := 0;
    pindex  : integer := 0;
    paddr : integer := 0;
    pmask : integer := 16#fff#
  );
  port(
    rst   			 	: in  std_logic;
    clk   			 	: in  std_logic;
    -- CntEnb			 	: in  std_logic;
    ahbi 			 	: in  ahb_mst_in_type;
    ahbo 			 	: out ahb_mst_out_type;
	--spi signals 
	sclk 			    : in  std_logic;
    scs 			    : in  std_logic;
    mosi   			    : in  std_logic;
    miso   			    : out std_logic
	);
end;

architecture struct of DMA_AHBM is
--constant for APB slave values
--constant pconfig : apb_config_type := (
 -- 0 => ahb_device_reg ( 0, 0, 0, 0, 0),
 -- 1 => apb_iobar(paddr, pmask));
---------------------------------------------------- 
--spi pkt handler 
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
	regRdData		: in  std_logic_vector(31 downto 0);
	regRdOccpls		: out std_logic;
	dma_rd_en		: out std_logic; --read enable pls for dma 
    -- SPI signals
    sclk 			: in  std_logic;
    scs 			: in  std_logic;
    mosi   			: in  std_logic;
    miso   			: out std_logic
    );
end component;
-------------------------------------------------------------- 
--states for FSM
type DMA_state_type is (idle, read1, write1);

--signals for DMA FSM
signal DMAcntrlState   			 : DMA_state_type;
signal dmai 					 : ahb_dma_in_type;
signal dmao 					 : ahb_dma_out_type;
signal readDataFlg		 		 : std_logic;
signal ReadData			 		 : std_logic_vector(31 downto 0);

signal Wrpls		 			 : std_logic;
signal Rdakdpls		 			 : std_logic;
signal Wrakdpls		 			 : std_logic;
signal RdOccpls		 			 : std_logic;
signal dma_rd_en		 		 : std_logic;
signal AHBErrResp	 			 : std_logic;
signal dmao_startDel 			 : std_logic;
signal Rdstate		 			 : std_logic;
signal Wrstate		 			 : std_logic;

signal regRdAddr		   		 : std_logic_vector(31 downto 0);
signal RdAddr		   		 	 : std_logic_vector(31 downto 0);
signal WrAddr		   		 	 : std_logic_vector(31 downto 0);
signal regWrAddr		   		 : std_logic_vector(31 downto 0);
signal regWrData		   		 : std_logic_vector(31 downto 0);
signal regRdData		   		 : std_logic_vector(31 downto 0);
-- signal WordCount 				 : std_logic_vector(15 downto 0);

attribute syn_encoding : string;
attribute syn_encoding of DMAcntrlState: signal is "safe,onehot";

begin

-------------------------------------------------
--spi pkt handler port map: 
spiPacketHndlr0: spiPacketHndlr
port map(
		clk  			          => clk,
        rstn			          => rst,
        --data from spi           
        regWrAddr		          => regWrAddr,
        regWrData		          => regWrData,
        regWrpls		          => Wrpls,
        --data to spi interface`     
        regRdAddr		          => regRdAddr,
        regRdData		          => regRdData,
        regRdOccpls		          => RdOccpls,
        dma_rd_en		          => dma_rd_en,
		--spi signals             
        sclk 			          => sclk,
        scs 			          => scs, 
        mosi   			          => mosi,
        miso                      => miso
);		
---------------------------------------------------
-------------------------------------------------------
--ahb master inputs
dmai.burst <= '0'; 
dmai.size <= "10"; 
dmai.busy <= '0';
dmai.irq <= '0';
-------------------------------------------------------
ahbmst0 : ahbmst 
generic map (hindex => hindex, venid =>16#00#, devid => 16#000#) 
port map (rst, clk, dmai, dmao, ahbi, ahbo);
-------------------------------------------------------
--state machine to control ahb master inputs


process(clk, rst)
begin
	if rst= '0' then
	DMAcntrlState <= idle ;
	dmai.address<= (others=>'0');
	dmai.wdata<= (others=>'0');
	dmai.start  <= '0';
	Rdstate  <= '0';
	Wrstate  <= '0';
	dmai.write <= '0';
	regRdData <= (others=>'0');
	elsif rising_edge(clk) then
		case DMAcntrlState is
			when idle =>
				dmai.address<= (others=>'0');
				dmai.start  <= '0';
				dmai.write <= '0';
				dmai.wdata<= (others=>'0');
				
				if (wrpls = '1') then 
					DMAcntrlState <= write1;
					Wrstate <= '1';
					dmai.write <= '1';
					dmai.start <= '1';
					dmai.address <= (others=>'0');
					dmai.wdata<= (others=>'0');
				elsif(dma_rd_en = '1') then
					DMAcntrlState <= read1;
					Rdstate <= '1';
					dmai.write <= '0';
					dmai.start <= '1';
					dmai.address <= (others=>'0');
					regRdData <= (others=>'0');
				else
					DMAcntrlState <= idle;
				end if;
								
			when read1 =>
				if dmao.active = '1' then
					if dmao.start = '1' then
						if dmai.write = '0' then
							dmai.address <= RdAddr;
							regRdData <= dmao.rdata;
						else 
							DMAcntrlState <= idle;
						end if;
					end if;
					
					if dmao.ready = '1' then 
						DMAcntrlState <= idle;
				  	--	WordCount <= WordCount +1;
					--	DMAcntrlState <= write1;
					end if;
				end if;
				
			when write1 => 
				if dmao.active = '1' then
					if dmao.start = '1' then
						if dmai.write = '1' then
							dmai.address <= WrAddr;
							dmai.wdata <=  regWrData;
						else 
							DMAcntrlState <= idle;
							
						end if;
					end if;
				end if;
			when others => NULL;
		end case;
	end if;
end process;
-------------------------------------------------------------------
Wrakdpls <= Wrpls when DMAcntrlState = write1 and Wrstate = '1' else '0';
Rdakdpls <= RdOccpls when DMAcntrlState = read1 and Rdstate = '1' else '0';

-------------------------------------------------------------------
--Address increment.
-------------------------------------------------------------------
process(rst, clk)
begin
	if rst = '0' then
		ReadData <= (others=>'0');
		AHBErrResp <= '0';
		readDataFlg <= '0';
		dmao_startDel <= '0';
		WrAddr <= (others=>'0');
		RdAddr <= (others=>'0');
	elsif rising_edge(clk) then	
	    		
		if dma_rd_en = '0'  then
			RdAddr <= regRdAddr;
		elsif dmao.active = '1' and dmao.start = '1' and DMAcntrlState = read1 then
			RdAddr <= RdAddr + 4; --since each word is of 4 bytes
		end if;
			
		--Write address 
		if Wrpls = '0'  then
			WrAddr <= regWrAddr;
		elsif dmao.active = '1' and dmao.start = '1' and DMAcntrlState = write1 then
			WrAddr <= WrAddr + 4; --since each word is of 4 bytes
		end if;	
			
		--latch of the read data from the sram location
		if dmao.active = '1' and dmao.start = '1' and DMAcntrlState = read1 then
			readDataFlg <= '1';
		elsif dmao.active = '1' and dmao.ready = '1' and readDataFlg = '1' then
			readDataFlg <= '0';
		end if;
	
		if dmao.active = '1' and dmao.ready = '1' and readDataFlg = '1' then
			ReadData <= dmao.rdata; 
		end if;
				
		--raise error flag when error response is received.
		if dmao.mexc = '1' or dmao.retry = '1' then
			AHBErrResp <= '1';
		end if;
	end if;
end process;
end;