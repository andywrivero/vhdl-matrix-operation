library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity module_uart_tx is
	port 
	(
		clk   		 : in std_logic;
		data  		 : in std_logic_vector (7 downto 0);
		data_present : in std_logic;
		read_ack  	 : out std_logic;
		serial_out	 : out std_logic 
	);
end module_uart_tx;

architecture module_uart_tx_ar of module_uart_tx is
	signal idle, t  : std_logic := '1';
	signal data_reg : std_logic_vector (8 downto 0);
begin
	-- clock divider for data transmition
	M1 : entity work.module_clk_div (module_clk_div_ar)
		 	generic map (MAX_TICKS => 10416) -- 10416 ticks = 1/9600 s = time period between transmited bits
		 	port map (clk => clk, reset => idle, t => t);
	--
	
	-- the transmiter unit
	TX_UNIT : process (clk)
		variable bit_count : unsigned (7 downto 0) := (others => '0');
	begin
		if rising_edge (clk) then
			if idle = '1' then		
				data_reg <= data & '0'; -- data + startbit
				idle <= not data_present;
				read_ack <= data_present; 
				bit_count := (others => '0');     	
			else		
				read_ack <= '0'; -- read_ack back to 0

				if t = '1' then
					data_reg <= '1' & data_reg (8 downto 1); -- shift right data_reg, and fill with 1 for the stop bit
					bit_count := bit_count + 1; -- increment number of transmited bits

					if bit_count = 10 then -- 1 startbit + 8 databits + 1 stopbit = 10 bits total
						idle <= '1';
					end if;
				end if;
			end if;
		end if;		
	end process;

	-- transmitted signal
	serial_out <= '1' when idle = '1' else data_reg (0);
	--
end module_uart_tx_ar;