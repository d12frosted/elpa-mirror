This package provides a hook variable `switch-buffer-functions'.

This hook will be run when the current buffer has been changed after each
interactive command, i.e. `post-command-hook' is called.

When functions are hooked, they will be called with the previous buffer and
the current buffer.  For example, if you eval:

(add-hook 'switch-buffer-functions
          (lambda (prev curr)
            (cl-assert (eq curr (current-buffer)))  ;; Always t
            (message "%S -> %S" prev curr)))

then the message like "#<buffer *Messages*> -> #<buffer init.el<.emacs.d>>"
will be displayed to the echo area each time when you switch the current
buffer.
