Table of Contents
_________________

1. flymake-actionlint: A Flymake handler for actionlint
2. How to Use?
3. License


[https://img.shields.io/github/tag/ROCKTAKEY/flymake-actionlint.svg?style=flat-square]
[https://img.shields.io/github/license/ROCKTAKEY/flymake-actionlint.svg?style=flat-square]
[https://img.shields.io/codecov/c/github/ROCKTAKEY/flymake-actionlint.svg?style=flat-square]
[https://img.shields.io/github/actions/workflow/status/ROCKTAKEY/flymake-actionlint/test.yml.svg?branch=master&style=flat-square]


[https://img.shields.io/github/tag/ROCKTAKEY/flymake-actionlint.svg?style=flat-square]
<https://github.com/ROCKTAKEY/flymake-actionlint>

[https://img.shields.io/github/license/ROCKTAKEY/flymake-actionlint.svg?style=flat-square]
<file:LICENSE>

[https://img.shields.io/codecov/c/github/ROCKTAKEY/flymake-actionlint.svg?style=flat-square]
<https://codecov.io/gh/ROCKTAKEY/flymake-actionlint?branch=master>

[https://img.shields.io/github/actions/workflow/status/ROCKTAKEY/flymake-actionlint/test.yml.svg?branch=master&style=flat-square]
<https://github.com/ROCKTAKEY/flymake-actionlint/actions>


1 flymake-actionlint: A Flymake handler for actionlint
======================================================

  Provide `Flymake' handler for [actionlint].  Please install
  [actionlint] before using this package.


[actionlint] <https://github.com/rhysd/actionlint>


2 How to Use?
=============

  ,----
  | (add-hook 'yaml-mode-hook #'flymake-actionlint-action-load-when-actions-file)
  | (add-hook 'yaml-ts-mode-hook #'flymake-actionlint-action-load-when-actions-file)
  `----
  `flymake-actionlint-action-load-when-actions-file' automatically turns
  `flymake-actionlint' on only when the current file is a yaml file in
  `.github/workflows/'.

  Run `M-x flymake-actionlint-load' if you want to turn
  `flymake-actionlint' on manually in current buffer.


3 License
=========

  This package is licensed by The GNU General Public License verson 3 or
  later.  See [LICENSE].


[LICENSE] <file:LICENSE>
