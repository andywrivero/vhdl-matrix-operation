library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity module_clk_div is
    generic 
    (
        MAX_TICKS : integer := 1 -- the default is half the frequency
    );
     
    port
    (
        clk     : in std_logic;
        reset   : in std_logic;
        t       : out std_logic
    );
end module_clk_div;

architecture module_clk_div_ar of module_clk_div is
    signal t_counter : integer := 0;
begin
    -- reset of this clock divider is async.
    process (clk, reset)
    begin
        if reset = '1' then
            t_counter <= 0;
        elsif rising_edge(clk) then   
            if t_counter = MAX_TICKS then
                t_counter <= 0; -- reset counter
            else
                t_counter <= t_counter + 1; -- count 1 more
            end if;
        end if;
    end process;
    
    t <= '1' when t_counter = MAX_TICKS else '0';
end module_clk_div_ar;