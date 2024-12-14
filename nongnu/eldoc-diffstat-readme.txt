This package provides a way to display VCS diffstat information via eldoc.
It supports Git and Mercurial repositories.

To use, call `eldoc-diffstat-setup' in the desired buffer or mode hook.
You might also want to add the following to your config:

  (eldoc-add-command
   'magit-next-line 'magit-previous-line
   'magit-section-forward 'magit-section-backward
   'magit-section-forward-sibling 'magit-section-backward-sibling)

Adapted from Tassilo Horn's blog post:
https://www.tsdh.org/posts/2022-07-20-using-eldoc-with-magit-async.html