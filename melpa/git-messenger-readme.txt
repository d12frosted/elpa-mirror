This package provides a function called git-messenger:popup-message
that when called will pop-up the last git commit message for the
current line.  This uses the git-blame tool internally.

Example usage:
  (require 'git-messenger)
  (global-set-key (kbd "C-x v p") 'git-messenger:popup-message)
