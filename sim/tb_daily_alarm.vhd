library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

use work.clock_types_pkg.all;

entity tb_daily_alarm is
end entity;

architecture test of tb_daily_alarm is
  constant day_seconds       : positive := 24 * 60 * 60;
  constant afternoon_match   : positive := 10 * 3600 + 45 * 60;
  constant midnight_match    : positive := 20 * 3600 + 30 * 60;

  signal clk          : std_logic := '0';
  signal reset        : std_logic := '1';
  signal tick_1s      : std_logic := '0';
  signal city_tehran  : std_logic := '0';
  signal format_12h   : std_logic := '1';
  signal view_sel     : std_logic_vector(1 downto 0) := "10";
  signal alarm_hour   : hour_24_t := 14;
  signal alarm_minute : minute_second_t := 15;
  signal alarm_enable : std_logic := '0';
  signal alarm_ack    : std_logic := '0';
  signal alarm_active : std_logic;
  signal seg_h10, seg_h1, seg_m10, seg_m1, seg_s10, seg_s1 : std_logic_vector(6 downto 0);
  signal pm, am_pm_valid : std_logic;

  function two_digits(value : natural) return string is
    constant digits : string := natural'image(100 + value);
  begin
    return digits(2 to 3);
  end function;

  function time_text(h, m, s : natural) return string is
  begin
    return two_digits(h) & ":" & two_digits(m) & ":" & two_digits(s);
  end function;
begin
  clk <= not clk after 5 ns;

  dut : entity work.digital_clock(structural)
    port map (
      clk => clk, reset => reset, tick_1s => tick_1s,
      city_tehran => city_tehran, format_12h => format_12h, view_sel => view_sel,
      countdown_load => '0', countdown_run => '0', stopwatch_run => '1', stopwatch_clear => '0',
      countdown_set_hour => 0, countdown_set_minute => 0, countdown_set_second => 0,
      alarm_hour => alarm_hour, alarm_minute => alarm_minute,
      alarm_enable => alarm_enable, alarm_ack => alarm_ack, alarm_active => alarm_active,
      seg_h10 => seg_h10, seg_h1 => seg_h1, seg_m10 => seg_m10,
      seg_m1 => seg_m1, seg_s10 => seg_s10, seg_s1 => seg_s1,
      pm => pm, am_pm_valid => am_pm_valid, countdown_done => open
    );

  stimulus : process
    alias gmt_hour is << signal .tb_daily_alarm.dut.gmt_hour : hour_24_t >>;
    alias gmt_minute is << signal .tb_daily_alarm.dut.gmt_minute : minute_second_t >>;
    alias gmt_second is << signal .tb_daily_alarm.dut.gmt_second : minute_second_t >>;
    alias tehran_hour is << signal .tb_daily_alarm.dut.tehran_hour : hour_24_t >>;
    alias tehran_minute is << signal .tb_daily_alarm.dut.tehran_minute : minute_second_t >>;

    procedure step(edges : positive := 1) is
    begin
      for edge_index in 1 to edges loop
        wait until rising_edge(clk);
      end loop;
      wait for 1 ns;
    end procedure;

    procedure check_alarm(
      scenario : string;
      expected_active : std_logic;
      expected_gmt, expected_tehran : string
    ) is
      constant observed_gmt : string := time_text(gmt_hour, gmt_minute, gmt_second);
      constant observed_tehran : string := time_text(tehran_hour, tehran_minute, gmt_second);
      constant observation : string :=
        " | expected GMT " & expected_gmt & ", Tehran " & expected_tehran &
        ", alarm=" & std_logic'image(expected_active) &
        " | observed GMT " & observed_gmt & ", Tehran " & observed_tehran &
        ", alarm=" & std_logic'image(alarm_active);
    begin
      assert alarm_active = expected_active and observed_gmt = expected_gmt and observed_tehran = expected_tehran
        report "FAIL: " & scenario & observation severity failure;
      report "PASS: " & scenario & observation severity note;
    end procedure;
  begin
    step;
    check_alarm("initial reset", '0', "00:00:00", "03:30:00");
    reset <= '0';
    tick_1s <= '1';
    step(afternoon_match - 1);
    check_alarm("day 1 before afternoon match", '0', "10:44:59", "14:14:59");
    step;
    check_alarm("day 1 reaches 14:15 with alarm disabled", '0', "10:45:00", "14:15:00");
    tick_1s <= '0';
    step;
    check_alarm("disabled alarm remains inactive on comparison edge", '0', "10:45:00", "14:15:00");

    alarm_enable <= '1';
    wait for 1 ns;
    check_alarm("enable has no effect before rising edge", '0', "10:45:00", "14:15:00");
    step;
    check_alarm("enable during matching minute with timer view, Greenwich and 12h selected",
                '1', "10:45:00", "14:15:00");
    city_tehran <= '1';
    format_12h <= '0';
    view_sel <= "00";
    step;
    check_alarm("active alarm survives city, format and view changes", '1', "10:45:00", "14:15:00");
    alarm_minute <= 16;
    step;
    check_alarm("active alarm survives rescheduling to a nonmatching minute", '1', "10:45:00", "14:15:00");
    alarm_minute <= 15;
    tick_1s <= '1';
    step(60);
    tick_1s <= '0';
    step;
    check_alarm("active alarm survives leaving scheduled minute", '1', "10:46:00", "14:16:00");
    alarm_enable <= '0';
    step;
    check_alarm("disable clears active alarm", '0', "10:46:00", "14:16:00");

    alarm_enable <= '1';
    step;
    check_alarm("enable outside scheduled minute", '0', "10:46:00", "14:16:00");
    alarm_minute <= 16;
    step;
    check_alarm("rescheduling to current unconsumed minute triggers without tick", '1', "10:46:00", "14:16:00");
    alarm_enable <= '0';
    step;
    check_alarm("disable clears alarm in matching minute", '0', "10:46:00", "14:16:00");
    alarm_enable <= '1';
    step;
    check_alarm("re-enable cannot retrigger in consumed minute", '0', "10:46:00", "14:16:00");

    alarm_minute <= 15;
    city_tehran <= '0';
    format_12h <= '1';
    tick_1s <= '1';
    step(day_seconds - 61);
    check_alarm("day 2 before afternoon match", '0', "10:44:59", "14:14:59");
    step;
    check_alarm("day 2 time-update edge precedes alarm sampling", '0', "10:45:00", "14:15:00");
    tick_1s <= '0';
    step;
    assert am_pm_valid = '1' and pm = '0'
      report "FAIL: expected Greenwich AM clock view at day 2 trigger" severity failure;
    check_alarm("day 2 trigger on next rising edge with tick_1s=0 and Greenwich 12h clock view",
                '1', "10:45:00", "14:15:00");

    alarm_ack <= '1';
    step;
    check_alarm("acknowledgement silences alarm in matching minute", '0', "10:45:00", "14:15:00");
    alarm_ack <= '0';
    step(2);
    check_alarm("no retrigger after releasing acknowledgement", '0', "10:45:00", "14:15:00");
    alarm_minute <= 16;
    step;
    alarm_minute <= 15;
    step;
    check_alarm("rescheduling away and back keeps minute consumed", '0', "10:45:00", "14:15:00");
    tick_1s <= '1';
    step(3);
    check_alarm("no retrigger after three more ticks within matching minute", '0', "10:45:03", "14:15:03");

    view_sel <= "10";
    step(day_seconds - 4);
    check_alarm("next day after consecutive ticks, before match", '0', "10:44:59", "14:14:59");
    step;
    check_alarm("next day time-update edge with timer displayed", '0', "10:45:00", "14:15:00");
    tick_1s <= '0';
    step;
    assert am_pm_valid = '0' report "FAIL: expected timer view at next-day trigger" severity failure;
    check_alarm("next day triggers again with timer view and tick_1s=0", '1', "10:45:00", "14:15:00");

    alarm_ack <= '1';
    step;
    check_alarm("acknowledge next-day alarm before midnight scenario", '0', "10:45:00", "14:15:00");
    alarm_ack <= '0';
    alarm_hour <= 0;
    alarm_minute <= 0;
    city_tehran <= '1';
    view_sel <= "00";
    tick_1s <= '1';
    step(midnight_match - afternoon_match - 1);
    check_alarm("one tick before Tehran midnight", '0', "20:29:59", "23:59:59");
    step;
    check_alarm("Tehran midnight time-update edge", '0', "20:30:00", "00:00:00");
    tick_1s <= '0';
    step;
    check_alarm("midnight alarm triggers on next rising edge without another tick", '1', "20:30:00", "00:00:00");

    reset <= '1';
    wait for 1 ns;
    check_alarm("synchronous reset leaves alarm active before rising edge", '1', "20:30:00", "00:00:00");
    step;
    check_alarm("reset clears alarm while enable remains high", '0', "00:00:00", "03:30:00");

    reset <= '0';
    alarm_hour <= 3;
    alarm_minute <= 30;
    alarm_ack <= '1';
    step;
    check_alarm("acknowledgement has priority on first matching sample", '0', "00:00:00", "03:30:00");
    alarm_ack <= '0';
    step;
    check_alarm("first-sample acknowledgement suppresses remaining minute", '0', "00:00:00", "03:30:00");

    report "PASS: all stage 4 alarm checks" severity note;
    finish;
  end process;
end architecture;
