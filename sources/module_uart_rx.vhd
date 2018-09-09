library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity module_uart_rx is
	port 
	(
		clk		     : in std_logic;
		data  		 : out std_logic_vector (7 downto 0); -- the byte out
		data_present : out std_logic; -- when byte is received data present is asserted for 1 clock cycle only
		serial_in    : in std_logic -- the serial input signal
	);
end module_uart_rx;

architecture module_uart_rx_ar of module_uart_rx is
	signal idle, t  : std_logic := '1'; 
	signal data_reg : std_logic_vector (7 downto 0);
begin
	-- clock divider for the sampling ticks
	M1 : entity work.module_clk_div (module_clk_div_ar)
			generic map (MAX_TICKS => 5208) -- 5208 ticks = (1/9600)/2 s = half bit's period
		 	port map (clk => clk, reset => idle, t => t);	
	--
	
	-- The receiver unit
	RX_UNIT : process (clk)
		variable sample_count : unsigned (7 downto 0) := (others => '0');
	begin
		if rising_edge (clk) then
			if idle = '1' then
				data_present <= '0';
				sample_count := (others => '0');
				idle <= serial_in; -- a start bit (serial_in = 0) results in idle = 0
			elsif t = '1' then
				sample_count := sample_count + 1;
			
				if sample_count = 19 then -- 10 middle samples + 9 edge samples = 19 total samples
					data_present <= serial_in;  -- if the stop bit = 1 then assert data_present one clock cycle
					idle <= '1'; -- done, go back to idle
				elsif sample_count (0) = '1' then -- odd counts are the middle samples
					data_reg <= serial_in & data_reg (7 downto 1); -- shift new bit into the register (notice that the start bit will be shift out of the byte)
				end if;
				end if;
			end if;
	end process;	
	
	-- data signal out
	data <= data_reg;
	--	
end module_uart_rx_ar;