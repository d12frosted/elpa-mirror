The enhanced-evil-paredit package prevents parenthesis imbalance when using
evil-mode with paredit.

It intercepts evil-mode commands such as delete, change, and paste, blocking
their execution if they would break the parenthetical structure. This
guarantees that your Lisp code remains syntactically correct while retaining
the editing features of evil-mode.

Installation from MELPA:
------------------------
;; `paredit-mode' is a requirement
(use-package paredit
  :ensure t
  :commands paredit-mode
  :hook
  (emacs-lisp-mode . paredit-mode))

(use-package enhanced-evil-paredit
  :ensure t
  :commands enhanced-evil-paredit-mode
  :hook (paredit-mode . enhanced-evil-paredit-mode))

Links:
------
- enhanced-evil-paredit @GitHub:
  https://github.com/jamescherti/enhanced-evil-paredit.el
