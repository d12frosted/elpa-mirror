This package provides mechanism for immediate completion, running again cycles over options.

; Usage


A key can be bound to a completion action,
to cycle in the reverse direction you can either press \\[keyboard-quit]
which causes the next completion to move in the opposite direction
or bind a key to cycle backward.

Example:

  ;; Map Alt-P to correct the current word.
  (global-set-key (kbd "M-p") 'recomplete-ispell-word)
