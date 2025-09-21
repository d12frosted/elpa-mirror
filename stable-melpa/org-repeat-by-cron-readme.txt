An Org mode task repeater based on Cron expressions
Modified from https://github.com/Raemi/org-reschedule-by-rule.
Key Differences:
- Uses a cron parser implemented in pure Elisp, with
  no dependency on the Python croniter package.
- Replaces the INTERVAL property with a DAY_AND property.
- Supports toggling between SCHEDULED and DEADLINE timestamps.

org-repeat-by-cron.el is a lightweight extension for Emacs Org
  ;; mode that allows you to repeat tasks based on powerful Cron expressions.
Standard Org mode repeaters (like +1d , ++1w ) are based on
the current SCHEDULED or DEADLINE timestamp. In contrast, this
tool provides a repetition method based on absolute time rules.
You can easily set a task to repeat \"on the last Friday of
every month\" or \"on the first Monday of each quarter\"
without manual date calculations.
A core advantage of this tool is its pure Elisp implementation,
which does not rely on any external programs (like Python's
croniter library), ensuring it works out-of-the-box in Emacs environment.

Installation
- Download =org-repeat-by-cron.el= and place it in your Emacs load-path.
- Add the following code to your Emacs configuration file (e.g., init.el ):
  #+begin_src elisp
(require 'org-repeat-by-cron)
  #+end_src

Using use-package

If you use use-package , the configuration is more concise:
#+begin_src elisp
(use-package org-repeat-by-cron
  :ensure nil  ; If the file is already in your load-path
  :load-path "/path/to/your/lisp/directory/")
#+end_src

Tip: You should not use org-repeat-by-cron and the built-in
Org repeater cookie (e.g., +1w) on the same task.
