The enhanced-evil-paredit package prevents parenthesis imbalance when using
evil-mode with paredit.

It intercepts evil-mode commands such as delete, change, and paste, blocking
their execution if they would break the parenthetical structure. This
guarantees that your Lisp code remains syntactically correct while retaining
the editing features of evil-mode.

Installation from MELPA:
------------------------
(use-package enhanced-evil-paredit
  :ensure t
  :config
  (add-hook 'paredit-mode-hook #'enhanced-evil-paredit-mode))

Links:
------
- enhanced-evil-paredit @GitHub:
  https://github.com/jamescherti/enhanced-evil-paredit.el
