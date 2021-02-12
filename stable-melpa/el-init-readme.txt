el-init loads split configuration files with `require' instead of `load'.

* Basic Usage

For example, there are configuration files like below,

    ~/.emacs.d/inits
    ├── ext/
    │   └── init-helm.el
    ├── lang/
    │   ├── init-emacs-lisp.el
    │   └── init-javascript.el
    └── init-package.el

you load them with following code.

    (require 'el-init)

    (el-init-load "~/.emacs.d/inits"
                  :subdirectories '("." "ext" "lang"))
