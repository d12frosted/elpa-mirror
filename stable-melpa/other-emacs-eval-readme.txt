Eval the Emacs Lisp expression in other Emacs.

(other-emacs-eval 'emacs-version)
;; => "27.0.50"

(other-emacs-eval 'emacs-version "emacs-25.3.1")
;; => "25.3.1"

(other-emacs-eval 'emacs-version "emacs-24.4.2")
;; => "24.4.2"
