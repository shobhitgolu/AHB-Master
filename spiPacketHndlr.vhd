-- spiPacketHndlr.vhd


Library ieee;
Use ieee.std_logic_1164.all;
Use ieee.std_logic_arith.all;
Use ieee.std_logic_unsigned.all;

Entity spiPacketHndlr is
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
	dma_rd_en		: out std_logic; --read enable pls for dma 
    -- SPI signals
    sclk 			: in  std_logic;
    scs 			: in  std_logic;
    mosi   			: in  std_logic;
    miso   			: out std_logic
    );
end entity ;

Architecture beh of spiPacketHndlr is

component spi_decoder is
 port (
	--system signals
    clk  			: in  std_logic;--should be 4 times spi-clk
    rstn			: in  std_logic;
    --data io interface
	dataip_wr_pls	: in std_logic;
    spi_reg_in  	: in  std_logic_vector(7 downto 0);
	dataop_wr_pls	: out std_logic;
    spi_reg_out 	: out std_logic_vector(7 downto 0);
    -- SPI signals
    sclk 			: in  std_logic;
    scs 			: in  std_logic;
    mosi   			: in  std_logic;
    miso   			: out std_logic
    );
end component ;

constant SPIREGWRITECMD	: std_logic_vector(7 downto 0) := x"02";
constant SPIREGREADCMD	: std_logic_vector(7 downto 0) := x"03";
constant SPIREGERRVAL	: std_logic_vector(7 downto 0) := x"5A";
constant DMARDEN		: std_logic_vector(7 downto 0) := x"A3";
type spipktstate_enum is (idle, datalength, addr1, addr2, addr3, addr4, sync,  data1, data2, data3, data4);

signal spipktstate	 			: spipktstate_enum;

signal regRdDataSel	 			: std_logic_vector(7 downto 0);

signal dataop_wr_pls	 		: std_logic;
signal dataop_wr_pls_lt	 		: std_logic;
signal dataop_wr_pls_lt2	 		: std_logic;
signal spi_reg_out	     		: std_logic_vector(7 downto 0);
signal packetErrorPls	     	: std_logic;
signal ByteCount	     		: std_logic_vector(7 downto 0);
signal spi_wrmode	     		: std_logic;
signal spi_rdmode	     		: std_logic;
signal spi_length	     		: std_logic_vector(7 downto 0);
signal spi_addr	     			: std_logic_vector(31 downto 0);
signal dataip_wr_pls	 		: std_logic;
-- signal spi_reg_in	     		: std_logic_vector(7 downto 0);
signal StatusReg	     		: std_logic_vector(7 downto 0);
begin
--------------------------------------------------------------------
--status reg is input when  spi_addr=x"FFFFFFFF" else input data
-- regRdDataSel <= StatusReg when spi_addr=x"FFFFFFFF" else regRdData;


--regRdDataSel <= StatusReg when spi_addr=x"FFFFFFFF" ;
		
--------------------------------------------------------------------
--spi decoder with output bytes of data
spi_decoder_0: spi_decoder
 port map(
    clk  			=> clk,				-- in  std_logic;--should be 4 times spi-clk
    rstn			=> rstn,			-- in  std_logic;
	dataip_wr_pls	=> dataip_wr_pls,	-- in std_logic;
    spi_reg_in  	=> regRdDataSel,	-- in  std_logic_vector(7 downto 0);
	dataop_wr_pls	=> dataop_wr_pls,	-- out std_logic;
    spi_reg_out 	=> spi_reg_out,		-- out std_logic_vector(7 downto 0);
    sclk 			=> sclk,			-- in  std_logic;
    scs 			=> scs,				-- in  std_logic;
    mosi   			=> mosi,			-- in  std_logic;
    miso   			=> miso				-- out std_logic
    );
--------------------------------------------------------------------
--spi packet decoder fsm
process(rstn,clk)
begin
	if rstn = '0' then
		dataop_wr_pls_lt <= '0';
		dataop_wr_pls_lt2 <= '0';
		StatusReg <= (others=>'0');
		spipktstate <= idle;
		packetErrorPls <= '0';
		ByteCount <= (others=>'0');
		spi_wrmode <= '0';
		spi_rdmode <= '0';
		regWrData <= (others=>'0');
		regRdDataSel <= (others=>'0');
		spi_length <= (others=>'0');
		spi_addr <= (others=>'0');
		dma_rd_en <= '0';
	elsif rising_edge(clk) then
	dataop_wr_pls_lt <= dataop_wr_pls;
	dataop_wr_pls_lt2 <= dataop_wr_pls_lt;
		case spipktstate is
			when idle =>	packetErrorPls <= '0';
							ByteCount <= (others=>'0');
							if scs='0' then
								if dataop_wr_pls = '1' then
									spipktstate <= datalength;
									if spi_reg_out = SPIREGWRITECMD then
										spi_wrmode <= '1';
										spi_rdmode <= '0';
									elsif spi_reg_out = SPIREGREADCMD then
										spi_wrmode <= '0';
										spi_rdmode <= '1';
									end if;
								end if;
							else
								spipktstate <= idle;
							end if;
							
			when datalength =>	packetErrorPls <= '0';
							ByteCount <= (others=>'0');
							if scs='0' then
								if dataop_wr_pls = '1' then
									spipktstate <= addr1;
									spi_length <= spi_reg_out;
								end if;
								-- if dataop_wr_pls_lt = '1' then
									-- spi_length <= spi_reg_out;
								-- end if;
							else
								spipktstate <= idle;
								packetErrorPls <= '1';
							end if;	
							
			when addr1 =>	packetErrorPls <= '0';
							ByteCount <= (others=>'0');
							if scs='0' then
								if dataop_wr_pls = '1' then
									spipktstate <= addr2;
									spi_addr(31 downto 24) <= spi_reg_out;
								end if;
							else
								spipktstate <= idle;
								packetErrorPls <= '1';
							end if;	
							
			when addr2 =>	packetErrorPls <= '0';
							ByteCount <= (others=>'0');
							if scs='0' then
								if dataop_wr_pls = '1' then
									spipktstate <= addr3;
									spi_addr(23 downto 16) <= spi_reg_out;
								end if;
							else
								spipktstate <= idle;
								packetErrorPls <= '1';
							end if;
							
			when addr3 => packetErrorPls <= '0';
							ByteCount <= (others=>'0');
							if scs='0' then
								if dataop_wr_pls = '1' then
									spipktstate <= addr4;
									spi_addr(15 downto 8) <= spi_reg_out;
								end if;
							else
								spipktstate <= idle;
								packetErrorPls <= '1';
							end if;
							
			when addr4 =>	packetErrorPls <= '0';
							ByteCount <= (others=>'0');
							if scs='0' then
								if dataop_wr_pls = '1' then
									spipktstate <= sync;
									spi_addr(7 downto 0) <= spi_reg_out;
								end if;								
							else
								spipktstate <= idle;
								packetErrorPls <= '1';
							end if;
							
			when sync => 	packetErrorPls <= '0';
							ByteCount <= (others=>'0');
							if scs='0' then
								if dataop_wr_pls = '1' then
									spipktstate <= data1;
									if 	spi_reg_out = DMARDEN and spi_rdmode = '1' then 
										dma_rd_en <= '1';
									end if;
								end if;
							else 
								spipktstate <= idle;
								packetErrorPls <= '1';
							end if;
										
			when data1  =>	packetErrorPls <= '0';
							ByteCount <= (others=>'0');
							if scs='0' then
								if dataop_wr_pls = '1' then
									spipktstate <= data2;
									if spi_wrmode = '1' then  
										regRdDataSel <= spi_reg_out;
										regWrData(31 downto 24) <= spi_reg_out;
									end if ;
								end if;
								if dataop_wr_pls_lt = '1' then 
									if spi_rdmode ='1'then
										regRdDataSel <= regRdData (31 downto 24);
									end if;
								end if;
							else
								spipktstate <= idle;
								packetErrorPls <= '1';
							end if;
							
			when data2 =>	packetErrorPls <= '0';
							ByteCount <= (others=>'0');
							if scs='0' then
								if dataop_wr_pls = '1' then
								spipktstate <= data3;
									if spi_wrmode = '1' then  
										regRdDataSel <= spi_reg_out;
										regWrData(23 downto 16) <= spi_reg_out;
									-- elsif spi_rdmode = '1'then
										-- regRdDataSel <= regRdData (23 downto 16);
									end if;
								end if;
								if dataop_wr_pls_lt = '1' then 
									if spi_rdmode ='1'then
										regRdDataSel <= regRdData (23 downto 16);
									end if;
								end if;
							else
								spipktstate <= idle;
								packetErrorPls <= '1';
							end if;
							
			when data3 =>	packetErrorPls <= '0';
							ByteCount <= (others=>'0');
							if scs='0' then
								if dataop_wr_pls = '1' then
								spipktstate <= data4;
									if spi_wrmode = '1' then  
										regRdDataSel <= spi_reg_out;
										regWrData(15 downto 8)<= spi_reg_out;
									-- elsif spi_rdmode = '1'then
										-- regRdDataSel <= regRdData (15 downto 8);
									end if;
								end if;
								if dataop_wr_pls_lt = '1' then 
									if spi_rdmode ='1'then
										regRdDataSel <= regRdData (15 downto 8);
									end if;
								end if;
							else
								spipktstate <= idle;
								packetErrorPls <= '1';
							end if;
							
			when data4 =>	packetErrorPls <= '0';
							ByteCount <= (others=>'0');
							if scs='0' then
								if dataop_wr_pls = '1' then
								spipktstate <= idle;
									if spi_wrmode = '1'then  
										regRdDataSel <= spi_reg_out;
										regWrData(7 downto 0)<= spi_reg_out;
									-- elsif spi_rdmode = '1'then
										-- regRdDataSel <= regRdData (7 downto 0);
									end if;
								end if;
								if dataop_wr_pls_lt = '1' then 
									if spi_rdmode ='1'then
										regRdDataSel <= regRdData (7 downto 0);
									end if;
								end if;
							else
								spipktstate <= idle;
								packetErrorPls <= '1';
							end if;
							
			-- when DataMD =>	packetErrorPls <= '0';
								-- if scs='0' then
									-- if dataop_wr_pls = '1' then
										-- if ByteCount <= spi_length-1 then
											-- spipktstate <= idle;
										-- else
											-- ByteCount <= ByteCount+1;
											-- spi_addr <= spi_addr+1;
										-- end if;
									-- end if;
								-- else
									-- spipktstate <= idle;
									-- packetErrorPls <= '1';
								-- end if;	
			when others => NULL;
		end case;
	end if;
end process;
--------------------------------------------------------------------
regWrAddr 	<= spi_addr;
-- regWrData 	<= spi_reg_out;
regWrpls	<= dataop_wr_pls when ((spipktstate = data1 or spipktstate = data2 or spipktstate = data3 or spipktstate = data4 ) and spi_wrmode='1' and spi_addr/=x"FFFF")  else '0';
regRdOccpls	<= dataip_wr_pls;
regRdAddr 	<= spi_addr;
dataip_wr_pls <= dataop_wr_pls_lt2 when ((spipktstate = data1 or spipktstate = data2 or spipktstate = data3 or spipktstate = data4) and spi_rdmode='1') else '0';--pls when in read mode.
--------------------------------------------------------------------
--delay out put dataop_wr_pls and route to dataip_wr_pls when in read mode.
--data read from address spi_addr is written in misoout reg with this pulse
-- process(rstn, clk)
-- begin
	-- if rstn = '0' then
		-- dataop_wr_pls_lt <= '0';
		-- StatusReg <= (others=>'0');
	-- elsif rising_edge(clk) then
		-- dataop_wr_pls_lt <= dataop_wr_pls;
		
		-- if dataop_wr_pls='1' and spi_addr=x"FFFF" and spipktstate=DataMD and  spi_wrmode = '1'then
			-- StatusReg <= spi_reg_out;
		-- elsif packetErrorPls='1' then
			-- StatusReg <= SPIREGERRVAL;
		-- end if;
	-- end if;
-- end process;
-- dataip_wr_pls <= dataop_wr_pls_lt when (spipktstate=DataMD and spi_rdmode='1') else '0';
--------------------------------------------------------------------
end beh;