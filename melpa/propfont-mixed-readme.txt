
Enable use of variable-width fonts for displaying symbols,
in a way that does not conflict with fixed-width-space-based
indentation.

Notes:

- Customize `propfont-mixed-inhibit-regexes' to forbid some symbols
  from being shown with proportional fonts. See also
  `propfont-mixed-inhibit-function', and `propfont-mixed-inhibit-faces'.

- It is probably necessary to adjust the face `variable-pitch', so
  that the proportional font looks good and is the correct size to
  match the default font.
