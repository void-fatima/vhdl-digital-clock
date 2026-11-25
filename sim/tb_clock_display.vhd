library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

use work.clock_types_pkg.all;

entity tb_clock_display is
end entity;

architecture test of tb_clock_display is
  constant clock_period : time := 10 ns;
  type segment_table is array (digit_t) of std_logic_vector(6 downto 0);
  constant expected_patterns : segment_table := (
    "1111110", "0110000", "1101101", "1111001", "0110011",
    "1011011", "1011111", "1110000", "1111111", "1111011"
  );

  signal clk            : std_logic := '0';
  signal reset          : std_logic := '1';
  signal tick_1s        : std_logic := '0';
  signal city_tehran    : std_logic := '0';
  signal format_12h     : std_logic := '0';
  signal gmt_hour       : hour_24_t;
  signal gmt_minute     : minute_second_t;
  signal gmt_second     : minute_second_t;
  signal tehran_hour    : hour_24_t;
  signal tehran_minute  : minute_second_t;
  signal display_hour   : hour_2digit_t;
  signal display_minute : minute_second_t;
  signal display_second : minute_second_t;
  signal pm             : std_logic;
  signal am_pm_valid    : std_logic;
  signal seg_h10, seg_h1, seg_m10, seg_m1, seg_s10, seg_s1 : std_logic_vector(6 downto 0);
  signal decoder_digit    : digit_t := 0;
  signal decoder_segments : std_logic_vector(6 downto 0);

  function two_digits(value : natural) return string is
    constant digits : string := natural'image(100 + value);
  begin
    return digits(2 to 3);
  end function;

  function time_text(h, m, s : natural) return string is
  begin
    return two_digits(h) & ":" & two_digits(m) & ":" & two_digits(s);
  end function;

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
  clk <= not clk after clock_period / 2;

  core : entity work.clock_core(rtl)
    port map (
      clk => clk, reset => reset, tick_1s => tick_1s,
      gmt_hour => gmt_hour, gmt_minute => gmt_minute, gmt_second => gmt_second
    );

  formatter : entity work.time_format(rtl)
    port map (
      gmt_hour => gmt_hour, gmt_minute => gmt_minute, gmt_second => gmt_second,
      city_tehran => city_tehran, format_12h => format_12h,
      tehran_hour => tehran_hour, tehran_minute => tehran_minute,
      display_hour => display_hour, display_minute => display_minute, display_second => display_second,
      pm => pm, am_pm_valid => am_pm_valid
    );

  display : entity work.display_driver(structural)
    port map (
      display_hour => display_hour, display_minute => display_minute, display_second => display_second,
      seg_h10 => seg_h10, seg_h1 => seg_h1, seg_m10 => seg_m10,
      seg_m1 => seg_m1, seg_s10 => seg_s10, seg_s1 => seg_s1
    );

  decoder_probe : entity work.seven_segment(rtl)
    port map (digit => decoder_digit, segments => decoder_segments);

  stimulus : process
    variable elapsed_ticks : natural := 0;

    procedure advance_to(target_tick : natural) is
    begin
      for tick_index in elapsed_ticks + 1 to target_tick loop
        wait until rising_edge(clk);
      end loop;
      elapsed_ticks := target_tick;
      wait for 1 ns;
    end procedure;

    procedure check_display(
      scenario, expected_gmt, expected_display : string;
      expected_valid, expected_pm : std_logic
    ) is
      constant observed_gmt : string := time_text(gmt_hour, gmt_minute, gmt_second);
      constant observed_display : string :=
        read_digit(seg_h10) & read_digit(seg_h1) & ":" &
        read_digit(seg_m10) & read_digit(seg_m1) & ":" &
        read_digit(seg_s10) & read_digit(seg_s1);
      constant observation : string :=
        " | expected GMT " & expected_gmt & ", display " & expected_display &
        ", valid=" & std_logic'image(expected_valid) & ", pm=" & std_logic'image(expected_pm) &
        " | observed GMT " & observed_gmt & ", display " & observed_display &
        ", valid=" & std_logic'image(am_pm_valid) & ", pm=" & std_logic'image(pm);
    begin
      assert observed_gmt = expected_gmt and observed_display = expected_display
        and am_pm_valid = expected_valid and pm = expected_pm
        report "FAIL: " & scenario & observation severity failure;
      report "PASS: " & scenario & observation severity note;
    end procedure;

    procedure check_tehran(scenario, expected : string) is
      constant observed : string := time_text(tehran_hour, tehran_minute, gmt_second);
    begin
      assert observed = expected
        report "FAIL: " & scenario & " | expected " & expected & ", observed " & observed severity failure;
      report "PASS: " & scenario & " | expected " & expected & ", observed " & observed severity note;
    end procedure;
  begin
    for digit in expected_patterns'range loop
      decoder_digit <= digit;
      wait for 1 ns;
      assert decoder_segments = expected_patterns(digit)
        report "FAIL: decoder digit " & natural'image(digit) &
          " | expected " & to_string(expected_patterns(digit)) & ", observed " & to_string(decoder_segments)
        severity failure;
      report "PASS: decoder digit " & natural'image(digit) &
        " | expected " & to_string(expected_patterns(digit)) & ", observed " & to_string(decoder_segments)
        severity note;
    end loop;

    wait until rising_edge(clk);
    wait for 1 ns;
    check_display("Greenwich midnight in 24h", "00:00:00", "00:00:00", '0', '0');
    format_12h <= '1';
    wait for 1 ns;
    check_display("Greenwich midnight in 12h", "00:00:00", "12:00:00", '1', '0');

    format_12h <= '0';
    reset <= '0';
    tick_1s <= '1';
    advance_to(1 * 3600 + 2 * 60 + 3);
    check_display("leading zeros", "01:02:03", "01:02:03", '0', '0');

    advance_to(8 * 3600 + 30 * 60);
    city_tehran <= '1';
    format_12h <= '1';
    wait for 1 ns;
    check_display("Tehran noon in 12h", "08:30:00", "12:00:00", '1', '1');
    format_12h <= '0';
    wait for 1 ns;
    check_display("Tehran noon in 24h", "08:30:00", "12:00:00", '0', '0');

    city_tehran <= '0';
    advance_to(10 * 3600 + 45 * 60 + 20);
    check_display("Greenwich before city switch", "10:45:20", "10:45:20", '0', '0');
    check_tehran("Tehran time available with Greenwich selected", "14:15:20");
    city_tehran <= '1';
    wait for 1 ns;
    check_display("Tehran minute carry after city switch", "10:45:20", "14:15:20", '0', '0');
    advance_to(elapsed_ticks + 1);
    check_display("enabled edge after city switch", "10:45:21", "14:15:21", '0', '0');
    format_12h <= '1';
    wait for 1 ns;
    check_display("Tehran afternoon after format switch", "10:45:21", "02:15:21", '1', '1');
    advance_to(elapsed_ticks + 1);
    check_display("enabled edge after format switch", "10:45:22", "02:15:22", '1', '1');
    check_tehran("Tehran 24h time available in 12h mode", "14:15:22");
    city_tehran <= '0';
    wait for 1 ns;
    check_display("switch back to Greenwich in 12h", "10:45:22", "10:45:22", '1', '0');
    advance_to(elapsed_ticks + 1);
    check_display("enabled edge after switching back", "10:45:23", "10:45:23", '1', '0');

    advance_to(12 * 3600);
    check_display("Greenwich noon in 12h", "12:00:00", "12:00:00", '1', '1');
    format_12h <= '0';
    wait for 1 ns;
    check_display("Greenwich noon in 24h", "12:00:00", "12:00:00", '0', '0');
    advance_to(12 * 3600 + 34 * 60 + 56);
    check_display("six digit order", "12:34:56", "12:34:56", '0', '0');

    advance_to(15 * 3600 + 4 * 60 + 5);
    check_display("Greenwich afternoon in 24h", "15:04:05", "15:04:05", '0', '0');
    format_12h <= '1';
    wait for 1 ns;
    check_display("Greenwich afternoon in 12h", "15:04:05", "03:04:05", '1', '1');

    city_tehran <= '1';
    format_12h <= '0';
    advance_to(20 * 3600 + 29 * 60 + 59);
    check_display("one tick before Tehran midnight", "20:29:59", "23:59:59", '0', '0');
    check_tehran("Tehran time before rollover", "23:59:59");
    advance_to(elapsed_ticks + 1);
    check_display("Tehran midnight in 24h", "20:30:00", "00:00:00", '0', '0');
    check_tehran("Tehran time after rollover", "00:00:00");
    format_12h <= '1';
    wait for 1 ns;
    check_display("Tehran midnight in 12h", "20:30:00", "12:00:00", '1', '0');
    report "PASS: all stage 2 checks" severity note;
    finish;
  end process;
end architecture;
