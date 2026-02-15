Lonelog is a minor mode that provides syntax highlight and support
for the "Lonelog" solo RPG notation system, designed by Loreseed
Workshop: https://zeruhur.itch.io/lonelog
The lonelog minor mode is designed to be agnostic to the underlying
major mode, working equally well in org-mode, Markdown, or plain
text.

Features include:
- Highlighting for core symbols (@, ?, d:, ->, =>)

To use this package, add the following to your configuration:

  (require 'lonelog)
  (add-hook 'text-mode-hook 'lonelog-mode)

Customization:
 Run M-x customize-group RET lonelog RET to change colors.
