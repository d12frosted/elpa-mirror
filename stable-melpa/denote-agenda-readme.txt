This file contains a simple integration between Denote and
Org-Agenda.  It is aware of `denote-journal', and provides
three configuration options.

- `denote-agenda-static-files' A list of files which should always
  be included.
- `denote-agenda-include-regexp' A regexp to determine files which
  should be included on the fly.
- `denote-agenda-include-journal' Set to t if
  `denote-journal' files should be included.  If set, only
  journal entries for the current and future days will be included.
- `denote-agenda-include-journal-limit' Set to nil if all
  current/future journal entries should be included, or a positive
  number specifying how many should be included.

To use this package, load it, configure the above options, and run:

    (denote-agenda-insinuate)

;; Errors and Patches

If you find an error, or have a patch to improve this package,
please send an email to ~swflint/emacs-utilities@lists.sr.ht.
