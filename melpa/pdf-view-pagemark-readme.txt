Because Emacs cannot show continuous pages at the same time, it is
difficult to keep track of the remaining text in current page, this
minor mode add a posframe indicator to tell you the line from
scroll up.

To enable, add the following:

  (use-package pdf-view-pagemark
    :custom (pdf-view-pagemark-timeout 2)
    :hook (pdf-view-mode . pdf-view-pagemark-mode))
