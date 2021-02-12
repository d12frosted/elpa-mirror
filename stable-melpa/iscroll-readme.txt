
Gone are the days when images jumps in and out of the window when
scrolling! This package makes scrolling over images as if the image
is made of many lines, instead of a single line. (Indeed, sliced
image with default scrolling has the similar behavior as what this
package provides.)

To use this package:

    M-x iscroll-mode RET

This mode remaps mouse scrolling functions and `next/previous-line'.
If you use other commands, you need to adapt them accordingly. See
`iscroll-mode-map' and `iscroll-mode' for some inspiration.

You probably don't want to enable this in programming modes because
it is slower than normal scrolling commands.

If a line is taller than double the default line height, smooth
scrolling is triggered and Emacs will reveal one line’s height each
time.

Commands provided:

- iscroll-up
- iscroll-down
- iscroll-next-line
- iscroll-previous-line
