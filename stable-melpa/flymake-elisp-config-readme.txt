Table of Contents
_________________

1. flymake-elisp-config: Setup `load-path' for flymake on Emacs Lisp mode
2. How to Use?
3. Add configurer
.. 1. Define predicate
.. 2. Define configurer
4. License


[https://img.shields.io/github/tag/ROCKTAKEY/flymake-elisp-config.svg?style=flat-square]
[https://img.shields.io/github/license/ROCKTAKEY/flymake-elisp-config.svg?style=flat-square]
[https://img.shields.io/codecov/c/github/ROCKTAKEY/flymake-elisp-config.svg?style=flat-square]
[https://img.shields.io/github/workflow/status/ROCKTAKEY/flymake-elisp-config/test/master.svg?style=flat-square]


[https://img.shields.io/github/tag/ROCKTAKEY/flymake-elisp-config.svg?style=flat-square]
<https://github.com/ROCKTAKEY/flymake-elisp-config>

[https://img.shields.io/github/license/ROCKTAKEY/flymake-elisp-config.svg?style=flat-square]
<file:LICENSE>

[https://img.shields.io/codecov/c/github/ROCKTAKEY/flymake-elisp-config.svg?style=flat-square]
<https://codecov.io/gh/ROCKTAKEY/flymake-elisp-config?branch=master>

[https://img.shields.io/github/workflow/status/ROCKTAKEY/flymake-elisp-config/test/master.svg?style=flat-square]
<https://github.com/ROCKTAKEY/flymake-elisp-config/actions>


1 flymake-elisp-config: Setup `load-path' for flymake on Emacs Lisp mode
========================================================================

  Default `load-path' for flymake on Emacs Lisp mode can be set through
  `elisp-flymake-byte-compile-load-path', but it is just a global
  variable.  When you are editing init.el, flymake should use all the
  `load-path'.  When you update some packages, `load-path' also should
  be updated.  When you are editing your package, flymake should use
  paths provided by cask or keg.

  This package provides three features:
  - Customizable variable `flymake-elisp-config-load-path-getter', which
    is a `FUNCTION' returning `load-path' for flymake.
  - Automatic setting of `load-path' for flymake by
    `flymake-elisp-config-auto-mode'.
  - Manual setting of it by configurers named
    `flymake-elisp-config-as-*'.


2 How to Use?
=============

  Just write in init.el:
  ,----
  | ;; Make `load-path' for flymake customizable through `flymake-elisp-config-load-path-getter'.
  | (flymake-elisp-config-global-mode)
  | ;; Automatically set `load-path' for flymake.
  | (flymake-elisp-config-auto-mode)
  `----

  If automatical setting is wrong, you can use
  `flymake-elisp-config-as-*' commands to change `load-path' for flymake
  manually.
  `flymake-elisp-config-as-config'
        Emacs configuration file such as init.el
  `flymake-elisp-config-as-keg'
        Emacs Lisp project managed by `keg'.
  `flymake-elisp-config-as-cask'
        Emacs Lisp project managed by `cask'.
  `flymake-elisp-config-as-eask'
        Emacs Lisp project managed by `eask'.
  `flymake-elisp-config-as-default'
        Default Emacs Lisp file.  It uses same `load-path' as default
        flymake.


3 Add configurer
================

  When you want to use another `load-path' getter, you can define
  `configurer'.  It can be achived by three steps:
  1. Define predicate
  2. Define configurer
  3. Register to `flymake-elisp-config-auto-configurer-alist'


3.1 Define predicate
~~~~~~~~~~~~~~~~~~~~

  Define predicate function, which takes `BUFFER' as an argument, and
  which return `non-nil' only when `flymake' should use your new
  configurer.


3.2 Define configurer
~~~~~~~~~~~~~~~~~~~~~

  Define configurer function, which takes `BUFFER' as an argument, and
  which sets `flymake-elisp-config-load-path-getter' in `BUFFER'.

  The value of `flymake-elisp-config-load-path-getter' should be a
  function which takes `BUFFER' as an argument, and returns list of
  path, like `load-path', which is used by `flymake' on `BUFFER'.


4 License
=========

  This package is licensed by GPLv3. See [LICENSE].


[LICENSE] <file:LICENSE>
