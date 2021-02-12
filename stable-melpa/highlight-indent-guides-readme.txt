This minor mode highlights indentation levels via font-lock.  Indent widths
are dynamically discovered, which means this correctly highlights in any
mode, regardless of indent width, even in languages with non-uniform
indentation such as Haskell.  This mode works properly around hard tabs and
mixed indentation, and it behaves well in large buffers.

To install, put this file in your load-path, and do
M-x highlight-indent-guides-mode to enable it.  To enable it automatically in
most programming modes, use the following:

  (add-hook 'prog-mode-hook 'highlight-indent-guides-mode)

To set the display method, use:

  (setq highlight-indent-guides-method METHOD)

Where METHOD is either 'fill, 'column, 'character, or 'bitmap.

To change the character used for drawing guide lines with the 'character
method, use:

  (setq highlight-indent-guides-character ?ch)

By default, this mode automatically inspects your theme and chooses
appropriate colors for highlighting.  To tweak the subtlety of these colors,
use the following (all values are percentages):

  (setq highlight-indent-guides-auto-odd-face-perc 15)
  (setq highlight-indent-guides-auto-even-face-perc 15)
  (setq highlight-indent-guides-auto-character-face-perc 20)

Or, to manually set the colors used for highlighting, use:

  (setq highlight-indent-guides-auto-enabled nil)

  (set-face-background 'highlight-indent-guides-odd-face "color")
  (set-face-background 'highlight-indent-guides-even-face "color")
  (set-face-foreground 'highlight-indent-guides-character-face "color")
