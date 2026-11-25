library ieee;
use ieee.std_logic_1164.all;

use work.clock_types_pkg.all;

entity digital_clock is
  port (
    clk                  : in  std_logic;
    reset                : in  std_logic;
    tick_1s              : in  std_logic;
    city_tehran          : in  std_logic;
    format_12h           : in  std_logic;
    view_sel             : in  std_logic_vector(1 downto 0);
    countdown_load       : in  std_logic;
    countdown_set_hour   : in  hour_2digit_t;
    countdown_set_minute : in  minute_second_t;
    countdown_set_second : in  minute_second_t;
    countdown_run        : in  std_logic;
    stopwatch_run        : in  std_logic;
    stopwatch_clear      : in  std_logic;
    seg_h10              : out std_logic_vector(6 downto 0);
    seg_h1               : out std_logic_vector(6 downto 0);
    seg_m10              : out std_logic_vector(6 downto 0);
    seg_m1               : out std_logic_vector(6 downto 0);
    seg_s10              : out std_logic_vector(6 downto 0);
    seg_s1               : out std_logic_vector(6 downto 0);
    pm                   : out std_logic;
    am_pm_valid          : out std_logic;
    countdown_done       : out std_logic
  );
end entity;

architecture structural of digital_clock is
  signal gmt_hour                           : hour_24_t;
  signal gmt_minute, gmt_second             : minute_second_t;
  signal clock_hour                         : hour_2digit_t;
  signal clock_minute, clock_second         : minute_second_t;
  signal clock_pm, clock_am_pm_valid        : std_logic;
  signal countdown_hour                     : hour_2digit_t;
  signal countdown_minute, countdown_second : minute_second_t;
  signal stopwatch_hour                     : hour_2digit_t;
  signal stopwatch_minute, stopwatch_second : minute_second_t;
  signal display_hour                       : hour_2digit_t;
  signal display_minute, display_second     : minute_second_t;
begin
  core : entity work.clock_core(rtl)
    port map (
      clk => clk, reset => reset, tick_1s => tick_1s,
      gmt_hour => gmt_hour, gmt_minute => gmt_minute, gmt_second => gmt_second
    );

  formatter : entity work.time_format(rtl)
    port map (
      gmt_hour => gmt_hour, gmt_minute => gmt_minute, gmt_second => gmt_second,
      city_tehran => city_tehran, format_12h => format_12h,
      tehran_hour => open, tehran_minute => open,
      display_hour => clock_hour, display_minute => clock_minute, display_second => clock_second,
      pm => clock_pm, am_pm_valid => clock_am_pm_valid
    );

  timers : entity work.timer_engine(rtl)
    port map (
      clk => clk, reset => reset, tick_1s => tick_1s,
      countdown_load => countdown_load,
      countdown_set_hour => countdown_set_hour,
      countdown_set_minute => countdown_set_minute, countdown_set_second => countdown_set_second,
      countdown_run => countdown_run, stopwatch_run => stopwatch_run, stopwatch_clear => stopwatch_clear,
      countdown_hour => countdown_hour, countdown_minute => countdown_minute,
      countdown_second => countdown_second, countdown_done => countdown_done,
      stopwatch_hour => stopwatch_hour, stopwatch_minute => stopwatch_minute,
      stopwatch_second => stopwatch_second
    );

  select_display : process (all)
  begin
    pm          <= '0';
    am_pm_valid <= '0';
    case view_sel is
      when "01" =>
        display_hour   <= countdown_hour;
        display_minute <= countdown_minute;
        display_second <= countdown_second;
      when "10" =>
        display_hour   <= stopwatch_hour;
        display_minute <= stopwatch_minute;
        display_second <= stopwatch_second;
      when others =>
        display_hour   <= clock_hour;
        display_minute <= clock_minute;
        display_second <= clock_second;
        pm            <= clock_pm;
        am_pm_valid   <= clock_am_pm_valid;
    end case;
  end process;

  display : entity work.display_driver(structural)
    port map (
      display_hour => display_hour, display_minute => display_minute, display_second => display_second,
      seg_h10 => seg_h10, seg_h1 => seg_h1, seg_m10 => seg_m10,
      seg_m1 => seg_m1, seg_s10 => seg_s10, seg_s1 => seg_s1
    );
end architecture;
