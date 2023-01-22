Table of Contents
_________________

1. Use migemo on ivy.
2. How to Use?
3. Functions
.. 1. `ivy-migemo-toggle-fuzzy'
.. 2. `ivy-migemo-toggle-migemo'
4. Handle `search-default-mode'
5. License


[https://img.shields.io/github/tag/ROCKTAKEY/ivy-migemo.svg?style=flat-square]
[https://img.shields.io/github/license/ROCKTAKEY/ivy-migemo.svg?style=flat-square]
[https://img.shields.io/github/actions/workflow/status/ROCKTAKEY/ivy-migemo/CI.yml.svg?style=flat-square]
[https://img.shields.io/codecov/c/github/ROCKTAKEY/ivy-migemo/master.svg?style=flat-square]
[file:https://melpa.org/packages/ivy-migemo-badge.svg]


[https://img.shields.io/github/tag/ROCKTAKEY/ivy-migemo.svg?style=flat-square]
<https://github.com/ROCKTAKEY/ivy-migemo>

[https://img.shields.io/github/license/ROCKTAKEY/ivy-migemo.svg?style=flat-square]
<file:LICENSE>

[https://img.shields.io/github/actions/workflow/status/ROCKTAKEY/ivy-migemo/CI.yml.svg?style=flat-square]
<https://github.com/ROCKTAKEY/ivy-migemo/actions>

[https://img.shields.io/codecov/c/github/ROCKTAKEY/ivy-migemo/master.svg?style=flat-square]
<https://codecov.io/gh/ROCKTAKEY/ivy-migemo?branch=master>

[file:https://melpa.org/packages/ivy-migemo-badge.svg]
<https://melpa.org/#/ivy-migemo>


1 Use migemo on ivy.
====================


2 How to Use?
=============

  ,----
  | ;; Toggle migemo and fuzzy by command.
  | (define-key ivy-minibuffer-map (kbd "M-f") #'ivy-migemo-toggle-fuzzy)
  | (define-key ivy-minibuffer-map (kbd "M-m") #'ivy-migemo-toggle-migemo)
  |
  | ;; If you want to defaultly use migemo on swiper and counsel-find-file:
  | (setq ivy-re-builders-alist '((t . ivy--regex-plus)
  |                               (swiper . ivy-migemo-regex-plus)
  |                               (counsel-find-file . ivy-migemo-regex-plus))
  |                               ;(counsel-other-function . ivy-migemo-regex-plus)
  |                               )
  | ;; Or you prefer fuzzy match like ido:
  | (setq ivy-re-builders-alist '((t . ivy--regex-fuzzy)
  |                               (swiper . ivy-migemo-regex-fuzzy)
  |                               (counsel-find-file . ivy-migemo-regex-fuzzy))
  |                               ;(counsel-other-function . ivy-migemo-regex-fuzzy)
  |                               )
  `----


3 Functions
===========

3.1 `ivy-migemo-toggle-fuzzy'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Toggle fuzzy match or not on ivy.  Almost same as `ivy-toggle-fuzzy',
  except this function can also be used to toggle between
  `ivy-migemo-regex-fuzzy' and `ivy-migemo-regex-plus'.


3.2 `ivy-migemo-toggle-migemo'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Toggle using migemo or not on ivy.


4 Handle `search-default-mode'
==============================

  When you set `search-default-mode' a function such as
  `char-fold-to-regexp', `swiper' might through error or might not work
  with migemo.  Then, You can turn on
  `ivy-migemo-search-default-handling-mode'.  When this mode is turned
  on, `swiper--re-builder' is advised to set `search-default-mode' `nil'
  with `ivy-migemo' on.


5 License
=========

  This package is licensed by GPLv3. See [LICENSE].


[LICENSE] <file:LICENSE>
