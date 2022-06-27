Import GitHub code given a permalink.

#+begin_src git-permalink
https://github.com/emacs-mirror/emacs/blob/a4dcc8b9a94466c792be3743760a4a45cf6e1e61/lisp/emacs-lisp/ring.el#L48-L52
#+end_src

↓ evaluate(C-c)

(defun ring-p (x)
  "Return t if X is a ring; nil otherwise."
  (and (consp x) (integerp (car x))
       (consp (cdr x)) (integerp (cadr x))
       (vectorp (cddr x))))
