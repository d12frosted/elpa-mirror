This package collects Emacs garbage collection (GC) statistics over time
and saves it in the format that can be shared with Emacs maintainers.

Context:
• <https://yhetil.org/emacs-devel/20230310110747.4hytasakomvdyf7i@Ergus/>
• <https://yhetil.org/emacs-devel/87v8j6t3i9.fsf@localhost/>

See the source code for information how to contact the author.

[2023-12-06 Wed] You can find EmacsConf2023 presentation with analysis
of the collected data (as of the timestamp date) at
<https://emacsconf.org/2023/talks/gc/>.  The data in reproducible format
is available at <https://dx.doi.org/10.5281/zenodo.10213384>.


1 Usage
═══════

  Add
  ┌────
  │ (require 'emacs-gc-stats)
  │ ;; Optionally reset Emacs GC settings to default values (recommended)
  │ (setq emacs-gc-stats-gc-defaults 'emacs-defaults)
  │ ;; Optionally set reminder to upload the stats after 3 weeks.
  │ (setq emacs-gc-stats-remind t) ; can also be a number of days
  │ ;; Optionally disable logging the command names
  │ ;; (setq emacs-gc-stats-inhibit-command-name-logging t)
  │ (emacs-gc-stats-mode +1)
  └────
  to your init file to enable the statistics acquiring.

  When you are ready to share the results, run `M-x
  emacs-gc-stats-save-session' and then share the saved
  `emacs-gc-stats-file' (defaults to `~/.emacs.d/emacs-gc-stats.eld') by
  sending an email attachment to <mailto:emacs-gc-stats@gnu.org>. You
  can review the file before sharing–it is a text file.

  Configure `emacs-gc-stats-remind' to make Emacs display a reminder
  about sharing the results.


2 Security considerations
═════════════════════════

  This package *does not* upload anything automatically.  You will need
  to upload the data manually, by sending email attachment.  If
  necessary, you can review `emacs-gc-stats-file' (defaults to
  `~/.emacs.d/emacs-gc-stats.eld') before uploading–it is just a text
  file.

  The following data is being collected after every command:
  • GC settings `gc-cons-threshold' and `gc-cons-percentage'
  • Emacs version and whether Emacs framework (Doom, Prelude, etc) is
    used
  • Whether `gcmh-mode' is used
  • Idle time and Emacs uptime
  • Available OS memory (see `memory-info')
  • Emacs memory allocation/GC stats
  • Current command name (potentially sensitive data, can be disabled)
  • Timestamp when every GC is finished

  Logging the command names can be disabled by setting
  `emacs-gc-stats-inhibit-command-name-logging' customization.

  What exactly is being logger is controlled by
  `emacs-gc-stats-setting-vars', `emacs-gc-stats-command-vars', and
  `emacs-gc-stats-summary-vars'.

  You can use `M-x emacs-gc-stats-clear' to clear the currently
  collected session data.

  You can pause the logging any time by disabling `emacs-gc-stats-mode'
  (`M-x emacs-gc-stats-mode').


3 News
══════

3.1 Version 1.4.1
─────────────────

  • Avoid `memory-info' trying to retrieve memory information from
    remote system over TRAMP.


3.2 Version 1.4
───────────────

  • `emacs-gc-stats-file' is now compressed, when possible.


3.3 Version 1.3
───────────────

  • New customization: `emacs-gc-stats-inhibit-command-name-logging' to
    disable logging current command name.  Logging is enabled by
    default.

  • New customization: `emacs-gc-stats-remind' to set a reminder to
    share the data.  Reminder is disabled by default.

  • The data being collected is can now be customized using
    `emacs-gc-stats-setting-vars', `emacs-gc-stats-command-vars', and
    `emacs-gc-stats-summary-vars'.
