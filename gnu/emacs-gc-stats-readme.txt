This package collects Emacs garbage collection (GC) statistics over time
and saves it in the format that can be shared with Emacs maintainers.

See the source code for information how to contact the author.

*Usage:*

Add
┌────
│ (require 'emacs-gc-stats)
│ (setq emacs-gc-stats-gc-defaults 'emacs-defaults) ; optional
│ (emacs-gc-stats-mode +1)
└────
to your init file to enable the statistics acquiring.

When you are ready to share the results, run `M-x
emacs-gc-stats-save-session' and then share the saved
`emacs-gc-stats-file' (defaults to `~/.emacs.d/emacs-gc-stats.eld').

You can use `M-x emacs-gc-stats-clear' to clear the currently collected
session data.
