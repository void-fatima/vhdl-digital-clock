library ieee;
use ieee.std_logic_1164.all;

library work;
use work.clock_types_pkg.all;

entity clock_core is
  port (
    clk        : in  std_logic;
    reset      : in  std_logic;
    tick_1s    : in  std_logic;
    gmt_hour   : out hour_24_t;
    gmt_minute : out minute_second_t;
    gmt_second : out minute_second_t
  );
end entity;

architecture rtl of clock_core is
  signal hour_reg   : hour_24_t;
  signal minute_reg : minute_second_t;
  signal second_reg : minute_second_t;
begin
  gmt_hour   <= hour_reg;
  gmt_minute <= minute_reg;
  gmt_second <= second_reg;

  timekeeping : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        hour_reg   <= 0;
        minute_reg <= 0;
        second_reg <= 0;
      elsif tick_1s = '1' then
        if second_reg < minute_second_t'high then
          second_reg <= second_reg + 1;
        else
          second_reg <= 0;
          if minute_reg < minute_second_t'high then
            minute_reg <= minute_reg + 1;
          else
            minute_reg <= 0;
            if hour_reg < hour_24_t'high then
              hour_reg <= hour_reg + 1;
            else
              hour_reg <= 0;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
end architecture;
