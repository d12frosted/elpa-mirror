This package enhances `nov-mode' by displaying the content of the link in a
popup when the mouse hovers over a link.

To use, ensure `eldoc-mouse' is installed, then add the following:

  (use-package eldoc-mouse :ensure t
    ;; replace <f1> <f1> to a key you like, "C-h ." maybe.
    :bind (:map eldoc-mouse-mode-map
           ("<f1> <f1>" . eldoc-mouse-pop-doc-at-cursor)) ;; optional
    ;; enable mouse hover
    :hook (eglot-managed-mode emacs-lisp-mode nov-mode))

  (use-package eldoc-mouse-nov
    :ensure t
    :after (eldoc-mouse)
    :hook (nov-mode))

to your Emacs configuration.