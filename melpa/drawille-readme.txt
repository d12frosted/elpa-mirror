This is an experimental drawille implementation im emacs lisp.

Drawille is a library originally written in python that permit to
use graphics in text environment using the braille characters as a
canvas smaller than a character (2x8 dots per characters).

It is not complete, but yet works, with a `drawille-buffer' command
that transforms the buffer into a small representation of its
content.

This will result into transforming a matrices:

[[a0 a1 a2 a3 a4 a5]   [[[a0 a1   [a2 a3   [a4 a5   \
 [b0 b1 b2 b3 b4 b5]      b0 b1  / b2 b3  / b4 b5   |<- One braille
 [c0 c1 c2 c3 c4 c5]      c0 c1 /  c2 c3 /  c4 c5   |   character
 [d0 d1 d2 d3 d4 d5] =>    d0 d1]   d2 d3]   d4 d5]] /
 [e0 e1 e2 e3 e4 e5]    [[e0 e1   [e2 e3   [e4 e5
 [f0 f1 f2 f3 f4 f5]      f0 f1  / f2 f3  / f4 f5
 [g0 g1 g2 g3 g4 g5]      g0 g1 /  g2 g3 /  g4 g5
 [h0 h1 h2 h3 h4 h5]]     h0 h1]   h2 h3]   h4 h5]]]

Which is more correctly written as:

[[[a0 a1 b0 b1 c0 c1 d0 d1] <- One braille character
  [a2 a3 b2 b3 c2 c3 d2 d3]
  [a4 a5 b4 b5 c4 c5 d4 d5]] <- One row of braille characters
 [[e0 e1 f0 f1 g0 g1 h0 h1]
  [e2 e3 f2 f3 g2 g3 h2 h3]
  [e4 e5 f4 f5 g4 g5 h4 h5]]] <- Two row of braille characters

With each row a vector of 0 or 1, that is multiplied pairwise, and
aditionned to #x2800 produce a braille character keycode.
