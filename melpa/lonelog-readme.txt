Lonelog is a minor mode that provides syntax highlight and support
for the "Lonelog" solo RPG notation system, designed by Loreseed
Workshop: https://zeruhur.itch.io/lonelog
The lonelog minor mode is designed to be agnostic to the underlying
major mode, working equally well in org-mode, Markdown, or plain
text.

Features include:
- Highlighting for core symbols (@, ?, d:, ->, =>)
- Highlighting for tags ([N:Jonah|friendly|uninjured])
- Tags are optionally tracked in a separate HUD window

To use this package, add the following to your configuration:

  (require 'lonelog)
  (add-hook 'text-mode-hook 'lonelog-mode)

Keybindings:
All commands are placed behind a customizable prefix, which defaults
to C-c , (Control-c followed by a comma).

  C-c , h  - Toggle the tag tracking HUD
  C-c , d  - Insert the current date

Customization:
Run M-x customize-group RET lonelog RET to change colors, window
widths, or the command prefix.
