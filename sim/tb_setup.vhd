library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

-- Toolchain check only; this is not the clock implementation.
entity tb_setup is
end entity;

architecture test of tb_setup is
  signal clk : std_logic := '0';
  signal sampled : std_logic := '0';
begin
  clk <= not clk after 5 ns;

  capture : process (clk)
  begin
    if rising_edge(clk) then
      sampled <= '1';
    end if;
  end process;

  stimulus : process
  begin
    assert sampled = '0' report "FAIL: initial value" severity failure;
    wait for 6 ns;
    assert sampled = '1' report "FAIL: rising-edge capture" severity failure;
    report "PASS: VHDL-2008 setup smoke test" severity note;
    finish;
  end process;
end architecture;
