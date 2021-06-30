;;; modular-config.el --- Organize your config into small and loadable modules -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Sidharth Arya

;; Author: Sidharth Arya <sidhartharya10@gmail.com>
;; Maintainer: Sidharth Arya <sidhartharya10@gmail.com>
;; Created: 28 May 2020
;; Version: 0.1
;; Package-Version: 20210629.2319
;; Package-Commit: 222ed4aab718ebcc2944c6cca87ebc3370d5ac3c
;; Package-Requires: ((emacs "24.3"))
;; Keywords: startup lisp tools
;; URL: https://github.com/SidharthArya/modular-config.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
;; USA.

;;; Commentary:

;; modular-config.el package allows you to create custom configurations from
;; .el files contained in a specific folder.  These .el files can be loaded if
;; needed using `modular-config-load-modules` function.  Or it can be loaded
;; from the cli as `emacs --modules "space separated list of modules".  You can
;; also specify module configurations

;;; Code:

(defcustom modular-config-list '((none ()))
  "List of module configs in the format: (module-config (list of modules))
Use (add-to-list 'modular-config-list '(main (core appearance)))"
  :group 'modular-config
  :type 'list)

(defcustom modular-config-default 'none
  "The default modular-config."
  :group 'modular-config
  :type 'symbol)

(defcustom modular-config-path (concat user-emacs-directory "lisp")
  "Path where all the modules are located."
  :group 'modular-config
  :type 'string)

(defcustom modular-config-current-modules  '()
  "Path where all the modules are located."
  :group 'modular-config
  :type 'string)

(defcustom modular-config-use-separate-bookmarks nil
  "Whether to use separate bookmarks file for each config."
  :group 'modular-config
  :type 'symbol)

(defcustom modular-config-separate-bookmarks-directory "~/.emacs.d/bookmarks.d"
  "If `modular-config-use-separate-bookmarks` is set.
The directory to place bookmarks in"
  :group 'modular-config
  :type 'symbol)

(defun modular-config-command-line-args-process ()
  "Process the command line arguments."
  (interactive)
  (let ((config nil)
        (modules nil))
    (dolist (it command-line-args)
      (if (equal it "--config")
        (progn
          (setq command-line-args (delete it command-line-args))
          (setq config t))
        (if (equal config t)
          (progn
            (setq config it)
            (setq command-line-args (delete it command-line-args)))))
      (if (equal it "--modules")
        (progn
          (setq command-line-args (delete it command-line-args))
          (setq modules t))
        (if (equal modules t)
          (progn
            (setq modules it)
            (setq command-line-args (delete it command-line-args))))))
    (if (equal config nil)
      (setq config (symbol-name modular-config-default)))
    (modular-config-process (intern config))
    (if modules
        (modular-config-load-modules (modular-config-string-to-list modules)))
    (when modular-config-use-separate-bookmarks
      (unless (file-directory-p modular-config-separate-bookmarks-directory)
        (make-directory modular-config-separate-bookmarks-directory))
      (require 'bookmark)
      (setq bookmark-default-file (concat modular-config-separate-bookmarks-directory "/" config)))))

(defun modular-config-process (arg)
  "Processing various modules from the cli.
ARG is the selected modules config."
  (let ((modules nil))
    (dolist (it modular-config-list)
      (if (equal (car it) arg)
        (setq modules (car (cdr it)))))
    (if modules
      (modular-config-load-modules modules))))

(defun modular-config-string-to-list (module)
  "Convert provided MODULE from string to list."
  (mapcar #'intern (split-string module)))

(defun modular-config-load-modules (modules &optional force)
  "Function to load modules.
MODULES is the list of modules to be loaded.
If not specified, the function would ask for a space separated list of modules.
FORCE is a prefix argument."
  (interactive (list (modular-config-string-to-list (read-string "Modules: "))
                     (prefix-numeric-value current-prefix-arg)))
  (message "[Module]: %s" modular-config-current-modules)

  (message "%s" force)
  (dolist (module modules)
    (let* ((module-name (symbol-name module))
           (module-full (concat modular-config-path "/" module-name)))
      (if (or (equal force 1) (not (member module-name modular-config-current-modules)))
          (progn
          (load module-full)
          (add-to-list 'modular-config-current-modules module-name)
          (message "[Module]: %s" module-name))
       (message "[Module]: Already loaded %s" module-name)))))

(defun modular-config-modules-loaded-p (modules)
  "Check whether a list of MODULES have been loaded."
  (if (listp modules)
       (not (member nil (mapcar #'modular-config-loaded-module-p modules)))
    (modular-config-loaded-module-p modules)))

(defun modular-config-loaded-module-p (module)
  "Check whether a MODULE is loaded."
      (member (symbol-name module) modular-config-current-modules))
(provide 'modular-config)

;;; modular-config.el ends here
