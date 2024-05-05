-- spi_decoder.vhd

--code assumes chapter 8 https: //www.nxp.com/docs/en/reference-manual/M68HC11RM.pdf
--CPOL='0' and CPHA = '1'

Library ieee;
Use ieee.std_logic_1164.all;
Use ieee.std_logic_arith.all;
Use ieee.std_logic_unsigned.all;

Entity spi_decoder is
 port (
	--system signals
    clk  			: in  std_logic;--should be 4 times spi-clk
    rstn			: in  std_logic;
    --data io interface
	dataip_wr_pls	: in  std_logic;
    spi_reg_in  	: in  std_logic_vector(7 downto 0);
	dataop_wr_pls	: out std_logic;
    spi_reg_out 	: out std_logic_vector(7 downto 0);
    -- SPI signals
    sclk 			: in  std_logic;
    scs 			: in  std_logic;
    mosi   			: in  std_logic;
    miso   			: out std_logic
    );
end entity ;

Architecture RTL of spi_decoder is
signal sample_sclk	 		: std_logic;
signal sample_sclk_lt 		: std_logic;
signal sample_sclk_lt2 		: std_logic;
signal sample_mosi	 	    : std_logic;
signal sample_mosi_lt 		: std_logic;
signal sample_mosi_lt2 		: std_logic;
signal sclk_rpls 			: std_logic;
-- signal sclk_Fpls 			: std_logic;
signal SerPar_Cntr   		: std_logic_vector(2 downto 0);
signal Data_SR	     		: std_logic_vector(7 downto 0);
signal dataSample	 		: std_logic;
signal dataSample_lt	 	: std_logic;
signal dataSamplePls	 	: std_logic;
signal dataop_wr_plsSig	 	: std_logic;
signal ParSer	     		: std_logic_vector(7 downto 0);
-- signal DataRdyFlag	 		: std_logic;
signal DataTosend	     	: std_logic_vector(7 downto 0);
signal dataop_wr_plsSig_lt	: std_logic;
signal dataop_wr_plsSig_lt2	: std_logic;
signal dataop_wr_plsSig_lt3	: std_logic;
signal miso_s				: std_logic;
signal miso_f				: std_logic;
-- signal dataop_wr_plsSig_lt4	: std_logic;

begin
--------------------------------------------------------------------
--sample spi-clock to indentify rising_edge of the clock
process(rstn, clk)
begin	
	if rstn = '0' then
		sample_sclk <= '1';
		sample_sclk_lt <= '1';
		sample_sclk_lt2 <= '1';
		sample_mosi <= '1';
		sample_mosi_lt <= '1';
		sample_mosi_lt2 <= '1';
	elsif rising_edge(clk) then
		sample_sclk <= sclk;
		sample_sclk_lt <= sample_sclk;
		sample_sclk_lt2 <= sample_sclk_lt;
		
		
		sample_mosi <= mosi;
		sample_mosi_lt <= sample_mosi;
		sample_mosi_lt2 <= sample_mosi_lt;
	end if;
end process;
sclk_rpls <= (not sample_sclk_lt) and sample_sclk;
-- sclk_rpls <= (not sample_sclk_lt) and sclk;
-- sclk_fpls <= sample_sclk_lt and (not sample_sclk);
--------------------------------------------------------------------
--shift in data from mosi when scs asserted and sclk_rise pls
Process(rstn,clk)
  begin
    if rstn ='0' then
		SerPar_Cntr 	<=(others=>'0'); 
		Data_SR 		<=(others=>'0');  
		dataSample_lt	<= '0';
    dataop_wr_plsSig    <= '0'; 
	dataop_wr_plsSig_lt  <='0';
	dataop_wr_plsSig_lt2 <='0';
	dataop_wr_plsSig_lt3 <='0';
	-- dataop_wr_plsSig_lt4 <='0';
	
    elsif rising_edge(clk) then
		if scs='0'  then
			if sclk_rpls='1' then 
				SerPar_Cntr <= SerPar_Cntr+'1';
				
				Data_SR 	<= Data_SR(6 downto 0) & sample_mosi_lt;
			end if;
		else
			SerPar_Cntr <=(others=>'0');  
			Data_SR 	<=(others=>'0');
		end if;
		

		dataSample_lt <= dataSample;
		dataop_wr_plsSig <= dataSamplePls ;
		dataop_wr_plsSig_lt <= dataop_wr_plsSig ;   -- latching 
		dataop_wr_plsSig_lt2 <= dataop_wr_plsSig_lt ;  
		dataop_wr_plsSig_lt3 <= dataop_wr_plsSig_lt2 ;  
		-- dataop_wr_plsSig_lt4 <= dataop_wr_plsSig_lt3 ;  
		
			
	end if;
end process;
spi_reg_out <= Data_SR;
dataop_wr_pls <= dataop_wr_plsSig_lt3;--3;
--sample 8 bit shift reg when count=31. sample and generate pulse ensure only one clock.
   dataSample <= '1' when SerPar_Cntr = "111" and scs='0' else '0';
dataSamplePls <= dataSample_lt and (not dataSample) and (not scs);
--------------------------------------------------------------------
--Shifting data to miso. after data write shift data out at rising edge of sck
DataTosend <= spi_reg_in;
Process(rstn,clk)
  begin
    if rstn = '0' then
      ParSer	 <= (others => '1');
    elsif rising_edge(clk) then 
				
		if scs='0' then    
			if dataip_wr_pls='1' then
				ParSer <= DataTosend;
			elsif sclk_rpls='1' then
				ParSer <= ParSer(6 downto 0) & '1';
			end if;
		else
			ParSer <= (others => '1');
		end if; 
    end if;
end process;
miso_s <= ParSer(7);  
--------------------------------------------------------------------
process(rstn,clk)
begin 
	if rstn = '0' then
		miso_f <= '1';
	elsif falling_edge(clk) then
		miso_f <= miso_s;
	end if;
end process;

process(rstn,sclk)
begin 
	if rstn = '0' then
		miso <= '1';
	elsif falling_edge(sclk) then
		miso <= miso_f;
	end if;
end process;
-------------------------------------
end RTL;

