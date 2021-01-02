; This is a mode that will download a review from gerrit using the
; `git-review' software and run show the diff for that changes.
;
; This is using magit and the `magit-repo-dirs` variable to download
; the change into.
;
; With gnus add a hook like this
; (add-hook 'gnus-startup-hook 'gerrit-download-insinuate-gnus)
; in your init file and use the 'v' key to have it automatically
; parse the email and show the diff.
