org-change is a minor mode to annotate changes in text files using
a custom markup syntax: {!new text!}{!old text!}.  It works in any
major mode.  Mark additions with org-change-add (C-` a), deletions
with org-change-delete (C-` d), and replacements with
org-change-replace (C-` r).  Accept or reject changes with
org-change-accept (C-` k) and org-change-reject (C-` x), or with
C-` K and C-` X to move to the next change as well.  Comment
on a change with org-change-comment (C-` c).  Move between changes
with org-change-next-change (C-` n) and
org-change-previous-change (C-` p).  Count them with
org-change-info (C-` i), or list them in a side window with
org-change-overview (C-` o).  Press C-` h for a summary of the key
bindings.  Generate change markup from
two versions of a document with org-change-from-diff.  When
used in org-mode, LaTeX, HTML, and plain text export are
available.  To change
key bindings and other settings, run M-x customize-group RET
org-change.  More information at the package URL.
