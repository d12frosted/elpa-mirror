Add a Tcl checker to Flycheck using ActiveState's tclchecker.

;; Setup

Add the following to your init file:

   (with-eval-after-load 'flycheck
     (flycheck-tcl-setup))
