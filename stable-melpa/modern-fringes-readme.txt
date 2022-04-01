modern-fringes is meant to replace the default fringes with ones that are
more visually pleasing.  They are very simple to use, just enable the
modern-fringes-mode minor mode.  You are able to use customize to make the
mode permanent, as well as change other aspects.  It is a global minor mode
and will affect all buffers.

It is suggested to use the following function in your init file to use
modern-fringes at intended.  It matches the truncation arrow foreground color
to the current main background color of your theme, making them appear
transparent and less visually cluttering.

(modern-fringes-invert-arrows)

Depending on your theme, the function may make them look unappealing.  In
that case, you can edit the bitmap faces as you wish in your config.

modern-fringes assumes the fringe width is 8 pixels wide, and the bitmaps
will likely look strange if the width is any different.

bitmap references

mf-right-arrow
10000000
11000000
11100000
11110000
11111000
11111100
11111110
11111100
11111000
11110000
11100000
11000000
10000000

mf-left-arrow
00000001
00000011
00000111
00001111
00011111
00111111
01111111
00111111
00011111
00001111
00000111
00000011
00000001

mf-right-curly-arrow
1000000
0100000
0010000
0001000
1000100
1001000
1010000
1100000
1111100

mf-left-curly-arrow
000010
000100
001000
010000
100010
010010
001010
000110
111110

mf-right-debug-arrow
10000000
01000000
11100000
00010000
11111000
00000100
11111110
00000100
11111000
00010000
11100000
01000000
10000000

mf-left-debug-arrow
0000001
0000010
0000111
0001000
0011111
0100000
1111111
0100000
0011111
0001000
0000111
0000010
0000001
