Compact syntax for short lambda.

After `llama', this is my second attempt at providing such syntax
without having the power to add actual new syntax to Emacs, which
means that I have to fake it, which means that compromises cannot
be avoided.

The `l' macro allows you to write one of these three expressions:

    (l`list % %2 %*)
    (l'list % %2 %*)
    (l list % %2 %*)

all of which are turned into:

    (lambda (% %2 &rest %*)
      (list % %2 %*))

You may wish to substitute some fancy character for `l':

    (defun my-prettify-l-symbol ()
      (cl-pushnew '("l" . ?ƒ) prettify-symbols-alist))
    (add-hook 'emacs-lisp-mode-hook 'my-prettify-l-symbol)
    (global-prettify-symbols-mode 1)
