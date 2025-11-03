This package enhances eldoc' by displaying documentation in a child frame
when the mouse hovers over a symbol.  It integrates with posframe' for popup
documentation.  Enable it in buffers that you want to show documentation using
eldoc for the symbol under the mouse cursor.

To use, ensure posframe is installed, then add the following:

The following two lines are both optional, but you would like to add at least one of them to your Emacs configuration.
(use-package eldoc-mouse :hook (eglot-managed-mode emacs-lisp-mode)) ;; enable mouse hover for eglot managed buffers, and Emacs Lisp buffers.
(global-set-key (kbd "<f1> <f1>") 'eldoc-mouse-pop-doc-at-cursor) ;; replace <f1> <f1> to a key you like.  Displaying document on a popup when you press a key.

to your Emacs configuration.
