This package collects Emacs garbage collection (GC) statistics over time
and saves it in the format that can be shared with Emacs maintainers.

Context:
• <https://yhetil.org/emacs-devel/20230310110747.4hytasakomvdyf7i@Ergus/>
• <https://yhetil.org/emacs-devel/87v8j6t3i9.fsf@localhost/>

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
`emacs-gc-stats-file' (defaults to `~/.emacs.d/emacs-gc-stats.eld') by
sending an email attachment to <mailto:emacs-gc-stats@gnu.org>.

You can use `M-x emacs-gc-stats-clear' to clear the currently collected
session data.

The following data is being collected after every command:
• GC settings `gc-cons-threshold' and `gc-cons-percentage'
• Emacs version and whether Emacs framework (Doom, Prelude, etc) is used
• Whether `gcmh-mode' is used
• Idle time and Emacs uptime
• Available OS memory (see `memory-info')
• Emacs memory allocation/GC stats
• Current command
