library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library work;
use work.clock_types_pkg.all;

entity tb_clock_core is
end entity;

architecture test of tb_clock_core is
  constant clock_period : time := 10 ns;
  constant ticks_per_day : positive := 24 * 60 * 60;

  signal clk        : std_logic := '0';
  signal reset      : std_logic := '1';
  signal tick_1s    : std_logic := '0';
  signal gmt_hour   : hour_24_t;
  signal gmt_minute : minute_second_t;
  signal gmt_second : minute_second_t;

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
  clk <= not clk after clock_period / 2;

  dut : entity work.clock_core(rtl)
    port map (
      clk        => clk,
      reset      => reset,
      tick_1s    => tick_1s,
      gmt_hour   => gmt_hour,
      gmt_minute => gmt_minute,
      gmt_second => gmt_second
    );

  stimulus : process
    procedure next_edge is
    begin
      wait until rising_edge(clk);
      wait for 1 ns;
    end procedure;

    procedure check_time(
      scenario : string;
      h, m, s  : natural;
      log_pass : boolean := true
    ) is
      constant expected : string := time_text(h, m, s);
      constant observed : string := time_text(gmt_hour, gmt_minute, gmt_second);
    begin
      assert gmt_hour = h and gmt_minute = m and gmt_second = s
        report "FAIL: " & scenario & " | expected " & expected & ", observed " & observed
        severity failure;
      if log_pass then
        report "PASS: " & scenario & " | expected " & expected & ", observed " & observed
          severity note;
      end if;
    end procedure;

    variable elapsed : natural;
  begin
    next_edge;
    check_time("initial reset", 0, 0, 0);

    reset <= '0';
    tick_1s <= '1';
    next_edge;
    check_time("one enabled rising edge", 0, 0, 1);

    tick_1s <= '0';
    for edge_index in 1 to 3 loop
      next_edge;
      check_time("hold with tick_1s=0, edge" & integer'image(edge_index), 0, 0, 1);
    end loop;

    reset <= '1';
    wait until falling_edge(clk);
    wait for 1 ns;
    check_time("reset asserted before the next rising edge", 0, 0, 1);
    next_edge;
    check_time("running clock reset with tick_1s=0", 0, 0, 0);

    reset <= '0';
    tick_1s <= '1';
    next_edge;
    check_time("count resumes after reset", 0, 0, 1);

    reset <= '1';
    next_edge;
    check_time("reset priority with tick_1s=1", 0, 0, 0);

    reset <= '0';
    -- Each enabled edge represents one elapsed second. Derive the reference
    -- time from total seconds, independently of the DUT's carry logic.
    for tick_index in 1 to ticks_per_day loop
      next_edge;
      elapsed := tick_index mod ticks_per_day;
      case tick_index is
        when 59 =>
          check_time("before minute rollover", 0, 0, 59);
        when 60 =>
          check_time("minute rollover", 0, 1, 0);
        when 3599 =>
          check_time("before hour rollover", 0, 59, 59);
        when 3600 =>
          check_time("hour rollover", 1, 0, 0);
        when 86399 =>
          check_time("before midnight rollover", 23, 59, 59);
        when 86400 =>
          check_time("midnight rollover", 0, 0, 0);
        when others =>
          check_time("consecutive tick" & integer'image(tick_index),
                     elapsed / 3600, (elapsed / 60) mod 60, elapsed mod 60,
                     log_pass => false);
      end case;
    end loop;
    report "PASS: all 86400 consecutive ticks checked" severity note;

    next_edge;
    check_time("first tick of the next day", 0, 0, 1);

    for tick_index in 1 to 3660 loop
      next_edge;
    end loop;
    check_time("all three counters nonzero before reset", 1, 1, 1);
    reset <= '1';
    next_edge;
    check_time("reset with tick_1s=1 clears all three counters", 0, 0, 0);
    finish;
  end process;
end architecture;
