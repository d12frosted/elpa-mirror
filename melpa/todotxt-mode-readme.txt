todotxt-mode is a major mode for editing todo.txt files.
(see http://www.todotxt.com for more information about format and apps)

Installation:

Put in your .emacs file:

(add-to-list 'load-path "<DIR WHERE TODOTXT-MODE LIVES>")
(require 'todotxt-mode)

Usage:

Open a todo.txt file

  M-x todotxt-mode
  M-x describe-mode

For some more customization:

  (setq todotxt-default-file (expand-file-name "<<WHERE YOUR TODO FILE LIVES>>"))
  (add-to-list 'auto-mode-alist '("todo\\.txt\\'" . todotxt-mode))
  (define-key global-map "\C-ct" 'todotxt-add-todo)
  (define-key global-map "\C-co" 'todotxt-open-file)
