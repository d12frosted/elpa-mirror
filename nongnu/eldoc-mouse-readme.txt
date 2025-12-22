This package enhances `eldoc' by displaying documentation in a child frame
when the mouse hovers over a symbol.  It integrates with `posframe' for popup
documentation.  Enable it in buffers that you want to show documentation using
eldoc for the symbol under the mouse cursor.

To use, ensure posframe is installed, then add the following:

  (use-package eldoc-mouse :ensure t
    ;; replace <f1> <f1> to a key you like, "C-h ." maybe.
    ;; Displaying document on a popup when you press a key.
    :bind (:map eldoc-mouse-mode-map
           ("<f1> <f1>" . eldoc-mouse-pop-doc-at-cursor)) ;; optional
    ;; enable mouse hover for eglot managed buffers, and Emacs Lisp buffers (optional)
    :hook (eglot-managed-mode emacs-lisp-mode))

Or if you simply want to enable mouse hover for all buffers where
eldoc-mode is available as a minor mode, then:

  (use-package eldoc-mouse :ensure t
    ;; replace <f1> <f1> to a key you like, "C-h ." maybe.  Displaying document on a popup when you press a key.
    :bind (:map eldoc-mouse-mode-map
           ("<f1> <f1>" . eldoc-mouse-pop-doc-at-cursor)) ;; optional
    :hook eldoc-mode)

Or if you want to show document only when you press a key, and
don't want to enable mouse hover, then:

  (use-package eldoc-mouse :ensure t)
  ;; replace <f1> <f1> to a key you like.  Displaying document on a popup when you press a key.
  (global-set-key (kbd "<f1> <f1>") 'eldoc-mouse-pop-doc-at-cursor)

to your Emacs configuration.