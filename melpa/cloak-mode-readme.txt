Hide sensitive using pre defined regex patterns per major mode.
It allows to define specific regex per each major mode where we want to hide
sensitive data

Usage: For example if we want to add it to envrc files
  (require 'cloak-mode)
  (setq cloak-mode-patterns '((envrc-file-mode . "[a-zA-Z0-9_]+[ \t]*=[ \t]*\\(.*+\\)$")))
  (global-cloak-mode)
