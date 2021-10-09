# -*- mode:org; ispell-dictionary:"en_GB"  -*-
#+TITLE: flymake backend clj-kondo
#+AUTHOR: https://turbocafe.keybase.pub

this  package  integrates  clj-kondo  a  clojure  linter  into  emacs'
flymake;  to use  this  package get  clj-kondo following  [[https://github.com/borkdude/clj-kondo/blob/master/doc/install.md][installation
instructions]]; then proceed with your preferred way of adding packages

* melpa

#+BEGIN_SRC emacs-lisp
(use-package flymake-kondor
  :ensure flymake-quickdef
  :hook (clojure-mode . flymake-kondor-setup))
#+END_SRC

* github

#+BEGIN_SRC emacs-lisp
(el-get-bundle flymake-kondor
               :url "https://raw.githubusercontent.com/turbo-cafe/flymake-kondor/master/flymake-kondor.el"
               (add-hook 'clojure-mode-hook #'flymake-kondor-setup))
#+END_SRC

* local

#+BEGIN_SRC emacs-lisp
(add-to-list 'load-path "~/path/to/flymake-kondor")
(require "flymake-kondor")
(add-hook 'clojure-mode-hook #'flymake-kondor-setup)
#+END_SRC


* note about flymake

to start linting  activate =M-x flymake-mode= in  clojure buffer; even
better assign hook  and keys so you could navigate  to prev/next error
in buffer instantly

#+BEGIN_SRC emacs-lisp
(use-package flymake
  :ensure nil
  :bind (([f8] . flymake-goto-next-error)
         ([f7] . flymake-goto-prev-error))
  :hook (prog-mode . (lambda () (flymake-mode t)))
  :config (remove-hook 'flymake-diagnostic-functions #'flymake-proc-legacy-flymake))
#+END_SRC

there's [[https://github.com/borkdude/flycheck-clj-kondo][sister project]] that integrates  clj-kondo into flycheck

