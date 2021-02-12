See github readme at https://github.com/Fuco1/indicators.el

Known limitations:

1. you can't have more than one color on one "physical line".
   This is becuse fringes operate on "per-line" basis and it is
   only possible to set face for bitmap for the whole line.
2. if you are at the end of file the indicators are displaied
   incorrectly. This is because it's impossible to set fringe
   bitmaps for lines past the end of file.

Both of these are currently imposible to fix.
