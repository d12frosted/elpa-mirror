A simple "glue" minor mode that allows Flycheck and Eglot to work together.

You just need to enable `global-flycheck-eglot-mode'.
Put the following in your init file:

     (require 'flycheck-eglot)
     (global-flycheck-eglot-mode 1)

By default, the Flycheck-Eglot considers the Eglot to be the only provider
of syntax checks.  Other Flycheck checkers are ignored.
There is a variable `flycheck-eglot-exclusive' that controls this.
You can override it system-wide or for some major modes.
