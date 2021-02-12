CONCEPTS
========

This package is meant to modularize the Emacs user configuration,
and simplify the maintenance of multiple Emacs configurations,
reducing code duplication.
It also offers support for automatic package installation for packages
installed with package.el.

The configuration is expressed as a hierarchical structure.
The concepts provided by this library are:
- profiles
- modules
- packages

A profile is a given Emacs configuration. For example, I, the
author, have 3 profiles: job, home-windows, home-linux.


A profile can require (and customize as needed in that profile) a
set of modules.  Modules can be seen as activities, like C
programming, elisp programming, or LaTeX authoring.
Modules can require a set of packages, and customize them as needed
by the given module.

For example, the package flymake could need different customizations for
C and Python. These customizations can be written in the respective C and
Python modules, while the common base configuration can be written in
the flymake package configuration file.

Smotitah packages are customization units for Emacs packages.
Packages can be either managed or unmanaged. A managed package is a package
that has been installed with a package manager, while an unmanaged one is
a package that is manually installed and updated by the user.
At the moment, package.el is the only package manager supported by Smotitah,
but there are plans on supporting el-get too.


CONFIGURATION LAYOUT
====================

Smotitah structures the Emacs configuration as follows:

  .emacs.d/
     + profiles/
     + modules/
     + packages/

A profile file has the following structure:
----------------------------------------------------------------------
(sm-profile-pre (profile-name)
  ;; code to be executed *before* loading the modules
  )

;;; Modules to activate,
(sm-require-modules "C" "Python")

(sm-profile-post (job)
 ;; Code to be executed *after* loading the modules
  )
----------------------------------------------------------------------

A module file has the following structure (example: C programming):
----------------------------------------------------------------------
(sm-module C
           :unmanaged-p nil
           ;; Required packages list
           :require-packages '(yasnippet auto-complete-clang c-eldoc))

(sm-module-pre (C)
  ;; Code to be executed *before* loading and configuring the packages
  )

(sm-module-post (C)
  ;; Code to be executed *after* loading and configuring the packages
  )

(sm-provide :module C)
----------------------------------------------------------------------

A package file has the following structure (example: yasnippet):
----------------------------------------------------------------------
(sm-package yasnippet
            :package-manager "package"
            :unmanaged-p nil)

;; Put the package's base configuration here.
(require 'yasnippet)

(defun add-yasnippet-ac-sources ()
  (add-to-list 'ac-sources 'ac-source-yasnippet))

(sm-provide :package yasnippet)
----------------------------------------------------------------------

EXECUTING CODE AFTER A PACKAGE OR MODULE HAS BEEN LOADED
========================================================
Sometimes you can need to execute code after a given package or module
has been loaded. For example, I need to integrate the package Evil
(a vim-like editing package) with lots of other packages.
Taking care of the loading order of packages is pretty annoying.

The macro `sm-integrate-with' takes care of this.
It works like `eval-after-load' (but with no need to quote the block of
code to be executed, and with an implicit progn) if a string or symbol
is given as its first argument, but it can also take a list of the form

  (:package package-name)
or
  (:module module-name)

A example from my evil package configuration:

  (sm-integrate-with (:package direx)
    (evil-global-set-key 'normal (kbd "C-d") 'popwin:direx))

  (sm-integrate-with (:package ipa)
    (evil-global-set-key 'normal (kbd "M-i M-i") 'ipa-toggle)
    (evil-global-set-key 'normal (kbd "M-i i") 'ipa-insert)
    (evil-global-set-key 'normal (kbd "M-i e") 'ipa-edit)
    (evil-global-set-key 'normal (kbd "M-i m") 'ipa-move))


USAGE
=====

Smotitah can be loaded from .emacs.d/init.el or your .emacs file.
The procedure to activate Smotitah is different whether you manually downloaded
its source code or you installed it with package.el.

Put this in your .emacs or init.el file if you manually downloaded the sources:

    (add-to-list 'load-path user-emacs-directory)

    (setq package-archives '(("melpa" . "http://melpa.milkbox.net/packages/")))

    (add-to-list 'load-path "path/to/smotitah")
    (require 'smotitah)
    (sm-initialize)

Put this in your .emacs or init.el file if you installed smotitah with package.el.

    (add-to-list 'load-path user-emacs-directory)
    (setq package-archives '(("melpa" . "http://melpa.milkbox.net/packages/")))

    (let ((package-enable-at-startup nil))
      (package-initialize t)
      (package-activate 'smotitah (package-desc-vers (cdr (assoc 'smotitah package-alist)))))
    (sm-initialize)


Smotitah profile, module and package files stubs can be created from template
using some facilities provided by the library:

To create a profile file, M-x sm-edit-profile RET profile-name RET
To create a module file, M-x sm-edit-module RET module-name RET
To create a package file, M-x sm-edit-package RET package-name RET

If a profile, module or package with the given name is already present,
these functions will just open the file for editing.

Please note that when installing a package with package-install or
from the list-packages menu a smotitah package file is
automatically created in the .emacs.d/packages directory.

To load a given profile, set the EMACS_PROFILE environment variable
to the profile name to load:

Example: use profile-1
   $ EMACS_PROFILE="profile-1" emacs

or alternatively put this in your initialization file (init.el or .emacs):

(setq sm-profile "profile-1")

If no profile has been set in any of these two ways, smotitah will ask
the user to choose which profile to load at startup.

To load only a given set of modules, set the EMACS_MODULES environment
variable to a comma-separated list of module names:

Example: load C and python modules:
   $ EMACS_MODULES="C, python" emacs

