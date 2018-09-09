library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity module_dualport_bram is
	generic 
	(
		WORD_WIDTH : integer := 8; -- WORD WIDTH (default is a BYTE)
		ADDR_WIDTH : integer := 12 -- ADDRESS WIDTH (default is 12 for 2^12 = 4K words)
	);
	
	port 
	(
		clk  	 : in std_logic;
		we 	 	 : in std_logic;
		addr_w 	 : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
		data_in  : in std_logic_vector (WORD_WIDTH - 1 downto 0);
		addr_r 	 : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
		data_out : out std_logic_vector (WORD_WIDTH - 1 downto 0)
	);
end module_dualport_bram;

architecture module_dualport_bram_ar of module_dualport_bram is
	-----------------------------------------------------------
	subtype WORD is std_logic_vector (WORD_WIDTH - 1 downto 0);
	type RAM_TYPE is array (0 to (2**ADDR_WIDTH) - 1) of WORD;
	-----------------------------------------------------------
	signal ram : RAM_TYPE;
begin
	process (clk)
	begin
		if rising_edge (clk) then	
			if we = '1' then	
				ram (to_integer (unsigned (addr_w))) <= data_in; 	 
			end if;
			
			data_out <= ram (to_integer (unsigned (addr_r)));
		end if;
	end process;
end module_dualport_bram_ar;
