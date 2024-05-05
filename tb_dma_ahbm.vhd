------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library gnr;
use gnr.libdcom.all;
use gnr.leon3.all;
use gnr.memctrl.all;
use gnr.misc.all;

library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;
use work.SSR_CONFIG.all;

library techmap;
use techmap.gencomp.all;

use work.SIM_PACKAGE.all;

entity tb_dma_ahbm is
end tb_dma_ahbm;

architecture behavioral of tb_dma_ahbm is


component DMA_AHBM is
	-- ports
	port( 
         
	rst   			 	: in  std_logic;
    clk   			 	: in  std_logic;
    -- CntEnb			 	: in  std_logic;
    ahbi 			 	: in  ahb_mst_in_type;
    ahbo 			 	: out ahb_mst_out_type;
	sclk 			    : in  std_logic;
    scs 			    : in  std_logic;
    mosi   			    : in  std_logic;
    miso   			    : out std_logic

        );
end component;

component ahbctrl is
generic (
	defmast     : integer := 0;		-- default master
	split       : integer := 0;		-- split support
	rrobin      : integer := 0;		-- round-robin arbitration
	timeout     : integer range 0 to 255 := 0;  -- HREADY timeout
	ioaddr      : ahb_addr_type := 16#fff#;  -- I/O area MSB address
	iomask      : ahb_addr_type := 16#fff#;  -- I/O area address mask
	cfgaddr     : ahb_addr_type := 16#ff0#;  -- config area MSB address
	cfgmask     : ahb_addr_type := 16#ff0#;  -- config area address mask
	nahbm       : integer range 1 to NAHBMST := NAHBMST; -- number of masters
	nahbs       : integer range 1 to NAHBSLV := NAHBSLV; -- number of slaves
	ioen        : integer range 0 to 15 := 1;    -- enable I/O area
	disirq      : integer range 0 to 1 := 0;     -- disable interrupt routing
	fixbrst     : integer range 0 to 1 := 0;     -- support fix-length bursts
	debug       : integer range 0 to 2 := 2;     -- report cores to console
	fpnpen      : integer range 0 to 1 := 0; -- full PnP configuration decoding
	icheck      : integer range 0 to 1 := 1;
	devid       : integer := 0;		     -- unique device ID
	enbusmon    : integer range 0 to 1 := 0; --enable bus monitor
	assertwarn  : integer range 0 to 1 := 0; --enable assertions for warnings 
	asserterr   : integer range 0 to 1 := 0; --enable assertions for errors
	hmstdisable : integer := 0; --disable master checks           
	hslvdisable : integer := 0; --disable slave checks
	arbdisable  : integer := 0  --disable arbiter checks
	);
port (
	rst     : in  std_ulogic;
	clk     : in  std_ulogic;
	msti    : out ahb_mst_in_type;
	msto    : in  ahb_mst_out_vector;
	slvi    : out ahb_slv_in_type;
	slvo    : in  ahb_slv_out_vector
);
end component;	


component AHB_RAM_slave is
generic (
	-- AHB generics
	hindex 		: integer := 0;
	addr1		: integer := 16#D00#;
	addr1mask  	: integer := 16#FFF#;
	arrayinit   : integer := 0
	); 
port (
	rstn   					: in std_ulogic;
	Pclk    				: in std_ulogic;	
	-- AHB signals
	ahbsi   				: in  ahb_slv_in_type;
	ahbso   				: out ahb_slv_out_type	
	);
end component;

component mctrl_edac is
  generic (
    hindex    : integer := 0;
    pindex    : integer := 0;
    romaddr   : integer := 16#000#;
    rommask   : integer := 16#E00#;
    ioaddr    : integer := 16#200#;
    iomask    : integer := 16#E00#;
    ramaddr   : integer := 16#400#;
    rammask   : integer := 16#C00#;
    paddr     : integer := 0;
    pmask     : integer := 16#fff#;
    wprot     : integer := 0;
    invclk    : integer := 0;
    fast      : integer := 0;
    romasel   : integer := 28;
    sdrasel   : integer := 29;
    srbanks   : integer := 4;
    ram8      : integer := 0;
    ram16     : integer := 0;
    sden      : integer := 0;
    sepbus    : integer := 0;
    sdbits    : integer := 32;
    sdlsb     : integer := 2;          -- set to 12 for the GE-HPE board
    oepol     : integer := 0;
    syncrst   : integer := 0;
    pageburst : integer := 0;
    scantest  : integer := 0;
    mobile    : integer := 0
  );
  port (
    rst       : in  std_ulogic;
    clk       : in  std_ulogic;
    memi      : in  memory_in_type;
    memo      : out memory_out_type;
    ahbsi     : in  ahb_slv_in_type;
    ahbso     : out ahb_slv_out_type;
    -- apbi      : in  apb_slv_in_type;
    -- apbo      : out apb_slv_out_type;
    wpo       : in  wprot_out_type;
    sdo       : out sdram_out_type;
    TP_rdenbPls : out std_logic;
    TP_SECFlg : out std_logic;
    TP_DEDFlg : out std_logic;
    TP_mctrlHready : out std_logic
  );
end component;


component SDRAM_usermodel IS
    GENERIC (
        -- Timing Parameters for -75 (PC133) and CAS Latency = 2
        tAC       : TIME    :=  6.0 ns;
        tHZ       : TIME    :=  7.0 ns;
        tOH       : TIME    :=  2.7 ns;
        tMRD      : INTEGER :=  2;          -- 2 Clk Cycles
        tRAS      : TIME    := 44.0 ns;
        tRC       : TIME    := 66.0 ns;
        tRCD      : TIME    := 20.0 ns;
        tRP       : TIME    := 20.0 ns;
        tRRD      : TIME    := 15.0 ns;
        tWRa      : TIME    :=  7.5 ns;     -- A2 Version - Auto precharge mode only (1 Clk + 7.5 ns)
        tWRp      : TIME    := 15.0 ns;     -- A2 Version - Precharge mode only (15 ns)

        tAH       : TIME    :=  0.8 ns;
        tAS       : TIME    :=  1.5 ns;
        tCH       : TIME    :=  2.5 ns;
        tCL       : TIME    :=  2.5 ns;
        tCK       : TIME    := 10.0 ns;
        tDH       : TIME    :=  0.8 ns;
        tDS       : TIME    :=  1.5 ns;
        tCKH      : TIME    :=  0.8 ns;
        tCKS      : TIME    :=  1.5 ns;
        tCMH      : TIME    :=  0.8 ns;
        tCMS      : TIME    :=  1.5 ns;

        addr_bits : INTEGER := 13;
        data_bits : INTEGER := 16;
        col_bits  : INTEGER :=  10;
        index     : INTEGER :=  0;
		fname     : string := "sram.srec"	-- File to read from
    );
    PORT (
        Dq    : INOUT STD_LOGIC_VECTOR (data_bits - 1 DOWNTO 0) := (OTHERS => 'Z');
		Dout_enb	: OUT BIT;
        Addr  : IN    STD_LOGIC_VECTOR (addr_bits - 1 DOWNTO 0) := (OTHERS => '0');
        Ba    : IN    STD_LOGIC_VECTOR := "00";
        Clk   : IN    STD_LOGIC := '0';
        Cke   : IN    STD_LOGIC := '1';
        Cs_n  : IN    STD_LOGIC := '1';
        Ras_n : IN    STD_LOGIC := '1';
        Cas_n : IN    STD_LOGIC := '1';
        We_n  : IN    STD_LOGIC := '1';
        Dqm   : IN    STD_LOGIC_VECTOR (1 DOWNTO 0) := "00"
    );
END component;

SIGNAL rstn  				: std_logic;
SIGNAL Pclk  				: std_logic := '0';
-- SIGNAL apbsi 				: apb_slv_in_type;
-- SIGNAL apbso 				: apb_slv_out_type;
SIGNAL ahbmi 				: ahb_mst_in_type;
SIGNAL ahbmo 				: ahb_mst_out_vector:= (others => ahbm_none);
signal ahbsi     			: ahb_slv_in_type;
signal ahbso     			: ahb_slv_out_vector := (others => ahbs_none);
signal CntEnb       		: std_logic;
signal TP_ScrubStrtPls      : std_logic;

-- mem controller I/F signals from memctrl.vhd package
signal memi      	: memory_in_type;                 
signal memo      	: memory_out_type;
signal sdo       	: sdram_out_type;
signal sdcsn_sig      	:std_logic;
signal sdcke_sig      	:std_logic;
signal WR_Data_Sel		: std_logic_vector(31 downto 0);
signal WR_CB_Sel		: std_logic_vector(7 downto 0);

signal proc_add_int		: std_logic_vector(16 downto 0);
signal WR_Data_Sel_lt		: std_logic_vector(31 downto 0);
signal WR_CB_Sel_lt		: std_logic_vector(7 downto 0);
-- SDRAM signals
signal Ba_temp 				: std_logic_vector(1 downto 0);				

signal proc_addr 			: STD_LOGIC_VECTOR(18 downto 0);						
signal p_data				: STD_LOGIC_VECTOR(31 downto 0);
signal P_DtChk				: STD_LOGIC_VECTOR(7 downto 0);
signal checkBitsGen			: std_logic_vector(7 downto 0);	
signal SDRAM_CKE				: STD_LOGIC;					
signal SDRAM_CLK1			: STD_LOGIC;	
signal SDRAM1_Rasn			: STD_LOGIC;
signal SDRAM1_Casn			: STD_LOGIC;
signal SDRAM1_Wen			: STD_LOGIC;				
signal SDRAM_CLK2			: STD_LOGIC;	
signal SDRAM2_Wen			: STD_LOGIC;					
signal SDRAM2_Casn			: STD_LOGIC;					
signal SDRAM2_Rasn			: STD_LOGIC;					
signal SDRAM_CLK3			: STD_LOGIC;
signal SDRAM3_Wen			: STD_LOGIC;					
signal SDRAM3_Casn			: STD_LOGIC;					
signal SDRAM3_Rasn			: STD_LOGIC;					
signal SDRAM_CSn				: STD_LOGIC;					
signal SDRAM_BA0				: STD_LOGIC;					
signal SDRAM_BA1				: STD_LOGIC;						
signal SDRAM_UDQM			: STD_LOGIC;					
signal SDRAM_LDQM			: STD_LOGIC;	
signal Dqm_temp 				: std_logic_vector(1 downto 0);								

constant AHBS_RAM1_HINDEX		: integer := 6;
constant TBAHBS_RAM0_HADDR		: integer := 16#C00#;
constant TBAHBS_RAM1_HADDR		: integer := 16#D00#;
constant AHBS_RAM1_HMASK		: integer := 16#FFF#;



signal rst   			: std_logic;
signal clk   			: std_logic:='0';
-- signal CntEnb			: std_logic;
signal ahbi 			: ahb_mst_in_type;
signal ahbo 			: ahb_mst_out_type;
signal sclk 			: std_logic:='0';
signal scs 			    : std_logic;
signal mosi   			: std_logic:='0';
signal miso   			: std_logic;



procedure SPIWr (constant WrData : in std_logic_vector(7 downto 0); 
                 signal mosi: out std_logic);
				 
procedure AHBRead(
      constant   Data:        in   Std_Logic_Vector(31 downto 0);
      signal   AHBIn:         out   ahb_mst_in_type );


-- procedure Rd    (constant rd1: in std_logic_vector(31 downto 0);
				 -- signal regRdData0 :out std_logic_vector(31 downto 0));
				 
				 
				 
				 
				 
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


--AHBread  
 procedure AHBRead(
      constant   Data:        in   Std_Logic_Vector(31 downto 0);
      signal   AHBIn:         out   ahb_mst_in_type
	  ) is
      variable Temp:                Std_Logic_Vector(31 downto 0);
   begin
   
     wait until ((sclk'event) and (sclk = '1'));
      AHBIn.hgrant		<= (others => '0');
      AHBIn.hready		<= '1';
      AHBIn.hresp		<= HRESP_OKAY;
      AHBIn.hrdata		<= Data;
      AHBIn.hcache		<= '0';
      AHBIn.hirq  		<= (others => '0');
      AHBIn.testen		<= '0';
      AHBIn.testrst		<= '1';
      AHBIn.scanen 		<= '0';
      AHBIn.testoen 	<= '1';
     

end AHBread;


-- procedure Rd    (constant rd1: in std_logic_vector(31 downto 0);
				 -- signal regRdData0 :out std_logic_vector(31 downto 0)
				 -- ) is 
-- begin
	-- wait until ((sclk'event) and (sclk = '1'));
	-- regRdData0<=rd1;
	
-- end Rd;



begin

clk  <= not clk after 12.5 ns;
sclk <= not sclk after 50 ns;
rst   <= '0', '1' after 250 ns;
scs   <= '1', '0' after 350 ns;


	
    -- Instantiate Unit Under Test:  DMA_AHBM
DMA_AHBM_0 : DMA_AHBM
port map( 
	clk  			=> clk  	,		
    rst				=> rst		,
    ahbo			=> ahbo		,
    ahbi			=> ahbi		,
	-- CntEnb			=> CntEnb ,
    sclk 			=> sclk ,			
    scs 			=> scs, 			
    mosi   			=> mosi ,  			
    miso   			=> miso
            
);

----------------------------------------------------------------------
--AHB CONTROLLER
ahb0: ahbctrl           -- AHB arbiter/multiplexer
	generic map (
		defmast      => CFG_DEFMST,  	-- default AHB Master addr
		split        => CFG_SPLIT,   	-- Enable support for AHB split response
		rrobin       => CFG_RROBIN,  	-- Select either round robin or fixed priority
		ioaddr       => CFG_AHBIO,   	-- MSB 12 bits of I0addr area
		ioen         => IOAEN,       	-- Enable AHB I/O area
		nahbm        => CFG_MAXAHBM, 	-- Number of AHB Masters( Max = 16)
		nahbs        => CFG_MAXAHBS		-- Number of AHB Slaves ( Max = 16)
		)
	port map(
		rst          => rstn,        -- reset
		clk          => Pclk, 	 -- clk
		msti         => ahbmi,       -- AHB Master I/F input
		msto         => ahbmo,       -- AHB Master I/F output
		slvi         => ahbsi,       -- AHB Slave I/F input
		slvo         => ahbso
	);	
	
----------------------------------------------------------------------
--AHB RAM
AHB_RAM_slave0: AHB_RAM_slave
generic map(	hindex    	=> 0,
				addr1	  	=> TBAHBS_RAM0_HADDR,
				arrayinit   => 0,
				addr1mask 	=> AHBS_RAM0_HMASK
				)
port map(
	rstn   		=> rstn,         			-- reset
	Pclk    	=> Pclk,         			-- clk
	ahbsi  		=> ahbsi,        			-- AHB Slave I/F input
	ahbso  		=> ahbso(0) 	-- AHB Slave I/F output
	);	

AHB_RAM_slave1: AHB_RAM_slave
generic map(	hindex    	=> 1,
				addr1	  	=> TBAHBS_RAM1_HADDR,
				arrayinit   => 1,
				addr1mask 	=> AHBS_RAM1_HMASK
				)
port map(
	rstn   		=> rstn,         			-- reset
	Pclk    	=> Pclk,         			-- clk
	ahbsi  		=> ahbsi,        			-- AHB Slave I/F input
	ahbso  		=> ahbso(1) 	-- AHB Slave I/F output
	);

-----------------------------------------------------------
--memory controller for PROM and SDRAM --------------------
-----------------------------------------------------------
 memi.bwidth <= "10";
 memi.brdyn <= '1';
 memi.bexcn <= '1';
 memi.wrn <= "1111";
 memi.sd <= (others=>'0');
mctrl_edac_0: mctrl_edac 
  generic map(
    hindex    => AHBS_MCTRL_HINDEX,
	pindex    => APB_MCTRL_PINDEX,
	romaddr   => AHBS_MCTRL_ROM_HADDR,
	rommask   => AHBS_MCTRL_ROM_HMASK,
	ioaddr    => AHBS_MCTRL_IO_HADDR,
    iomask    => AHBS_MCTRL_IO_HMASK,
	ramaddr   => AHBS_MCTRL_RAM_HADDR,
    rammask   => AHBS_MCTRL_RAM_HMASK,
	paddr     => APB_MCTRL_PADDR,   
    pmask     => APB_MCTRL_PMASK,	
	ram8      => CFG_RAM8     ,
    ram16     => CFG_RAM16    ,
	srbanks   => CFG_SRBANKS  ,
    wprot     => CFG_WPROT    ,
    invclk    => CFG_INVCLK   ,
    fast      => CFG_FAST     ,
    romasel   => CFG_ROMASEL  ,
    sdrasel   => CFG_SDRASEL  ,
    sden      => CFG_SDEN     ,
    sepbus    => CFG_SEPBUS   ,
    sdbits    => CFG_SDBITS   ,
    oepol     => CFG_OEPOL    ,
    syncrst   => CFG_SYNCRST  ,
    pageburst => CFG_PAGEBURST,
    scantest  => CFG_SCANTEST ,
    mobile    => CFG_MOBILE   
  )
  port map(
    rst      => rstn,
    clk      => pclk,
    memi     => memi,
    memo     => memo ,
    ahbsi    => ahbsi,   
    ahbso    => ahbso(AHBS_MCTRL_HINDEX),
    -- apbi     => apbi,     
    -- apbo     => apbo(APB_MCTRL_PINDEX),  
    wpo      => wprot_out_none,
    sdo      => sdo
  );  	  

--------------------------------------------
-- Memory Signals

	SDRAM1_Wen <= sdo.sdwen;
	SDRAM2_Wen <= sdo.sdwen;
	
	SDRAM1_Casn <= sdo.casn;
	SDRAM2_Casn <= sdo.casn;	
	
	SDRAM1_Rasn <= sdo.rasn;
	SDRAM2_Rasn <= sdo.rasn;	
  
-- sdram CSn, BA0, BA1, CKE, CLk			
	sdcsn_sig <= sdo.sdcsn(0) and sdo.sdcsn(1);
	SDRAM_CSn <= sdcsn_sig;
	
	sdcke_sig <= sdo.sdcke(0) and sdo.sdcke(1);
	SDRAM_CKE <= sdcke_sig;  
	
	SDRAM_CLK1 <= pclk;
	SDRAM_CLK2 <= pclk;	
	
--sdram LDQM, UDQM				 
	
	SDRAM_LDQM <= sdo.dqm(0); 			  
	SDRAM_UDQM <= sdo.dqm(1);

--proc address
	proc_add_int<= memo.address(18 downto 2);
	
--proc data control signals	enb and dirn	  
	proc_busenb <= sdcsn_sig;	
	
--proc data bus				 
	WR_CB_Sel <= memo.cb(7 downto 0);
	WR_Data_Sel <= memo.data;	
	
	proc_data_latch:process(rstn, pclk)
	begin
		if rstn = '0' then
			WR_Data_Sel_lt <= (others=>'0');
			WR_CB_Sel_lt <= (others=>'0');
			p_add <= (others=>'0');
			SDRAM_BA0 <='0';
			SDRAM_BA1 <='0';
		elsif falling_edge(pclk) then
			WR_Data_Sel_lt<= WR_Data_Sel;
			WR_CB_Sel_lt<= WR_CB_Sel;
			p_add<= proc_add_int;
			SDRAM_BA0 <= memo.address(15);
			SDRAM_BA1 <= memo.address(16);
		end if;
	end process;
	
	p_data <= WR_Data_Sel_lt;
	P_DtChk <= WR_CB_Sel_lt;

---------------------------------------------------   

	proc_addr <= "00"&p_add(16 downto 0);
    
	Ba_temp <=  SDRAM_BA1 & SDRAM_BA0;
	Dqm_temp <= SDRAM_UDQM & SDRAM_LDQM;


--SDRAM MODEL
	SDRAM_0: SDRAM_usermodel
	GENERIC map (
			tMRD     		=> 1,		-- INTEGER :=  2;          -- 2 Clk Cycles
			addr_bits		=> 13,		-- INTEGER := 19;
			data_bits		=> 16,		-- INTEGER := 8;
			col_bits 		=> 10,		-- INTEGER :=  9;
			index    		=> 0,		-- INTEGER :=  0;
			fname     		=> sramfile		-- string := "sram.srec"	-- File to read from
		)
	port map(
			Dq    => p_data(31 downto 16),
			Dout_enb    => open,
			Addr  => proc_addr(12 downto 0),
			Ba    => Ba_temp,
			Clk   => SDRAM_CLK1,
			Cke   => SDRAM_CKE,
			Cs_n  => SDRAM_CSn,
			Ras_n => SDRAM1_Rasn,
			Cas_n => SDRAM1_Casn,
			We_n  => SDRAM1_Wen,
			Dqm   => Dqm_temp
		);	

	--data bits (15 downto 0)
	SDRAM_1: SDRAM_usermodel
	GENERIC map (
			tMRD     		=> 1,		-- INTEGER :=  2;          -- 2 Clk Cycles
			addr_bits		=> 13,		-- INTEGER := 19;
			data_bits		=> 16,		-- INTEGER := 8;
			col_bits 		=> 10,		-- INTEGER :=  9;
			index    		=> 16,		-- INTEGER :=  0;
			fname     		=> sramfile		-- string := "sram.srec"	-- File to read from
		)
	port map(
			Dq    => p_data(15 downto 0),
			Dout_enb    => Dout_enb,
			Addr  => proc_addr(12 downto 0),
			Ba    => Ba_temp,
			Clk   => SDRAM_CLK2,
			Cke   => SDRAM_CKE,
			Cs_n  => SDRAM_CSn,
			Ras_n => SDRAM2_Rasn,
			Cas_n => SDRAM2_Casn,
			We_n  => SDRAM2_Wen,
			Dqm   => Dqm_temp
		);		


bfm:	process
	begin
	wait until rst='1';
	-- Master to Slave
	
	SPIWr(x"02", mosi);
	SPIWr(x"04", mosi);
	SPIWr(x"40", mosi);
	SPIWr(x"00", mosi);
	SPIWr(x"00", mosi);
	SPIWr(x"01", mosi);
	SPIWr(x"03", mosi);
	SPIWr(x"12", mosi);
	SPIWr(x"34", mosi);
	SPIWr(x"56", mosi);
	SPIWr(x"78", mosi);
	
	-- SPIWr(x"03", mosi);
	-- SPIWr(x"04", mosi);
	-- SPIWr(x"40", mosi);
	-- SPIWr(x"00", mosi);
	-- SPIWr(x"00", mosi);
	-- SPIWr(x"01", mosi);
	-- SPIWr(x"A3", mosi);
	-- AHBRead(x"52645678", ahbi);

	
	
	-- Rd(x"52645678",ahbi.hrdata);
	

	
	--SPIRd(x"A5",ReadoutData,spi_reg_in,dataip_wr_pls_s);
	
	
	end process;
	
	
	
			

end behavioral;

