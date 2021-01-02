
Languages in the Lisp family have macros, which means that some
Lisp forms sometimes need custom indentation.  Emacs enables this
via symbol properties: e.g. (put 'when 'lisp-indent-function 1)

Unfortunately symbol properties are global to all of Emacs.  That
makes it impossible to have different Lisp indentation settings in
different buffers.  This package works around the problem by adding
a `lisp-indent-function' wrapper that temporarily swaps the global
properties for buffer-local values whenever you indent some code.
It then changes them back to their global values after indenting.

The buffer-local variable `lisp-local-indent' controls indentation.
When a particular Lisp form is not mentioned in that variable, the
global indentation settings are used as a fallback.

Enable via one or more of the following hooks:

(add-hook 'emacs-lisp-mode-hook 'lisp-local)
(add-hook 'lisp-mode-hook       'lisp-local)
(add-hook 'scheme-mode-hook     'lisp-local)
(add-hook 'clojure-mode-hook    'lisp-local)

This package does not say where your indentation settings should
come from.  Currently you can set them in `.dir-locals.el' or a
custom hook function.  In the future, more convenient ways will
hopefully be provided by other packages.
