library ieee;
use ieee.std_logic_1164.all;

use work.clock_types_pkg.all;

entity daily_alarm is
  port (
    clk           : in  std_logic;
    reset         : in  std_logic;
    tehran_hour   : in  hour_24_t;
    tehran_minute : in  minute_second_t;
    alarm_hour    : in  hour_24_t;
    alarm_minute  : in  minute_second_t;
    alarm_enable  : in  std_logic;
    alarm_ack     : in  std_logic;
    alarm_active  : out std_logic
  );
end entity;

architecture rtl of daily_alarm is
  signal previous_hour   : hour_24_t;
  signal previous_minute : minute_second_t;
  signal minute_consumed : std_logic;
begin
  alarm_control : process (clk)
    variable new_minute : boolean;
  begin
    if rising_edge(clk) then
      if reset = '1' then
        previous_hour   <= 0;
        previous_minute <= 0;
        minute_consumed <= '0';
        alarm_active    <= '0';
      else
        new_minute := tehran_hour /= previous_hour or tehran_minute /= previous_minute;
        previous_hour   <= tehran_hour;
        previous_minute <= tehran_minute;
        if new_minute then
          minute_consumed <= '0';
        end if;

        if alarm_enable = '0' then
          alarm_active <= '0';
        elsif alarm_ack = '1' then
          alarm_active    <= '0';
          minute_consumed <= '1';
        elsif tehran_hour = alarm_hour and tehran_minute = alarm_minute
          and (new_minute or minute_consumed = '0') then
          -- A new minute can fire on its first sample, even if the old one was consumed.
          alarm_active    <= '1';
          minute_consumed <= '1';
        end if;
      end if;
    end if;
  end process;
end architecture;
