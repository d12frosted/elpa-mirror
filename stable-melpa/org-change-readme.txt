This package provides a minor mode for annotating changes in org-mode
files, by defining a new type of link, the change: link.  Using the
functions org-change-add, org-change-delete, and
org-change-replace, you can mark text as constitution an addiion,
deletion, or replacement to the text.  These functions are bound by
default to C-` a, C-` d, and C-` r. Functions org-change-accept and
org-change-reject can be used to replace the change: link with the
new and old text, respectively.  These are bound to C-` o and C-` x.

To change key bindings and other settings, run M-x customize-group
RET org-change.  When exporting to LaTeX, changes are rendered using
the "changes" package.  See the package URL for more documentation.
