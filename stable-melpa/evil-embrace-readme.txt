                             ______________

                              EVIL-EMBRACE

                              Junpeng Qiu
                             ______________


Table of Contents
_________________

1 Overview
2 Why
3 Usage
4 Screencasts


Evil integration of [embrace.el].


[embrace.el] https://github.com/cute-jumper/embrace.el


1 Overview
==========

  This package provides evil integration of [embrace.el]. Since
  `evil-surround' provides a similar set of features as `embrace.el',
  this package aims at adding the goodies of `embrace.el' to
  `evil-surround' and making `evil-surround' even better.


[embrace.el] https://github.com/cute-jumper/embrace.el


2 Why
=====

  `evil-surround' is good when there is a text object defined. But
  unfortunately, if you want to add custom surrouding pairs,
  `evil-surround' will not be able to delete/change the pairs if there
  are no evil text objects defined for these pairs. For example, if you
  want to make `\textbf{' and `}' as a surround pair in `LaTeX-mode',
  you can't either change or delete the surround pair since there is no
  text object for `\textbf{' and `}'. However, using `embrace', you can
  define whatever surrounding pairs you like, and adding, changing, and
  deleting will *always* work.

  The idea of this package is that let `evil-surround' handle the keys
  that corresponds to existing text objects (i.e., `(', `[', etc.),
  which is what `evil-surround' is good at, and make `embrace' handles
  all the other keys of custom surrounding pairs so that you can also
  benefit from the extensibility that `embrace' offers.

  In a word, you can use the default `evil-surround'. But whenever you
  want to add a custom surrounding pair, use `embrace' instead. To see
  how to add a custom pair in `embrace', look at the README of
  [embrace.el].


[embrace.el] https://github.com/cute-jumper/embrace.el


3 Usage
=======

  To enable the `evil-surround' integration:
  ,----
  | (evil-embrace-enable-evil-surround-integration)
  `----

  And use `evil-embrace-disable-evil-surround-integration' to disable
  whenever you don't like it.

  The keys that are processed by `evil-surround' are saved in the
  variable `evil-embrace-evil-surround-keys'. The default value is:
  ,----
  | (?\( ?\[ ?\{ ?\) ?\] ?\} ?\" ?\' ?< ?> ?b ?B ?t ?w ?W ?s ?p)
  `----

  Note that this variable is buffer-local. You should change it in the
  hook:
  ,----
  | (add-hook 'LaTeX-mode-hook
  |     (lambda ()
  |        (add-to-list 'evil-embrace-evil-surround-keys ?o)))
  `----

  Only these keys saved in the variable are processed by
  `evil-surround', and all the other keys will be processed by
  `embrace'.

  If you find the help message popup annoying, use the following code to
  disable it:
  ,----
  | (setq evil-embrace-show-help-p nil)
  `----


4 Screencasts
=============

  Use the following settings:
  ,----
  | (add-hook 'org-mode-hook 'embrace-org-mode-hook)
  | (evil-embrace-enable-evil-surround-integration)
  `----

  In an org-mode file, we can change the surrounding pair in the
  following way (note that this whole process can't be achieved solely
  by `evil-surround'):

  [./screencasts/evil-embrace.gif]
