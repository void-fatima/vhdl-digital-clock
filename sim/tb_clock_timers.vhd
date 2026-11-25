library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

use work.clock_types_pkg.all;

entity tb_clock_timers is
  generic (test_stopwatch_limit : boolean := false);
end entity;

architecture test of tb_clock_timers is
  type segment_table is array (digit_t) of std_logic_vector(6 downto 0);
  constant expected_patterns : segment_table := (
    "1111110", "0110000", "1101101", "1111001", "0110011",
    "1011011", "1011111", "1110000", "1111111", "1111011"
  );

  signal clk                  : std_logic := '0';
  signal reset                : std_logic := '1';
  signal tick_1s              : std_logic := '0';
  signal city_tehran          : std_logic := '0';
  signal format_12h           : std_logic := '0';
  signal view_sel             : std_logic_vector(1 downto 0) := "00";
  signal countdown_load       : std_logic := '0';
  signal countdown_set_hour   : hour_2digit_t := 0;
  signal countdown_set_minute : minute_second_t := 0;
  signal countdown_set_second : minute_second_t := 0;
  signal countdown_run        : std_logic := '0';
  signal stopwatch_run        : std_logic := '0';
  signal stopwatch_clear      : std_logic := '0';
  signal pm, am_pm_valid, countdown_done : std_logic;
  signal seg_h10, seg_h1, seg_m10, seg_m1, seg_s10, seg_s1 : std_logic_vector(6 downto 0);

  function read_digit(segments : std_logic_vector(6 downto 0)) return character is
  begin
    for digit in expected_patterns'range loop
      if segments = expected_patterns(digit) then
        return character'val(character'pos('0') + digit);
      end if;
    end loop;
    return '?';
  end function;

  function two_digits(value : natural) return string is
    constant digits : string := natural'image(100 + value);
  begin
    return digits(2 to 3);
  end function;
begin
  clk <= not clk after 5 ns;

  dut : entity work.digital_clock(structural)
    port map (
      clk => clk, reset => reset, tick_1s => tick_1s,
      city_tehran => city_tehran, format_12h => format_12h, view_sel => view_sel,
      countdown_load => countdown_load, countdown_set_hour => countdown_set_hour,
      countdown_set_minute => countdown_set_minute, countdown_set_second => countdown_set_second,
      countdown_run => countdown_run, stopwatch_run => stopwatch_run, stopwatch_clear => stopwatch_clear,
      alarm_hour => 0, alarm_minute => 0, alarm_enable => '0', alarm_ack => '0', alarm_active => open,
      seg_h10 => seg_h10, seg_h1 => seg_h1, seg_m10 => seg_m10,
      seg_m1 => seg_m1, seg_s10 => seg_s10, seg_s1 => seg_s1,
      pm => pm, am_pm_valid => am_pm_valid, countdown_done => countdown_done
    );

  stimulus : process
    alias gmt_hour is << signal .tb_clock_timers.dut.gmt_hour : hour_24_t >>;
    alias gmt_minute is << signal .tb_clock_timers.dut.gmt_minute : minute_second_t >>;
    alias gmt_second is << signal .tb_clock_timers.dut.gmt_second : minute_second_t >>;

    procedure step(edges : positive := 1) is
    begin
      for edge_index in 1 to edges loop
        wait until rising_edge(clk);
      end loop;
      wait for 1 ns;
    end procedure;

    procedure select_view(view_code : std_logic_vector(1 downto 0)) is
    begin
      view_sel <= view_code;
      wait for 1 ns;
    end procedure;

    procedure load_countdown(h : hour_2digit_t; m, s : minute_second_t) is
    begin
      countdown_set_hour   <= h;
      countdown_set_minute <= m;
      countdown_set_second <= s;
      countdown_load       <= '1';
      step;
      countdown_load <= '0';
    end procedure;

    procedure check_display(
      scenario, expected : string;
      expected_valid : std_logic := '0'
    ) is
      constant observed : string :=
        read_digit(seg_h10) & read_digit(seg_h1) & ":" &
        read_digit(seg_m10) & read_digit(seg_m1) & ":" &
        read_digit(seg_s10) & read_digit(seg_s1);
      constant observation : string :=
        " | expected " & expected & ", valid=" & std_logic'image(expected_valid) & ", pm='0'" &
        " | observed " & observed & ", valid=" & std_logic'image(am_pm_valid) & ", pm=" & std_logic'image(pm);
    begin
      assert observed = expected and am_pm_valid = expected_valid and pm = '0'
        report "FAIL: " & scenario & observation severity failure;
      report "PASS: " & scenario & observation severity note;
    end procedure;

    procedure check_done(scenario : string; expected : std_logic) is
      constant observation : string :=
        " | expected done=" & std_logic'image(expected) & ", observed " & std_logic'image(countdown_done);
    begin
      assert countdown_done = expected report "FAIL: " & scenario & observation severity failure;
      report "PASS: " & scenario & observation severity note;
    end procedure;

    procedure check_greenwich(expected : string) is
      constant observed : string :=
        two_digits(gmt_hour) & ":" & two_digits(gmt_minute) & ":" & two_digits(gmt_second);
    begin
      assert observed = expected report "FAIL: hidden Greenwich time | expected " & expected &
        ", observed " & observed severity failure;
      report "PASS: hidden Greenwich time | expected " & expected & ", observed " & observed severity note;
    end procedure;
  begin
    step;
    if test_stopwatch_limit then
      select_view("10");
      reset <= '0';
      tick_1s <= '1';
      stopwatch_run <= '1';
      step(3599);
      check_display("stopwatch before hour carry", "00:59:59");
      step;
      check_display("stopwatch hour carry", "01:00:00");
      step(359998 - 3600);
      check_display("stopwatch one tick below limit", "99:59:58");
      step;
      check_display("stopwatch at limit", "99:59:59");
      step(3);
      check_display("stopwatch saturates after three extra ticks", "99:59:59");
      finish;
    end if;

    check_display("clock after initial reset", "00:00:00");
    select_view("01");
    check_display("countdown after initial reset", "00:00:00");
    check_done("completion after initial reset", '0');

    reset <= '0';
    tick_1s <= '1';
    countdown_run <= '1';
    step;
    check_done("running tick before any load", '0');
    load_countdown(0, 1, 0);
    check_display("load has priority over running tick", "00:01:00");
    check_done("completion after load", '0');
    step;
    check_display("countdown borrows from minutes", "00:00:59");

    countdown_run <= '0';
    for edge_index in 1 to 3 loop
      step;
      check_display("countdown paused on edge" & integer'image(edge_index), "00:00:59");
    end loop;
    countdown_run <= '1';
    step(58);
    check_display("resumed countdown one second before completion", "00:00:01");
    check_done("completion one second before zero", '0');
    step;
    check_display("countdown reaches zero", "00:00:00");
    check_done("completion at zero", '1');
    step(3);
    check_display("countdown stays at zero for three extra ticks", "00:00:00");
    check_done("completion remains asserted", '1');

    load_countdown(0, 0, 4);
    check_display("reload starts a new duration", "00:00:04");
    check_done("reload clears completion", '0');
    select_view("00");
    check_display("clock visible while countdown is running", "00:01:09");
    step(3);
    check_display("clock after three ticks with countdown hidden", "00:01:12");
    select_view("01");
    check_display("countdown progressed while hidden", "00:00:01");
    check_greenwich("00:01:12");
    step;
    check_display("countdown completes again after reload", "00:00:00");
    check_done("completion after reloaded duration", '1');
    check_greenwich("00:01:13");
    select_view("00");
    check_display("clock after progressing while hidden", "00:01:13");

    load_countdown(0, 0, 0);
    select_view("01");
    check_display("loaded zero", "00:00:00");
    check_done("zero load clears completion even on a running tick", '0');
    countdown_run <= '0';
    step(2);
    check_done("loaded zero does not complete while paused", '0');
    countdown_run <= '1';
    tick_1s <= '0';
    step(2);
    check_done("loaded zero waits for an enabled edge", '0');
    tick_1s <= '1';
    step;
    check_done("loaded zero completes on first running tick", '1');

    load_countdown(1, 0, 0);
    check_display("load an hour", "01:00:00");
    step;
    check_display("countdown borrows from hours", "00:59:59");

    select_view("10");
    check_display("stopwatch before start", "00:00:00");
    stopwatch_run <= '1';
    step;
    check_display("stopwatch starts on first running tick", "00:00:01");
    stopwatch_run <= '0';
    for edge_index in 1 to 3 loop
      step;
      check_display("stopwatch paused on edge" & integer'image(edge_index), "00:00:01");
    end loop;
    stopwatch_run <= '1';
    step(58);
    check_display("resumed stopwatch before minute carry", "00:00:59");
    step;
    check_display("stopwatch minute carry", "00:01:00");

    tick_1s <= '0';
    load_countdown(99, 59, 59);
    select_view("01");
    check_display("maximum countdown load with tick_1s=0", "99:59:59");
    city_tehran <= '1';
    wait for 1 ns;
    check_display("city does not affect countdown display", "99:59:59");
    format_12h <= '1';
    wait for 1 ns;
    check_display("format does not affect countdown display", "99:59:59");
    step(3);
    check_display("running countdown holds with tick_1s=0", "99:59:59");
    select_view("10");
    check_display("running stopwatch holds with tick_1s=0", "00:01:00");
    city_tehran <= '0';
    wait for 1 ns;
    check_display("city does not affect stopwatch display", "00:01:00");
    format_12h <= '0';
    wait for 1 ns;
    check_display("format does not affect stopwatch display", "00:01:00");
    city_tehran <= '1';
    format_12h <= '1';
    select_view("11");
    check_display("view 11 returns to formatted Tehran clock", "03:32:22", '1');

    tick_1s <= '1';
    stopwatch_clear <= '1';
    select_view("10");
    step;
    check_display("stopwatch clear has priority over running tick", "00:00:00");
    stopwatch_clear <= '0';
    step;
    check_display("stopwatch resumes on tick after clear", "00:00:01");

    reset <= '1';
    countdown_load <= '1';
    select_view("01");
    check_display("countdown still running before synchronous reset", "99:59:57");
    step;
    check_display("reset has priority over countdown load and tick", "00:00:00");
    check_done("completion after reset with load and tick", '0');
    select_view("10");
    check_display("reset clears running stopwatch", "00:00:00");

    report "PASS: all stage 3 functional checks" severity note;
    finish;
  end process;
end architecture;
