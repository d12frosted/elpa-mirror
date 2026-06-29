mode-line-maker is a package to ease the creation of mode-line,
header-line or tab-line.  It allows to define the precise alignment
of the mode-line (on left and right sides) and splits the mode-line
into left and right parts, with automatic truncation (when there is
too much information to display).

These features come with a price in rendering speed because
everything is computed dynamically.  From early benchmarks, you can
expect a significant slowdown (between x2 and x3).  Things can get
worse if you use pixel-wise alignment because of the
string-pixel-width call.

If you only need alignment on left and right, you can directly use
the 'nano-line-make--padding function to get the relevant
prefix/suffix to be prepended/appended to your mode-line.

Usage:

(setq mode-line-format (mode-line-maker '("%b") '("%3c:%3l")))