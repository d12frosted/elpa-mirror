This package provide a function to create a sparkline graph.

Sparkline graphs were introduced by Edward Tufte see
http://en.wikipedia.org/wiki/Sparkline

They are charts containing a single line without any labels or
indication of scale.

They are meant to be used inline in text, without changing the line
height and provide a quick overview of the trend and pattern of the
underlying data.

Creating sparkline graphs is done for example by

  (sparkline-make-sparkline 80 11 '(10 20 4 23.3 22.1 3.3 4.5 6.7))

which creates in image which can be inserted in a buffer with the
standard image functions such as:

  (insert-image
     (sparkline-make-sparkline 80 11 '(10 20 4 23.3 22.1 3.3 4.5 6.7)))


GENERAL DRAWING FEATURES

Besides creating sparklines this package also allows creating and
drawing into bitmaps in a limited way.

The supported features are:

- Creating a monochrome bitmap of arbitrary size with `sparkline-make-image'
- Coloring a pixel in the foreground or backaground color with `sparkline-set-pixel'
- Drawing straight lines with `sparkline-draw-line'.
