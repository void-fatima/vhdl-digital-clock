library ieee;
use ieee.std_logic_1164.all;

use work.clock_types_pkg.all;

entity seven_segment is
  port (
    digit    : in  digit_t;
    segments : out std_logic_vector(6 downto 0)
  );
end entity;

architecture rtl of seven_segment is
begin
  -- Active-high abcdefg. Bit 6 is a and bit 0 is g.
  with digit select segments <=
    "1111110" when 0,
    "0110000" when 1,
    "1101101" when 2,
    "1111001" when 3,
    "0110011" when 4,
    "1011011" when 5,
    "1011111" when 6,
    "1110000" when 7,
    "1111111" when 8,
    "1111011" when 9;
end architecture;
