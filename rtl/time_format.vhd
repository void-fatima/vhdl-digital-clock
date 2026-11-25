library ieee;
use ieee.std_logic_1164.all;

use work.clock_types_pkg.all;

entity time_format is
  port (
    gmt_hour       : in  hour_24_t;
    gmt_minute     : in  minute_second_t;
    gmt_second     : in  minute_second_t;
    city_tehran    : in  std_logic;
    format_12h     : in  std_logic;
    tehran_hour    : out hour_24_t;
    tehran_minute  : out minute_second_t;
    display_hour   : out hour_2digit_t;
    display_minute : out minute_second_t;
    display_second : out minute_second_t;
    pm             : out std_logic;
    am_pm_valid    : out std_logic
  );
end entity;

architecture rtl of time_format is
begin
  display_second <= gmt_second;

  convert_time : process (all)
    variable offset_hour   : natural range 0 to 27;
    variable offset_minute : natural range 0 to 89;
    variable selected_hour : hour_24_t;
  begin
    offset_hour   := gmt_hour + 3;
    offset_minute := gmt_minute + 30;
    if offset_minute >= 60 then
      offset_minute := offset_minute - 60;
      offset_hour   := offset_hour + 1;
    end if;
    if offset_hour >= 24 then
      offset_hour := offset_hour - 24;
    end if;
    tehran_hour   <= offset_hour;
    tehran_minute <= offset_minute;

    if city_tehran = '1' then
      selected_hour  := offset_hour;
      display_minute <= offset_minute;
    else
      selected_hour  := gmt_hour;
      display_minute <= gmt_minute;
    end if;

    display_hour <= selected_hour;
    pm           <= '0';
    am_pm_valid  <= '0';
    if format_12h = '1' then
      am_pm_valid <= '1';
      if selected_hour >= 12 then
        pm <= '1';
      end if;
      if selected_hour = 0 then
        display_hour <= 12;
      elsif selected_hour > 12 then
        display_hour <= selected_hour - 12;
      end if;
    end if;
  end process;
end architecture;
