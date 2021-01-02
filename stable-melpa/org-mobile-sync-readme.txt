Adds delayed `org-mobile-push' upon saving files that are part of
`org-mobile-files-alist'. Watches the `org-mobile-capture-file' for
changes with `file-notify.el' and then invokes `org-mobile-pull'.

; Requirements:

Emacs 24.3.50 with `file-notify-support' is required for it to work.
