Increase or decrease the number at point with `shift-number-up' and
`shift-number-down' commands.

To install the package manually, add the following to your init file:

(add-to-list 'load-path "/path/to/shift-number-dir")
(autoload 'shift-number-up "shift-number" nil t)
(autoload 'shift-number-down "shift-number" nil t)

For more verbose description and a gif demonstration, see
<https://codeberg.org/ideasman42/emacs-shift-number>.
