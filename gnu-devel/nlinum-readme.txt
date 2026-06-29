This is like linum-mode, but uses jit-lock to be (hopefully)
more efficient.

News:

v1.9:
- Add `nlinu-widen'.

v1.8:
- Add `nlinum-use-right-margin'.

v1.7:
- Add ability to highlight current line number.
- New custom variable `nlinum-highlight-current-line' and
  face `nlinum-current-line'.
- New `nlinum' group in Custom.

v1.3:
- New custom variable `nlinum-format'.
- Change in calling convention of `nlinum-format-function'.

v1.2:
- New global mode `global-nlinum-mode'.
- New config var `nlinum-format-function'.

Known bugs:
- When narrowed, there can be a "bogus" line number that appears at the
  very end of the buffer.
- After widening, the current line's number may stay stale until the
  next command.