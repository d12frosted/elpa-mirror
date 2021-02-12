This provides a major mode to view the output of dictionary tools,
and utilities that perform searches and nicely format the results.

Currently tied to sdcv, but this is intended to be changed in the future.

Put this file into your load-path and the following into your
~/.emacs:
  (require 'lexic-mode)
  (global-set-key (kbd "C-c d") 'lexic-search)
