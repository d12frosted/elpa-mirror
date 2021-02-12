Provides feedback via flycheck about issues with `rx' and literal
regular expressions in Emacs Lisp, using `relint'.

To enable, use something like this:

   (eval-after-load 'flycheck
     '(flycheck-relint-setup))
