library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

use work.clock_types_pkg.all;

entity tb_digital_clock is
end entity;

architecture test of tb_digital_clock is
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
  signal alarm_hour           : hour_24_t := 14;
  signal alarm_minute         : minute_second_t := 15;
  signal alarm_enable         : std_logic := '0';
  signal alarm_ack            : std_logic := '0';
  signal seg_h10, seg_h1, seg_m10, seg_m1, seg_s10, seg_s1 : std_logic_vector(6 downto 0);
  signal pm, am_pm_valid, countdown_done, alarm_active : std_logic;

  function read_digit(segments : std_logic_vector(6 downto 0)) return character is
  begin
    for digit in expected_patterns'range loop
      if segments = expected_patterns(digit) then
        return character'val(character'pos('0') + digit);
      end if;
    end loop;
    return '?';
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
      alarm_hour => alarm_hour, alarm_minute => alarm_minute,
      alarm_enable => alarm_enable, alarm_ack => alarm_ack,
      seg_h10 => seg_h10, seg_h1 => seg_h1, seg_m10 => seg_m10,
      seg_m1 => seg_m1, seg_s10 => seg_s10, seg_s1 => seg_s1,
      pm => pm, am_pm_valid => am_pm_valid, countdown_done => countdown_done, alarm_active => alarm_active
    );

  stimulus : process
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

    procedure load_duration(m, s : minute_second_t) is
    begin
      countdown_set_minute <= m;
      countdown_set_second <= s;
      countdown_load <= '1';
      step;
      countdown_load <= '0';
    end procedure;

    procedure check_outputs(
      scenario, expected_time : string;
      expected_valid : std_logic := '0';
      expected_pm    : std_logic := '0';
      expected_done  : std_logic := '0';
      expected_alarm : std_logic := '0'
    ) is
      constant observed_time : string :=
        read_digit(seg_h10) & read_digit(seg_h1) & ":" &
        read_digit(seg_m10) & read_digit(seg_m1) & ":" &
        read_digit(seg_s10) & read_digit(seg_s1);
      constant expected_flags : std_logic_vector(1 to 4) :=
        expected_valid & expected_pm & expected_done & expected_alarm;
      constant observed_flags : std_logic_vector(1 to 4) :=
        am_pm_valid & pm & countdown_done & alarm_active;
      constant observation : string :=
        " | display and flags(valid,pm,done,alarm) | expected " & expected_time & " " &
        to_string(expected_flags) & ", observed " & observed_time & " " & to_string(observed_flags);
    begin
      assert observed_time = expected_time and observed_flags = expected_flags
        report "FAIL: " & scenario & observation severity failure;
      report "PASS: " & scenario & observation severity note;
    end procedure;
  begin
    step;
    check_outputs("initial Greenwich 24h reset", "00:00:00");

    reset <= '0';
    countdown_run <= '1';
    stopwatch_run <= '1';
    load_duration(0, 5);
    select_view("01");
    check_outputs("load five-second countdown", "00:00:05");
    tick_1s <= '1';
    step;
    check_outputs("first simultaneous tick in timer view", "00:00:04");
    select_view("00");
    check_outputs("clock advanced while hidden", "00:00:01");
    step(2);
    check_outputs("clock continues over two ticks", "00:00:03");
    select_view("01");
    check_outputs("countdown advanced while hidden", "00:00:02");
    step;
    check_outputs("countdown just before completion", "00:00:01");
    select_view("00");
    check_outputs("clock before hidden countdown completion", "00:00:04");
    step;
    check_outputs("countdown completes while clock remains visible", "00:00:05", expected_done => '1');
    step;
    check_outputs("completion stays high on another clock tick", "00:00:06", expected_done => '1');
    select_view("01");
    check_outputs("completed countdown is zero when revealed", "00:00:00", expected_done => '1');

    view_sel <= "00";
    alarm_enable <= '1';
    -- Advance continuously from Greenwich 00:00:06 to 10:44:57.
    step(10 * 3600 + 44 * 60 + 57 - 6);
    check_outputs("Greenwich before afternoon alarm window", "10:44:57", expected_done => '1');
    tick_1s <= '0';
    load_duration(1, 10);
    select_view("01");
    check_outputs("reload clears done and displays the new duration", "00:01:10");
    city_tehran <= '1';
    wait for 1 ns;
    check_outputs("change city in timer view", "00:01:10");
    format_12h <= '1';
    wait for 1 ns;
    check_outputs("change format in timer view", "00:01:10");
    select_view("00");
    check_outputs("return to Tehran 12h clock", "02:14:57", expected_valid => '1', expected_pm => '1');
    select_view("01");
    check_outputs("timer view suppresses the clock PM outputs", "00:01:10");

    tick_1s <= '1';
    step(2);
    check_outputs("timer running one second before Tehran alarm minute", "00:01:08");
    step;
    check_outputs("Tehran enters alarm minute while countdown advances", "00:01:07");
    tick_1s <= '0';
    step;
    check_outputs("Tehran alarm starts in timer view without another tick", "00:01:07", expected_alarm => '1');
    select_view("00");
    check_outputs("alarm remains active in Tehran PM clock view", "02:15:00",
                  expected_valid => '1', expected_pm => '1', expected_alarm => '1');
    select_view("10");
    check_outputs("alarm remains active in stopwatch view", "10:45:00", expected_alarm => '1');
    select_view("01");
    check_outputs("alarm remains active when countdown returns", "00:01:07", expected_alarm => '1');

    alarm_ack <= '1';
    step;
    check_outputs("acknowledge alarm while the countdown is displayed", "00:01:07");
    alarm_ack <= '0';
    tick_1s <= '1';
    for second_in_minute in 1 to 59 loop
      step;
      assert alarm_active = '0'
        report "FAIL: alarm re-triggered at second" & natural'image(second_in_minute)
        severity failure;
    end loop;
    check_outputs("alarm stayed clear for the remaining 59 seconds", "00:00:08");

    alarm_minute <= 16;
    step;
    check_outputs("countdown still running on entry into next Tehran minute", "00:00:07");
    tick_1s <= '0';
    step;
    check_outputs("new alarm active while countdown is nonzero", "00:00:07", expected_alarm => '1');
    reset <= '1';
    tick_1s <= '1';
    countdown_load <= '1';
    wait for 1 ns;
    check_outputs("active timer and alarm before synchronous reset edge", "00:00:07", expected_alarm => '1');
    step;
    check_outputs("reset clears countdown, completion and alarm", "00:00:00");
    select_view("10");
    check_outputs("reset clears the running stopwatch", "00:00:00");
    select_view("00");
    check_outputs("reset Tehran clock with 12h selection retained", "03:30:00", expected_valid => '1');
    city_tehran <= '0';
    format_12h <= '0';
    wait for 1 ns;
    check_outputs("reset Greenwich clock in 24h mode", "00:00:00");

    report "PASS: all stage 5 integration checks" severity note;
    finish;
  end process;
end architecture;
