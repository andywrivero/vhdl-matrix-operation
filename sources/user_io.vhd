library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity user_io is
	port 
	(
		clk : in std_logic;
		RsRx : in std_logic;
		RsTx : out std_logic
	);
end user_io;

architecture user_io_ar of user_io is
	--------------------------- function is digit --------------------------------
	function is_ascii_digit (a : in std_logic_vector (7 downto 0)) return boolean is
		variable b : boolean;
	begin
		if a > x"29" and a < x"40" then
			b := true;
		else
			b := false;
		end if;

		return b;
	end function;

	--------------------------- function is separator --------------------------------
	function is_ascii_separator (a : in std_logic_vector (7 downto 0)) return boolean is
		variable b : boolean;
	begin
		if (a = x"20" or a = x"0D") then
			b := true;
		else
			b := false;
		end if;

		return b;
	end function;

	--------------------------- signals --------------------------------
	type state_type is (init, read_A_rows, read_A_cols, read_A_matrix, read_B_rows, read_B_cols, read_B_matrix, read_op, add_fetch, add_calc, add_rdy, mult_fetch, mult_calc, mult_rdy);
	signal state	  : state_type := init;
	signal di, 
		   di_reg 	  : std_logic_vector (7 downto 0); -- data rx input
	signal dip        : std_logic; -- data input present
	signal do         : std_logic_vector (7 downto 0); -- data tx output
	signal dop	      : std_logic := '0'; -- data out present
	signal doa        : std_logic; -- data output acknoledge
	signal rowsA, 
		   colsA, 
		   rowsB, 
		   colsB,
		   data_in,
		   tx_count	  : unsigned (15 downto 0) := (others => '0');
	signal addr_A,   
		   addr_B     : unsigned (15 downto 0);
	signal byteA_out,
		   byteB_out  : unsigned (7 downto 0);
	signal byteA_reg,
		   byteB_reg  : unsigned (7 downto 0) := (others => '0');
	signal clk_not,
		   weA, 
		   weB		  : std_logic;
	signal result     : unsigned (15 downto 0);
	signal bcd 	 	  : std_logic_vector (19 downto 0);
	signal tx_data,
		   cbcd 	  : std_logic_vector (23 downto 0) := x"FFFFFF";
	signal sizeA, 
		   sizeB,
		   sizeC	  : integer;
	signal new_sep,
		   new_dig	  : std_logic;
begin
	--------------------------- I/O transmitter --------------------------------
	dop <= '1' when state /= init and tx_data (23 downto 20) /= x"F" else '0';
	
	do <= x"20" when tx_data (23 downto 20) = x"A" else
		  x"3" & tx_data (23 downto 20);
	
	I_TRANSMITTER : entity work.transmitter (transmitter_ar)
						port map 
						(
							clk => clk,  
							di => di, 
							dip => dip, 
							do => do,
							dop	=> dop,
							doa => doa,
							serial_in => RsRx,
							serial_out => RsTx
						);

	--------------------------- process input data --------------------------------
	new_sep <= '1' when dip = '1' and is_ascii_separator (di) else '0';
	new_dig <= '1' when dip = '1' and is_ascii_digit (di) else '0';

	process (clk)
	begin
		if rising_edge (clk) then
			if new_sep = '1' or state = init then
				data_in <= (others => '0');
			elsif new_dig = '1' then
				data_in <= (shift_left (data_in, 3) + shift_left (data_in, 1)) + unsigned (di (3 downto 0));
			end if;
		end if;
	end process;

	--------------------------- transmit result --------------------------------
	process (clk)
	begin
		if rising_edge (clk) then
			if dop = '1' then
				if doa = '1' then
					tx_data <= tx_data (19 downto 0) & x"F";
				end if;
			elsif state = add_rdy or state = mult_rdy then
				tx_data <= cbcd;
				tx_count <= tx_count + 1;
			elsif state = init then
				tx_data <= x"FFFFFF";
				tx_count <= (others => '0');
			end if;
		end if;
	end process;

	--------------------------- BRAMs --------------------------------
	clk_not <= not clk;
	weA <= '1' when state = read_A_matrix else '0';
	weB <= '1' when state = read_B_matrix else '0';
	
	I_MA : entity work.module_bram (module_bram_ar) -- matrix A 
				generic map 
				(
					WORD_WIDTH => 8,
					ADDR_WIDTH => 16
				)
				port map
				(
					clk => clk_not,
					we => weA,
					addr => std_logic_vector (addr_A), 	 
					data_in => std_logic_vector (data_in (7 downto 0)),
					unsigned (data_out) => byteA_out
				);

	I_MB : entity work.module_bram (module_bram_ar) -- matrix B 
				generic map 
				(
					WORD_WIDTH => 8,
					ADDR_WIDTH => 16
				)
				port map
				(
					clk => clk_not,
					we => weB,
					addr => std_logic_vector (addr_B), 	 
					data_in => std_logic_vector (data_in (7 downto 0)),
					unsigned (data_out) => byteB_out
				);

	--------------------------- state controller --------------------------------
	STATE_CONTROLLER : process (clk)
	begin	
		if rising_edge (clk) then	
			case state is
				when init => -- initialization
					result <= (others => '0');
					addr_A <= (others => '0'); 
					addr_B <= (others => '0');
					state <= read_A_rows;

				when read_A_rows => -- read A rows
					rowsA <= data_in;

					if new_sep = '1' then
						state <= read_A_cols;
					end if;

				when read_A_cols => -- read A cols
					colsA <= data_in;

					if new_sep = '1' then
						state <= read_A_matrix;
					end if;

				when read_A_matrix => -- read matrix A
					if new_sep = '1' then
						addr_A <= addr_A + 1;
					
						if addr_A = sizeA - 1 then
							state <= read_B_rows;		
						end if;
					end if;

				when read_B_rows => -- read B rows
					rowsB <= data_in;

					if new_sep = '1' then
						state <= read_B_cols;
					end if;

				when read_B_cols => -- read B cols
					colsB <= data_in;

					if new_sep = '1' then
						state <= read_B_matrix;
					end if;

				when read_B_matrix => -- read matrix B
					if new_sep = '1' then
						addr_B <= addr_B + 1;
					
						if addr_B = sizeB - 1 then
							state <= read_op;		
						end if;
					end if;

				when read_op => -- read operation	
					addr_A <= (others => '0'); 
					addr_B <= (others => '0'); 

					if new_sep = '1' then
						if di_reg = x"2B" and rowsA = rowsB and colsA = colsB then -- + operation
							state <= add_fetch; -- add
						elsif di_reg = x"2A" and colsA = rowsB then -- * operation
							state <= mult_fetch; -- mult
						end if;
					end if;
				
				when add_fetch => -- addition fetch bytes
					byteA_reg <= byteA_out;
					byteB_reg <= byteB_out;
					addr_A <= addr_A + 1;
					addr_B <= addr_B + 1;
					state <= add_calc;
					
				when add_calc => -- addition calculation
					result <= (x"00" & byteA_reg) + (x"00" & byteB_reg);
					state <= add_rdy;
					
				when add_rdy => -- addition ready
					if dop = '0' then
						if tx_count = sizeA then
							state <= init;
						elsif tx_count /= sizeA - 1 then
							state <= add_fetch;
						end if;						
					end if;

				when mult_fetch => -- multiplication fetch bytes
					byteA_reg <= byteA_out;
					byteB_reg <= byteB_out;

					if addr_B = sizeB - 1 then
						addr_A <= addr_A + 1;
						addr_B <= (others => '0');
					elsif addr_B < sizeB - colsB then
						addr_A <= addr_A + 1;
						addr_B <= addr_B + colsB;
					else
						addr_A <= addr_A - (colsA - 1);
						addr_B <= addr_B - (sizeB - colsB - 1);
					end if;

					state <= mult_calc;

				when mult_calc => -- multiplication sum of products
					result <= result + byteA_reg * byteB_reg;

					if addr_B < colsB then
						state <= mult_rdy;
					else
						state <= mult_fetch;
					end if;

				when mult_rdy => -- multiplication ready
					if dop = '0' then
						if tx_count = sizeC then
							state <= init;
						elsif tx_count /= sizeC - 1 then
							state <= mult_fetch;
						end if;

						result <= (others => '0');						
					end if;		
			end case;

			-- save last input 
			if dip = '1' then
				di_reg <= di;
			end if;
		end if;
	end process;

	--------------------------- result to bcd --------------------------------
	I_b2b2 : entity work.module_bin2bcd (module_bin2bcd_ar)
				generic map (BIN_WIDTH => 16, BCD_WIDTH => 20)
				port map (bin => std_logic_vector (result), bcd => bcd);
	
	--------------------------- correct leading 0's --------------------------------
	cbcd <= bcd (3 downto 0) & x"AFFFF" when bcd (19 downto 4) = x"0000" else
			bcd (7 downto 0) & x"AFFF" when bcd (19 downto 8) = x"000" else
			bcd (11 downto 0) & x"AFF" when bcd (19 downto 12) = x"00" else
			bcd (15 downto 0) & x"AF" when bcd (19 downto 16) = x"0" else
			bcd & x"A";

	--------------------------- some other logic --------------------------------
	sizeA <= to_integer (rowsA * colsA);
	sizeB <= to_integer (rowsB * colsB);
	sizeC <= to_integer (rowsA * colsB);
end user_io_ar;
