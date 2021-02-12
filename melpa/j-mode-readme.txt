Provides font-lock and basic REPL integration for the
[J programming language](http://www.jsoftware.com)

; Installation

The only method of installation is to check out the project, add it to the
load path, and load normally. This may change one day.

Put this in your emacs config
  (add-to-list 'load-path "/path/to/j-mode/")
  (load "j-mode")

Add for detection of j source files if the auto-load fails
  (add-to-list 'auto-mode-alist '("\\.ij[rstp]$" . j-mode)))
