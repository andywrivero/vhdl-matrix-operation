library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity module_buffer_uart is	
	port 
	(
		clk 			: in std_logic;
		rx_data  		: out std_logic_vector (7 downto 0); 
		rx_data_present : out std_logic;
		rx_read_ack		: in std_logic;
		tx_data  		: in std_logic_vector (7 downto 0);
		tx_data_present : in std_logic;
		tx_read_ack  	: out std_logic;
		serial_in    	: in std_logic;
		serial_out		: out std_logic
	);
end module_buffer_uart;

architecture module_buffer_uart_ar of module_buffer_uart is
	signal rx_buffer_full, 
		   rx_buffer_empty,
		   tx_buffer_full,
		   tx_buffer_empty  : std_logic;
	signal rxdp, txdp, txra : std_logic;
	signal rxd, txd  		: std_logic_vector (7 downto 0);
	signal clk_not 			: std_logic;
begin
	-- Buffer clock inverted
	clk_not <= not clk;

	-- the RX unit
	I_UART_RX : entity work.module_uart_rx (module_uart_rx_ar)
					port map
					(
						clk => clk,
						data => rxd,
						data_present => rxdp,
						serial_in => serial_in
					);

	-- Buffer for the RX unit
	I_RX_BUFFER : entity work.module_buffer (module_buffer_ar)
					port map
					(
						clk => clk_not,
						data_in => rxd,
						data_in_present => rxdp, 
						data_out => rx_data,
						data_out_read_ack => rx_read_ack,
						buffer_full => rx_buffer_full,
						buffer_empty => rx_buffer_empty
					); 

	-- the RX data present signal
	rx_data_present <= not rx_buffer_empty;
		
	-- the TX unit
	I_UART_TX : entity work.module_uart_tx (module_uart_tx_ar)
					port map
					(
						clk => clk,
						data => txd,
						data_present => txdp,
						read_ack => txra,
						serial_out => serial_out
					);  

	-- Buffer for the TX unit
	I_TX_BUFFER : entity work.module_buffer (module_buffer_ar)
					port map
					(
						clk => clk_not,
						data_in => tx_data,
						data_in_present => tx_data_present, 
						data_out => txd,
						data_out_read_ack => txra,
						buffer_full => tx_buffer_full,
						buffer_empty => tx_buffer_empty
					); 

	-- the TX data present signal
	txdp <= not tx_buffer_empty;

	-- TX read acknowledge
	process (clk_not)
	begin 
		if rising_edge (clk_not) then
			tx_read_ack <= tx_data_present and not tx_buffer_full; 
		end if;
	end process;
end module_buffer_uart_ar;

