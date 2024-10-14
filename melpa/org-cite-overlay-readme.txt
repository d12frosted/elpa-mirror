
Automatically toggle showing org-cite citations as formatted
overlays upon cursor entry/exit.  To use, enable
`org-cite-overlay-mode' in org mode buffers (for example, in
`org-mode-hook').  This code is heavily inspired by org-fragtog
(https://github.com/io12/org-fragtog/).

This package does have a few limitations:
 - Detection of exit or insertion of citations is somewhat
   inconsistent, so every 30 user commands in the buffer, all
   citations will be regenerated.

;; Bug Reports and Patches

If you find an error or have a patch to improve these packages,
please send an email to `~swflint/emacs-utilities@lists.sr.ht'.
