This package collects Emacs garbage collection (GC) statistics over time
and saves it in the format that can be shared with Emacs maintainers.

See the source code for information how to contact the author.

*Usage:*

Add
┌────
│ (require 'emacs-gc-stats)
│ ;; optional
│ (setq gc-cons-threshold
│       (* 800000 (seq-random-elt '(1 2 4 8 16 32 64 128))))
│ (emacs-gc-stats-mode +1)
└────
to your init file to enable the statistics acquiring.

When you are ready to share the results, run `M-x
emacs-gc-stats-save-session' and then share the saved
`emacs-gc-stats-file' (defaults to `~/.emacs.d/emacs-gc-stats.eld').

You can use `M-x emacs-gc-stats-clear' to clear the currently collected
session data.
