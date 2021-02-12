`org-autolist` makes org-mode lists behave more like lists in non-programming
editors such as Google Docs, MS Word, and OS X Notes.

When editing a list item, pressing "Return" will insert a new list item
automatically. This works for both bullet points and checkboxes, so there's
no need to think about whether to use `M-<return>` or `M-S-<return>`. Similarly,
pressing "Backspace" at the beginning of a list item deletes the bullet /
checkbox, and moves the cursor to the end of the previous line.

To enable org-autolist mode in the current buffer:

  (org-autolist-mode)

To enable it whenever you open an org file, add this to your init.el:

  (add-hook 'org-mode-hook (lambda () (org-autolist-mode)))
