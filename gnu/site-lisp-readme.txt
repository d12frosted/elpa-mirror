The following code manages local Lisp code, that might not be part
of a package.  For regular use, create a "site-lisp" directory next
to "init.el", and create a file subdirectory for every script you
wish to have loaded.

Use `site-lisp-reload' after adding a new script to avoid
restarting Emacs.