
library ieee;
use ieee.std_logic_1164.all;
USE std.textio.all;
use ieee.std_logic_1164.STD_LOGIC;
Use ieee.std_logic_unsigned.all;

entity spi_decoder_tb is
end spi_decoder_tb;

architecture behavioral of spi_decoder_tb is
	constant SYSCLK_PERIOD : time := 25 ns; -- 40MHZ
	constant spiclk_prd    : time := 100 ns; --10MHz
    signal SYSCLK 		   : std_logic :='0';
    -- signal scs	 		   : std_logic :='0';
    signal miso 		   : std_logic :='0';
    signal mosi 		   : std_logic :='0';
    signal dataip_wr_pls_s : std_logic :='0';
    signal NSYSRESET 	   : std_logic :='0';
	signal spiclk 		   : std_logic :='0';
	signal scs		       : std_logic :='0';
	-- signal mosi_L1 		   : std_logic :='0';
	-- signal mosi_L2 		   : std_logic :='0';
	-- signal mosi_L3 		   : std_logic :='0';
	signal dataop_wr_pls   : std_logic;
	signal ReadoutData	   : std_logic_vector(7 downto 0):=(others=>'0');
	signal spi_reg_out	   : std_logic_vector(7 downto 0);
	signal spi_reg_in	   : std_logic_vector(7 downto 0):=(others=>'0');
	-- signal counter 		   : std_logic_vector(3 downto 0);
	
	
	
procedure SPIWr (constant WrData : in std_logic_vector(7 downto 0); 
                 signal mosi: out std_logic);
procedure SPIRd (constant  SRLoadData:in std_logic_vector(7 downto 0); 
				 signal RdData : out std_logic_vector(7 downto 0);
				 signal spi_reg_in_ss : out std_logic_vector(7 downto 0);
				 signal dataip_wr_pls_o : out std_logic);



procedure SPIWr( constant WrData : in std_logic_vector(7 downto 0);
				 signal mosi: out std_logic ) is
     -- procedure declarative part (constants, variables etc.)
	-- variable mosi: std_logic;
begin

     -- Sequential instructions 
	 wait until ((spiclk'event) and (spiclk = '1'));
	 MOSI<=WrData(7);
	 wait until ((spiclk'event) and (spiclk = '1'));
	 MOSI<=WrData(6);
	 wait until ((spiclk'event) and (spiclk = '1'));
	 MOSI<=WrData(5);
	 wait until ((spiclk'event) and (spiclk = '1'));
	 MOSI<=WrData(4);
	 wait until ((spiclk'event) and (spiclk = '1'));
	 MOSI<=WrData(3);
	 wait until ((spiclk'event) and (spiclk = '1'));
	 MOSI<=WrData(2);
	 wait until ((spiclk'event) and (spiclk = '1'));
	 MOSI<=WrData(1);
	 wait until ((spiclk'event) and (spiclk = '1'));
	 MOSI<=WrData(0);
	 
	 
	 -- for x in 7 to 0 loop
		-- wait until ((spiclk'event) and (spiclk = '1'));
		-- MOSI<=WrData(x);	
	 -- end loop;
end SPIWr;




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
	wait until ((spiclk'event) and (spiclk = '1'));
	dataip_wr_pls_o <= '0';
     
	 
	 -- Testbench functions
	 wait until ((spiclk'event) and (spiclk = '1'));
     RdDataSH(7):= miso;
	 wait until ((spiclk'event) and (spiclk = '1'));
	 RdDataSH(6):= miso;
	 wait until ((spiclk'event) and (spiclk = '1'));
	 RdDataSH(5):= miso;
	 wait until ((spiclk'event) and (spiclk = '1'));
	 RdDataSH(4):= miso;
	 wait until ((spiclk'event) and (spiclk = '1'));
	 RdDataSH(3):= miso;
	 wait until ((spiclk'event) and (spiclk = '1'));
	 RdDataSH(2):= miso;
	 wait until ((spiclk'event) and (spiclk = '1'));
	 RdDataSH(1):= miso;
	 wait until ((spiclk'event) and (spiclk = '1'));
	 RdDataSH(0):= miso;
	 RdData <=RdDataSH;
end SPIRd;


    component spi_decoder
        -- ports
        port( 
            -- Inputs
            clk 			: in std_logic;
            rstn 			: in std_logic;
            dataip_wr_pls   : in std_logic;
            spi_reg_in 		: in std_logic_vector(7 downto 0);
            SCLK 			: in std_logic;
            scs 			: in std_logic;
            mosi 			: in std_logic;

            -- Outputs
            dataop_wr_pls   : out std_logic;
            spi_reg_out 	: out std_logic_vector(7 downto 0);
            miso 			: out std_logic


        );
    end component;
	
	
	
begin

    -- Clock Driver
    SYSCLK <= not SYSCLK after (SYSCLK_PERIOD / 2.0 );
	spiclk <= not spiclk after (spiclk_prd / 2.0 );
	NSYSRESET <= '0', '1' after 60 ns;
	-- dataip_wr_pls_s <= '0', '1' after 75 ns, '0' after 110 ns;
	-- process(SYSCLK, NSYSRESET)
	-- begin
	-- if NSYSRESET = '0' then
		-- counter		 <= (others=>'0'); 
		-- spi_reg_in_s <= (others=>'0'); 
	-- elsif rising_edge(SYSCLK) then
		-- counter <= counter + 1;
		-- -- if counter = 10 then
			-- -- dataip_wr_pls_s <= '1';
			-- -- spi_reg_in_s 	<= x"a5";
		-- -- else
			-- -- dataip_wr_pls_s <= '0';
			-- -- spi_reg_in_s 	<= (others=>'0');
		-- -- end if;
	-- end if;
	-- end process;
	
bfm:	process
	begin
	wait until NSYSRESET='1';
	-- Master to Slave
	
	SPIWr(x"55", mosi);
	
	wait for 20 ns;
	SPIWr(x"0F", mosi);
	
	
	
	-- Slave to Master
	
	SPIRd(x"A5",ReadoutData,spi_reg_in,dataip_wr_pls_s);
	SPIRd(x"AA",ReadoutData,spi_reg_in,dataip_wr_pls_s);
	SPIRd(x"A5",ReadoutData,spi_reg_in,dataip_wr_pls_s);
	SPIRd(x"AF",ReadoutData,spi_reg_in,dataip_wr_pls_s);
	end process;
	
	
	
	-- process(SYSCLK, NSYSRESET)
	-- begin
	-- if NSYSRESET = '0' then
		-- mosi_L1	<= '0';
	    -- mosi_L2	<= '0';
	    -- mosi_L3	<= '0';
	-- elsif rising_edge(SYSCLK) then
		-- mosi_L1  <= miso;
		-- mosi_L2  <= mosi_L1;
		-- mosi_L3  <= mosi_L2;

	-- end if;
	-- end process;
	
	
-- mosi <= mosi_L3;	
	
	 
	
    -- Instantiate Unit Under Test:  spi_decoder
    spi_decoder_0 : spi_decoder
        -- port map
        port map( 
            -- Inputs
            clk 			=> SYSCLK,
            rstn 			=> NSYSRESET,
            dataip_wr_pls   => dataip_wr_pls_s ,
            spi_reg_in 		=> spi_reg_in,--x"a5",
            sclk 			=> spiclk,
            scs 			=> scs,
            mosi 			=> mosi,

            -- Outputs
            dataop_wr_pls   =>  dataop_wr_pls,
            spi_reg_out 	=>  spi_reg_out,
            miso 			=>  miso

        );
	
		
end behavioral;

