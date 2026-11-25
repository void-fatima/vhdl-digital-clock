library ieee;
use ieee.std_logic_1164.all;

use work.clock_types_pkg.all;

entity timer_engine is
  port (
    clk                  : in  std_logic;
    reset                : in  std_logic;
    tick_1s              : in  std_logic;
    countdown_load       : in  std_logic;
    countdown_set_hour   : in  hour_2digit_t;
    countdown_set_minute : in  minute_second_t;
    countdown_set_second : in  minute_second_t;
    countdown_run        : in  std_logic;
    stopwatch_run        : in  std_logic;
    stopwatch_clear      : in  std_logic;
    countdown_hour       : out hour_2digit_t;
    countdown_minute     : out minute_second_t;
    countdown_second     : out minute_second_t;
    countdown_done       : out std_logic;
    stopwatch_hour       : out hour_2digit_t;
    stopwatch_minute     : out minute_second_t;
    stopwatch_second     : out minute_second_t
  );
end entity;

architecture rtl of timer_engine is
  signal countdown_loaded : std_logic;
begin
  count_down : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        countdown_hour   <= 0;
        countdown_minute <= 0;
        countdown_second <= 0;
        countdown_done   <= '0';
        countdown_loaded <= '0';
      elsif countdown_load = '1' then
        countdown_hour   <= countdown_set_hour;
        countdown_minute <= countdown_set_minute;
        countdown_second <= countdown_set_second;
        countdown_done   <= '0';
        countdown_loaded <= '1';
      elsif tick_1s = '1' and countdown_run = '1' and countdown_loaded = '1' then
        -- The first running tick at a loaded zero also completes the countdown.
        if countdown_hour = 0 and countdown_minute = 0 and countdown_second <= 1 then
          countdown_second <= 0;
          countdown_done   <= '1';
        elsif countdown_second /= 0 then
          countdown_second <= countdown_second - 1;
        else
          countdown_second <= minute_second_t'high;
          if countdown_minute /= 0 then
            countdown_minute <= countdown_minute - 1;
          else
            countdown_minute <= minute_second_t'high;
            countdown_hour   <= countdown_hour - 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  count_up : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' or stopwatch_clear = '1' then
        stopwatch_hour   <= 0;
        stopwatch_minute <= 0;
        stopwatch_second <= 0;
      elsif tick_1s = '1' and stopwatch_run = '1' then
        if stopwatch_second < minute_second_t'high then
          stopwatch_second <= stopwatch_second + 1;
        elsif stopwatch_minute < minute_second_t'high then
          stopwatch_second <= 0;
          stopwatch_minute <= stopwatch_minute + 1;
        elsif stopwatch_hour < hour_2digit_t'high then
          stopwatch_second <= 0;
          stopwatch_minute <= 0;
          stopwatch_hour   <= stopwatch_hour + 1;
        end if;
      end if;
    end if;
  end process;
end architecture;
