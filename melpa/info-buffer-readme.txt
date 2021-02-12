
Interactive command (`info-buffer') to display each info topic on its
separate buffer.  With prefix, display an already opened topic on a new
buffer.

If you're using `use-package', you can easily re-define Emacs's info binding
to use `info-buffer' instead:

  (use-package info-buffer
    :bind (("C-h i" . info-buffer)))
