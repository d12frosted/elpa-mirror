Bring animation like in Beamer into your org-tree-slide presentations!

Manual installation:
Download the org-tree-slide-pauses.el.  Add the path to the `load-path'
variable and load it.  This can be added to the .emacs initialization file:

    (add-to-list 'load-path "path-to-where-the-el-file-is")
    (require 'org-tree-slide-pauses)

Usage:
- List items and enumerations works automatically.
- Add one of the following to create a pause:
  # pause
  #+pause:
  #+beamer: \pause

When you start to presenting with `org-tree-slide-mode' the text between
pauses will appear with the "shadow" face.  Use the C->
(M-x `org-tree-slide-move-next-tree') to show one by one.  If there is no
more text to reveal, the same command will show the next slide/title like
usual.
