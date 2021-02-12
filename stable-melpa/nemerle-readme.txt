A major mode for editing nemerle source files.  It provides syntax
hilighting, proper indentation, and many other features.
To install the nemerle mode, put the following lines into your
~/.emacs file:

(setq load-path (cons "/path/to/dir/where/this/file/resides" load-path))
(autoload 'nemerle-mode "nemerle.el"
  "Major mode for editing nemerle programs." t)
(setq auto-mode-alist (cons '("\\.n$" . nemerle-mode) auto-mode-alist))

If you'd like to have every line indented right after new line put
these lines into your ~/.emacs files.

(defun my-nemerle-mode-hook ()
  (define-key nemerle-mode-map "\C-m" 'newline-and-indent))
(add-hook 'nemerle-mode-hook 'my-nemerle-mode-hook)

You may use variables nemerle-basic-offset and nemerle-match-case-offset
to customize indentation levels.

By default indentation based syntax is turned on. It is switched off
inside any parens anyway so it should be ok. If you think otherwise
you can use following in your ~/.emacs file:

(setq nemerle-indentation-based-syntax nil)
