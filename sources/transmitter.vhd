library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity transmitter is
	port
	(	
		clk  	   : in std_logic;
		di   	   : out std_logic_vector (7 downto 0); -- data rx input
		dip  	   : out std_logic;
		do   	   : in std_logic_vector (7 downto 0); -- data tx output
		dop	 	   : in std_logic;
		doa  	   : out std_logic;
		serial_in  : in std_logic;
		serial_out : out std_logic
	);
end transmitter;

architecture transmitter_ar of transmitter is
	signal rx_data, tx_data : std_logic_vector (7 downto 0); 
	signal rx_data_present,
		   tx_data_present  : std_logic;
	signal rx_read_ack,
		   tx_read_ack      : std_logic;
begin
	-- buffered uart
	I_B_U : entity work.module_buffer_uart (module_buffer_uart_ar)
				port map 
				(
					clk => clk,
					rx_data => rx_data,
					rx_data_present => rx_data_present,
					rx_read_ack => rx_read_ack,
					tx_data => tx_data,
					tx_data_present => tx_data_present,
					tx_read_ack => tx_read_ack,
					serial_in => serial_in,
					serial_out => serial_out	
				);

	-- rx data routing
	di <= rx_data;
	dip <= rx_data_present;
	rx_read_ack <= rx_data_present; 
	--

	-- tx data routing
	tx_data <= rx_data when dop = '0' else do;
	tx_data_present <= rx_data_present or dop;
	doa <= dop and tx_read_ack;
end transmitter_ar;
