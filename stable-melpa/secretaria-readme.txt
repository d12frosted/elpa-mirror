# What's this?

A personal assistant based on org-mode.  This package contains utilities that
enhance your experience with org-mode.

# Features

- Reminders
    - All tasks scheduled or which have a deadline set to "today", but have no time of the day
      specified.
    - The current clocked task, every N minutes (10 by default).
    - In case of Emacs crashing, the task clocked in at the moment so you don't forget about fixing
      that.

# How to use

This package should be available in Melpa, if you use `use-package`, throw this code snippet in your
Emacs configuration.

    (use-package secretaria
      :config
      ;; use this for getting a reminder every 30 minutes of those tasks scheduled
      ;; for today and which have no time of day defined.
      (add-hook 'after-init-hook #'secretaria-unknown-time-always-remind-me))
