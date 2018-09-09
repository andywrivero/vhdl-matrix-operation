library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity module_buffer is
	generic 
	(
		WORD_WIDTH : integer := 8; -- WORD WIDTH (default is a BYTE)
		ADDR_WIDTH : integer := 10 -- ADDRESS WIDTH (default width is 10 for 2^10 = 1K words)
	);
	
	port 
	(
		clk 			  : in std_logic;
		data_in 		  : in std_logic_vector (WORD_WIDTH - 1 downto 0);
		data_in_present   : in std_logic;
		data_out 		  : out std_logic_vector (WORD_WIDTH - 1 downto 0);
		data_out_read_ack : in std_logic;
		buffer_full 	  : out std_logic;
		buffer_empty 	  : out std_logic
	);
end module_buffer;

architecture module_buffer_ar of module_buffer is
	signal re, we, be, bf : std_logic;		   
	signal addr_r, addr_w : unsigned (ADDR_WIDTH - 1 downto 0) := (others => '0');
	signal data_out_reg   : std_logic_vector (WORD_WIDTH - 1 downto 0);
begin
	-- read/write enables
	we <= data_in_present and not bf; 
	re <= data_out_read_ack and not be;

	-- buffer status
	bf <= '1' when addr_r = addr_w + 1 else '0';
	be <= '1' when addr_r = addr_w else '0';
	
	-- buffer signals out
	buffer_full <= bf;
	buffer_empty <= be;
	
	-- dual-port BRAM instance
	I_BRAM_BUFFER : entity work.module_dualport_bram (module_dualport_bram_ar)
						generic map 
						(
							WORD_WIDTH => WORD_WIDTH,
							ADDR_WIDTH => ADDR_WIDTH
						)
						port map
						(
							clk => clk,
							we => we,
							addr_w => std_logic_vector (addr_w),
							data_in => data_in,
							addr_r => std_logic_vector (addr_r),
							data_out => data_out_reg
						);

	-- this controls the buffer 
	BUFFER_CONTROLLER : process (clk)
	begin
		if rising_edge (clk) then
			if re = '1' then
				addr_r <= addr_r + 1;
			end if;

			if we = '1' then
				addr_w <= addr_w + 1;
			end if;

			if we = '1' and be = '1' then
				data_out <= data_in;
			else
				data_out <= data_out_reg;
			end if;
		end if;
	end process;
end module_buffer_ar;
