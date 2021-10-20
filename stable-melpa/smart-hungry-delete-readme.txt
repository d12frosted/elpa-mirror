Hungrily deletes whitespace between cursor and next word, paren or
delimiter while honoring some rules about where space should be
left to separate words and parentheses.

Usage:

with use-package:

(use-package smart-hungry-delete
  :bind (("<backspace>" . smart-hungry-delete-backward-char)
              ("C-d" . smart-hungry-delete-forward-char)))
