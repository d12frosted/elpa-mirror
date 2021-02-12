#+OPTIONS: toc:nil title:nil timestamp:nil
* webkit-color-picker                                                :README:

Small experiment with embedded a Webkit widgets in a childframe. Requires Emacs 26 compiled with [[https://www.gnu.org/software/emacs/manual/html_node/emacs/Embedded-WebKit-Widgets.html][embedded Webkit Widget support]].

webkit-color-picker is available on [[https://melpa.org/][MELPA]]. Example configuration using [[https://github.com/jwiegley/use-package][use-package]]:

#+BEGIN_SRC emacs-lisp
(use-package webkit-color-picker
  :ensure t
  :bind (("C-c C-p" . webkit-color-picker-show)))
#+END_SRC

** Screenshot
[[./screenshots/webkit-color-picker.gif]]
