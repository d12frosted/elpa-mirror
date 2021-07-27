;;; modular-config.el --- Organize your config into small and loadable modules -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Sidharth Arya

;; Author: Sidharth Arya <sidhartharya10@gmail.com>
;; Maintainer: Sidharth Arya <sidhartharya10@gmail.com>
;; Created: 28 May 2020
;; Version: 0.5
;; Package-Version: 20210726.1614
;; Package-Commit: 2bd77193fa3a7ec0541db284b4034821a8f59fea
;; Package-Requires: ((emacs "25.1"))
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

(require 'cl-seq)

(defgroup modular-config nil
  "modular-config.el package allows you to create custom configurations from
.el files contained in a specific folder"
  :group 'convenience
  :prefix "modular-config-"
  :link '(url-link "https://github.com/SidharthArya/modular-config.el"))

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

(defcustom modular-config-separate-bookmarks-directory (concat user-emacs-directory "/bookmarks.d")
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
        (when (equal config t)
            (setq config it)
            (setq command-line-args (delete it command-line-args))))
      (if (equal it "--modules")
        (progn
          (setq command-line-args (delete it command-line-args))
          (setq modules t))
        (when (equal modules t)
            (setq modules it)
            (setq command-line-args (delete it command-line-args)))))
    (when (equal config nil)
      (setq config (symbol-name modular-config-default)))
    (modular-config-process (intern config))
    (when modules
        (modular-config-load-modules (modular-config-string-to-list modules)))
    (when modular-config-use-separate-bookmarks
      (unless (file-directory-p modular-config-separate-bookmarks-directory)
        (make-directory modular-config-separate-bookmarks-directory))
      (require 'bookmark)
      (setq bookmark-default-file (concat modular-config-separate-bookmarks-directory "/" config)))))

(defun modular-config-process (arg &rest notargs)
  "Processing various modules from the cli.
ARG is the selected modules config."
  (let ((modules nil))
    (dolist (it modular-config-list)
      (when (equal (car it) arg)
        (setq modules (car (cdr it)))))
    (setq modules (cl-set-difference modules (car notargs)))
    (message "notargs: %s" modules)
    (when modules
      (setq modules (delete 'nil (mapcar #'modular-config-process-inherit-config modules)))
      (modular-config-load-modules modules))))

  (defun modular-config-process-inherit-config(module)
    "Process inherited configs"
    (if (listp module)
        (progn
          (modular-config-process (car module) (cdr module))
          nil)
      module))
  
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
