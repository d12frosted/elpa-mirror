This library provides basic integration between
`denote-journal-extras' and `org-capture', providing a function to
allow a specific date to be captured to, while saving the date for
later editing as part of the capture process.

It may be used as follows.  For a given capture template with a
`file' derived location, the functions
`denote-journal-capture-entry-for-date' (prompt for a date) or
`denote-journal-capture-entry-for-today' (today's entry) may be
used instead of filename, for example:

(setq org-capture-templates '(("a" "Appointment" entry
                               (file+olp denote-journal-capture-entry-for-date "Appointments")
                               "* %(denote-journal-capture-timestamp) %^{Subject?}")))

Then, as shown above, in the template, the expansion of
`%(denote-journal-capture-template)' can be used to prompt
for (and reuse) the date that was selected as for capturing.

;; Errors and Patches

If you find an error, or have a patch to improve this package,
please send an email to ~swflint/emacs-utilities@lists.sr.ht.
