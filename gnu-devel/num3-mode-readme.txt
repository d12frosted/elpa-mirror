Num3 is a minor mode that makes long numbers and other numeric data
more readable by highlighting groups of digits in a string when
font-lock is on.

For example, an integer ‘28318530’ would be split into 3-digit-long
groups as ‘(28)(318)(530)’ and then each group highlighted using
alternating face.  This improves readability of the number by clearly
denoting millions, thousands and ones.  Besides integers and real
numbers, the mode also supports dates in ‘20151021T0728’ format.

The mode supports:
- decimal numbers, e.g. 1234567 or 6.2831853,
- hexadecimal integers, e.g. 0x1921FB5, #x1921FB5 or unprefixed 1921FB5,
- octal integers, e.g. 0o1444176 or #o1444176,
- binary integers, e.g. 0b1100100100 or #b1100100100,
- hexadecimal floating point numbers, e.g. 0x1.921FB54p+2,
- timestamps, e.g. 20151021T0728

Decimal and octal numbers are split into 3-digit-long groups (the
length is customisable); hexadecimal and binary numbers are split
into 4-digit-long groups; timestamps are split based on the part of
the date or time.