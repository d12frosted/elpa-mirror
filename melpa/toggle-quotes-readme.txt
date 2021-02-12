
`toggle-quotes' toggles the single-quoted string at point to
double-quoted one, and vice versa.

To use toggle-quotes, make sure that this file is in Emacs `load-path':
  (add-to-list 'load-path "/path/to/directory/or/file")

Then require it and bind the command `toggle-quotes':
  (require 'toggle-quotes)
  (global-set-key (kbd "C-'") 'toggle-quotes)
