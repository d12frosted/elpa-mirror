This package allows to find a color by pressing keys for smooth
changing foreground/background color of any text sample.

To manually install the package, copy this file to a directory from
`load-path' and add the following to your init-file:

  (autoload 'make-color "make-color" nil t)
  (autoload 'make-color-switch-to-buffer "make-color" nil t)

Usage: select any region and call "M-x make-color".  You will see a
buffer in `make-color-mode'.  Select some text in it and press "n" to
set this text for colorizing.  Now you can modify a color with the
following keys:

  - r/R, g/G, b/B - decrease/increase red, green, blue components
  - c/C, m/M, y/Y - decrease/increase cyan, magenta, yellow components
  - h/H, s/S, l/L - decrease/increase hue, saturation, luminance
  - RET - change current color (prompt for a value)

If you are satisfied with current color, press "k" to put the color
into `kill-ring'.  At any time you can set a new probing region with
"n".  You can navigate through a history of probing regions with
"SPC", "N" and "P".  If you forgot where the current probing region
is placed, press "SPC".  Also you can switch between modifying
background/foreground colors with "t".  See mode description ("C-h
m") for other key bindings.

Buffer in `make-color-mode' is not read-only, so you can yank and
delete text and undo the changes as you always do.

For full description, see <https://github.com/alezost/make-color.el>.
