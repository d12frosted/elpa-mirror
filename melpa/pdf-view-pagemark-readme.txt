Because Emacs cannot show continuous pages at the same time, it is
difficult to keep track of the remaining text in current page, this
minor mode add a posframe indicator to tell you the line from
scroll up.

To enable, add the following:
  (add-hook 'pdf-view-mode-hook 'pdf-view-pagemark-mode)
