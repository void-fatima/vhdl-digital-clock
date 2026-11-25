library ieee;
use ieee.std_logic_1164.all;

use work.clock_types_pkg.all;

entity display_driver is
  port (
    display_hour   : in  hour_2digit_t;
    display_minute : in  minute_second_t;
    display_second : in  minute_second_t;
    seg_h10        : out std_logic_vector(6 downto 0);
    seg_h1         : out std_logic_vector(6 downto 0);
    seg_m10        : out std_logic_vector(6 downto 0);
    seg_m1         : out std_logic_vector(6 downto 0);
    seg_s10        : out std_logic_vector(6 downto 0);
    seg_s1         : out std_logic_vector(6 downto 0)
  );
end entity;

architecture structural of display_driver is
begin
  h10 : entity work.seven_segment(rtl)
    port map (digit => display_hour / 10, segments => seg_h10);
  h1 : entity work.seven_segment(rtl)
    port map (digit => display_hour mod 10, segments => seg_h1);
  m10 : entity work.seven_segment(rtl)
    port map (digit => display_minute / 10, segments => seg_m10);
  m1 : entity work.seven_segment(rtl)
    port map (digit => display_minute mod 10, segments => seg_m1);
  s10 : entity work.seven_segment(rtl)
    port map (digit => display_second / 10, segments => seg_s10);
  s1 : entity work.seven_segment(rtl)
    port map (digit => display_second mod 10, segments => seg_s1);
end architecture;
