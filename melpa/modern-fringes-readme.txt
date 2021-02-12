modern-fringes is meant to replace the arguably ugly default fringe bitmaps
with more modern, easier on the eyes ones.  They are very simple to use,
simply use the modern-fringes-mode.  As one knows, you may use customize to
make the mode permanent.  It is a global minor mode, so it will affect all
buffers.

It is suggested to use the following function in your init file to
use modern-fringes at intended.  It makes the truncation arrows appear
transparent, making a very easy on the eyes zipper-effect.

   (modern-fringes-invert-arrows)

Depending on your theme, it may not work
properly.  In that case, you can edit the bitmap faces as you wish in your
config.  modern-fringes was designed assuming the fringe width is 8 pixels
wide.  It will likely look strange if the width is any less or more.

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
