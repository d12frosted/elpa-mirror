This package provides syntax highlighting and basic alda integration.
Activate font-lock-mode to use the syntax features, and run 'alda-play-region' to play song files

Variables:
alda-binary-location: Set to the location of the binary executable.
If nil, alda-mode will search for your binary executable on your path
If set to a string, alda-mode will use that binary instead of 'alda' on your path.
Ex: (setq alda-binary-location "/usr/local/bin/alda")
Ex: (setq alda-binary-location nil) ;; Use default alda location
alda-ess-keymap: Whether to add the default ess keymap.
If nil, alda-mode will not add the default ess keymaps.
Ex: (setq alda-ess-keymap nil) ;; before (require 'alda)
