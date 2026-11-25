package clock_types_pkg is
  subtype hour_24_t is natural range 0 to 23;
  subtype hour_2digit_t is natural range 0 to 99;
  subtype minute_second_t is natural range 0 to 59;
  subtype digit_t is natural range 0 to 9;
end package;
