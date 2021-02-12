Table of Contents
─────────────────

1 req-package
.. 1.1 Description
.. 1.2 Usage
.. 1.3 Logging
.. 1.4 Migrate from use-package
.. 1.5 Note
.. 1.6 Contribute
.. 1.7 Changelog
..... 1.7.1 `v1.1'
..... 1.7.2 `v1.0'
..... 1.7.3 `v0.9'
..... 1.7.4 `v0.8'
..... 1.7.5 `v0.7'
..... 1.7.6 `v0.6'
..... 1.7.7 `v0.5'
..... 1.7.8 `v0.4.2'
..... 1.7.9 `v0.4.1'
..... 1.7.10 `v0.4-all-cycles'
..... 1.7.11 `v0.3-cycles'
..... 1.7.12 `v0.2-auto-fetch'


1 req-package
═════════════

  [file:https://img.shields.io/badge/license-GPL_3-green.svg]
  [file:http://melpa.org/packages/req-package-badge.svg]
  [file:http://stable.melpa.org/packages/req-package-badge.svg]
  [file:https://travis-ci.org/edvorg/req-package.svg]
  [file:https://coveralls.io/repos/edvorg/req-package/badge.svg?branch=develop&service=github]


[file:https://img.shields.io/badge/license-GPL_3-green.svg]
http://www.gnu.org/licenses/gpl-3.0.txt

[file:http://melpa.org/packages/req-package-badge.svg]
http://melpa.org/#/req-package

[file:http://stable.melpa.org/packages/req-package-badge.svg]
http://stable.melpa.org/#/req-package

[file:https://travis-ci.org/edvorg/req-package.svg]
https://travis-ci.org/edvorg/req-package

[file:https://coveralls.io/repos/edvorg/req-package/badge.svg?branch=develop&service=github]
https://coveralls.io/github/edvorg/req-package?branch=develop

1.1 Description
───────────────

  `req-package' provides dependency management for use-package.  This
  allows to write simple and modular configs.  Migration from
  use-package is simple and syntax is almost same.


1.2 Usage
─────────

  Load req-package:

  ┌────
  │ (require 'req-package)
  │
  │ (req-package el-get ;; prepare el-get (optional)
  │   :force t ;; load package immediately, no dependency resolution
  │   :config
  │   (add-to-list 'el-get-recipe-path "~/.emacs.d/el-get/el-get/recipes")
  │   (el-get 'sync))
  └────

  Define required packages with dependencies using `:require'.
  Use `:force t' if you want to avoid dependency management and load right now.
  Use `:el-get t' or `:el-get package-name' if you want to install from el-get.

  ┌────
  │ ;; init-dired.el
  │
  │ (req-package dired) ;; this form is optional as it doesn't have any configuration
  │
  │ (req-package dired-single
  │   :require dired ;; depends on dired
  │   :config (...))
  │
  │ (req-package dired-isearch
  │   :require dired ;; depends on dired
  │   :config (...))
  │
  │ ;; init-lua.el
  │
  │ (req-package lua-mode
  │   :config (...))
  │
  │ (req-package flymake-lua
  │   :require flymake lua-mode
  │   :config (...))
  │
  │ ;; init-flymake.el
  │
  │ (req-package flymake
  │   :config (...))
  │
  │ (req-package flymake-cursor
  │   :require flymake
  │   :config (...))
  │
  │ (req-package flymake-custom
  │   :require flymake
  │   :load-path "/path/to/file/directory"
  │   :config (...))
  └────

  Solve dependencies, install and load packages in right order:

  ┌────
  │ ;; order doesn't matter here
  │ (require 'init-dired)
  │ (require 'init-lua)
  │ (require 'init-flymake)
  │ (req-package-finish)
  └────


1.3 Logging
───────────

  You can use `req-package--log-open-log' to see, what is happening with
  your configuration.  You can choose log level in `req-package' group
  by `req-package-log-level' custom.  These log levels are supported:
  `fatal', `error', `warn', `info', `debug', `trace'.


1.4 Migrate from use-package
────────────────────────────

  Just replace all `(use-package ...)' with `(req-package [:require
  DEPS] ...)' and add `(req-package-finish)' at the end of your
  configuration file.  There is a `:force' keyword which simulates plain
  old use-package behavior.


1.5 Note
────────

  More complex req-package usage example can be found at
  [https://github.com/edvorg/emacs-configs].

  Use `load-dir' package to load all `*.el' files in a dir (e.g
  `~/.emacs.d/init.d')


1.6 Contribute
──────────────

  Please, pull-request your changes to `develop' branch.  Master is used
  for automatic *release* package builds by travis-ci.


1.7 Changelog
─────────────

1.7.1 `v1.1'
╌╌╌╌╌╌╌╌╌╌╌╌

  • due to use-package being mature enough drop providers system


1.7.2 `v1.0'
╌╌╌╌╌╌╌╌╌╌╌╌

  • once you called `req-package-finish' you are able reload package
    just by reload `req-package' form
  • proper errors handling. see `req-package--log-open-log' for messages
  • smart add-hook which invokes function if mode is loaded
  • refactor providers system
  • no need to use progn in :init and :config sections
  • no need to use list literal in :require section
  • `:loader' keyword now accepts loaders as keywords or as functions.
    e.g. `:el-get', `:elpa', `:built-in', `:path' and `my-loader-fn'
  • `req-package-force' replaced with `:force' keyword


1.7.3 `v0.9'
╌╌╌╌╌╌╌╌╌╌╌╌

  • `:loader' keyword support


1.7.4 `v0.8'
╌╌╌╌╌╌╌╌╌╌╌╌

  • bugfixes


1.7.5 `v0.7'
╌╌╌╌╌╌╌╌╌╌╌╌

  • fixed some issues with packages installation. all packages will be
    installed at bootstrap time
  • custom package providers support by `req-package-providers'
  • priority feature for cross provider packages loading. you can
    choose, what to try first - elpa, el-get, or something else


1.7.6 `v0.6'
╌╌╌╌╌╌╌╌╌╌╌╌

  • `el-get' support


1.7.7 `v0.5'
╌╌╌╌╌╌╌╌╌╌╌╌

  • Major system refactoring.
  • Fixed bugs with defered loading.
  • Significant performance optimization.
  • `max-specpdl-size', `max-lisp-eval-depth' issues completely solved.
  • Flexible `:require' keyword parsing.


1.7.8 `v0.4.2'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  • Bug fixes.


1.7.9 `v0.4.1'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  • Various tweaks and bug fixes.


1.7.10 `v0.4-all-cycles'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  • All cycles of your dependencies will be printed now.
  • Also there are more handy log messages and some bug fixes.


1.7.11 `v0.3-cycles'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  • There are nice error messages about cycled dependencies now.
  • Cycles printed in a way: `pkg1 -> [pkg2 -> ...] pkg1'.
  • It means there is a cycle around `pkg1'.


1.7.12 `v0.2-auto-fetch'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  • There is no need of explicit `:ensure' in your code now.
  • When you req-package it adds `:ensure' if package is available in
    your repos.
  • Also package deps `:ensure''d automatically too.
  • Just write `(req-package pkg1 :require pkg2)' and all you need will
    be installed.
