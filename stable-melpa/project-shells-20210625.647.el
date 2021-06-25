;;; project-shells.el --- Manage the shell buffers of each project -*- lexical-binding: t -*-

;; Copyright (C) 2017 "Huang, Ying" <huang.ying.caritas@gmail.com>

;; Author: "Huang, Ying" <huang.ying.caritas@gmail.com>
;; Maintainer: "Huang, Ying" <huang.ying.caritas@gmail.com>
;; URL: https://github.com/hying-caritas/project-shells
;; Package-Commit: 900369828f1a213c60a2207a71d46bc43fd5405c
;; Version: 20170311
;; Package-Version: 20210625.647
;; Package-X-Original-Version: 20171107.851
;; Package-X-Original-Version: 20170311
;; Package-Type: simple
;; Keywords: processes, terminals
;; Package-Requires: ((emacs "24.3") (seq "2.19"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Manage multiple shell/terminal buffers for each project.  For
;; example, to develop for Linux kernel, I usually use one shell
;; buffer to configure and build kernel, one shell buffer to run some
;; git command not supported by magit, one shell buffer to run qemu
;; for built kernel, one shell buffer to ssh into guest system to
;; test.  Different set of commands is used by the shell in each
;; buffer, so each shell should have different command history
;; configuration, and for some shell, I may need different setup.  And
;; I have several projects to work on.  In addition to project
;; specific shell buffers, I want some global shell buffers, so that I
;; can use them whichever project I am working on.  Project shells is
;; an Emacs program to let my life easier via helping me to manage all
;; these shell/terminal buffers.

;; The ssh support code is based on Ian Eure's nssh.  Thanks Ian!

;;; Code:

(require 'cl-lib)
(require 'shell)
(require 'term)
(require 'eshell)
(require 'seq)

(defvar-local project-shells-project-name nil)
(defvar-local project-shells-project-root nil)

(defvar project-shells--dest-history nil)

;;; Customization
(defgroup project-shells nil
  "Manage shell buffers of each project"
  :group 'tools
  :link '(url-link :tag "Github" "https://github.com/hying-caritas/project-shells"))

(defcustom project-shells-default-shell-name "sh"
  "Default shell buffer name."
  :group 'project-shells
  :type 'string)

(defcustom project-shells-empty-project "-"
  "Name of the empty project.

This is used to create non-project specific shells."
  :group 'project-shells
  :type 'string)

(defcustom project-shells-setup `((,project-shells-empty-project .
				   (("1" .
				     (,project-shells-default-shell-name
				      "~/" shell nil)))))
  "Configration form for shells of each project.

The format of the variable is an alist which maps the project
name (string) to the project shells configuration.  Which is an
alist which maps the key (string) to the shell configuration.
Which is a list of shell name (string), initial
directory (string), type ('shell, 'term, or 'vterm), and intialization
function (symbol or lambda)."
  :group 'project-shells
  :type '(alist :key-type (string :tag "Project") :value-type
		(alist :tag "Project setup"
		       :key-type  (string :tag "Key")
		       :value-type (list :tag "Shell setup"
					 (string :tag "Name")
					 (choice :tag "Directory" string (const ask))
					 (choice :tag "Type" (const term) (const shell) (const eshell) (const vterm))
					 (choice :tag "Function" (const nil) function)))))

(defcustom project-shells-default-init-func 'project-shells-init-sh
  "Default function to initialize the shell buffer")

(defcustom project-shells-keys '("1" "2" "3" "4" "5" "6" "7" "8" "9" "0" "-" "=")
  "Keys used to create shell buffers.

One shell will be created for each key.  Usually these key will
be bound in a non-global keymap."
  :group 'project-shells
  :type '(repeat string))

(defcustom project-shells-vterm-keys nil
  "Keys used to create vterm buffers.

One vterm will be created for each key.  Usually these key will
be bound in a non-global keymap."
  :group 'project-shells
  :type '(repeat string))

(defcustom project-shells-term-keys '("-")
  "Keys used to create terminal buffers.

By default shell mode will be used, but for keys in
‘project-shells-term-keys’, ansi terminal mode will be used.  This
should be a subset of poject-shells-keys."
  :group 'project-shells
  :type '(repeat string))

(defcustom project-shells-eshell-keys '("=")
  "Keys used to create eshell buffers.

By default shell mode will be used, but for keys in
‘project-shells-eshell-keys’, eshell mode will be used.  This
should be a subset of poject-shells-keys."
  :group 'project-shells
  :type '(repeat string))

(defcustom project-shells-session-root "~/.sessions"
  "The root directory for the shell sessions."
  :group 'project-shells
  :type 'string)

(defcustom project-shells-project-name-func 'projectile-project-name
  "Function to get project name."
  :group 'project-shells
  :type 'function)

(defcustom project-shells-project-root-func 'projectile-project-root
  "Function to get project root directory."
  :group 'project-shells
  :type 'function)

(defcustom project-shells-histfile-env "HISTFILE"
  "Environment variable to set shell history file."
  :group 'project-shells
  :type 'string)

(defcustom project-shells-histfile-name ".shell_history"
  "Shell history file name used to set environment variable."
  :group 'project-shells
  :type 'string)

(defcustom project-shells-init-file-name ".shellrc"
  "Shell initialize file name to load at startup"
  :group 'project-shells
  :type 'string)

(defcustom project-shells-term-args nil
  "Shell arguments used in terminal."
  :group 'project-shells
  :type '(repeat string))

(defcustom project-shells-keymap-prefix "C-c s"
  "project-shells keymap prefix."
  :group 'project-shells
  :type 'string)

(let ((saved-shell-buffer-list nil)
      (last-shell-name nil))
  (cl-defun project-shells--buffer-list ()
    (setf saved-shell-buffer-list
	  (cl-remove-if-not #'buffer-live-p saved-shell-buffer-list)))

  (cl-defun project-shells--switch (&optional name to-create)
    (let* ((name (or name last-shell-name))
	   (buffer-list (project-shells--buffer-list))
	   (buf (when name
		  (cl-find-if (lambda (b) (string= name (buffer-name b)))
			      buffer-list))))
      (when (and (or buf to-create)
		 (cl-find (current-buffer) buffer-list))
	(setf last-shell-name (buffer-name (current-buffer))))
      (if buf
	  (progn
	    (select-window (display-buffer buf))
	    buf)
	(unless to-create
	  (message "No such shell: %s" name)
	  nil))))

  (cl-defun project-shells-switch-to-last ()
    "Switch to the last shell buffer."
    (interactive)
    (let ((name (or (and last-shell-name (get-buffer last-shell-name)
			 last-shell-name)
		    (and (project-shells--buffer-list)
			 (buffer-name (cl-first (project-shells--buffer-list)))))))
      (if name
	  (project-shells--switch name)
	(message "No more shell buffers!"))))

  (cl-defun project-shells--create (name dir &optional (type 'shell))
    (let ((default-directory (expand-file-name (or dir "~/"))))
      (cl-ecase type
	(vterm (vterm)
	      (rename-buffer name))
	(term (ansi-term "/bin/sh")
	      (rename-buffer name))
	(shell (pop-to-buffer name)
	       (unless (comint-check-proc (current-buffer))
		 (setf comint-prompt-read-only t)
		 (cd dir)
		 (shell (current-buffer))))
	(eshell (let ((eshell-buffer-name name))
		  (eshell))))
      (push (current-buffer) saved-shell-buffer-list))))

(cl-defun project-shells-send-shell-command (cmdline)
  "Send the command line to the current (shell) buffer.  Can be
used in shell initialized function."
  (insert cmdline)
  (comint-send-input))

(cl-defun project-shells-init-sh (session-dir type)
  "Initialize the shell via loading initialize file"
  (let* ((init-file (concat session-dir "/" project-shells-init-file-name))
	 (cmdline (concat ". " init-file)))
    (when (and (not (eq type 'eshell)) (file-exists-p init-file))
      (cl-ecase type
	(shell (project-shells-send-shell-command cmdline))
	(term (term-send-raw-string (concat cmdline "\n")))))))

(cl-defun project-shells--project-name ()
  (or project-shells-project-name
      (and (symbol-function project-shells-project-name-func)
	   (funcall project-shells-project-name-func))
      project-shells-empty-project))

(cl-defun project-shells--project-root (proj-name)
  (if (string= proj-name project-shells-empty-project)
      "~/"
    (or project-shells-project-root
	(and (symbol-function project-shells-project-root-func)
	     (funcall project-shells-project-root-func))
	"~/")))

(cl-defun project-shells--setenv (env val)
  (when env
    (prog1
	(list (list env (getenv env)))
      (setenv env val))))

(cl-defun project-shells--histfile-name (session-dir)
  (when project-shells-histfile-name
    (expand-file-name project-shells-histfile-name session-dir)))

(cl-defun project-shells--set-shell-env (session-dir)
  (when project-shells-histfile-name
    (project-shells--setenv project-shells-histfile-env
			    (project-shells--histfile-name session-dir))))

(cl-defun project-shells--restore-shell-env (saved-env)
  (cl-loop
   for env-val in (reverse saved-env)
   do (apply #'setenv env-val)))

(cl-defun project-shells--command-string (args)
  (mapconcat
   #'identity
   (cl-loop
    for arg in args
    collect (concat "\"" (shell-quote-argument arg) "\""))
   " "))

(cl-defun project-shells--term-command-string ()
  (let* ((prog (or explicit-shell-file-name
		   (getenv "ESHELL") shell-file-name)))
    (concat "exec " (project-shells--command-string
		     (cons prog project-shells-term-args)) "\n")))

;;;###autoload
(cl-defun project-shells-activate-for-key (key &optional proj proj-root)
  "Create or switch to the shell buffer for the key, the project
name, and the project root directory."
  (let* ((key (replace-regexp-in-string "/" "slash" key))
	 (proj (or proj (project-shells--project-name)))
	 (proj-shells (cdr (assoc proj project-shells-setup)))
	 (shell-info (cdr (assoc key proj-shells)))
	 (name (or (cl-first shell-info) project-shells-default-shell-name))
	 (shell-name (format "*%s.%s.%s*" key name proj)))
    (unless (project-shells--switch shell-name t)
      (let* ((proj-root (or proj-root (project-shells--project-root proj)))
	     (type (cond
		    ((cl-third shell-info))
		    ((member key project-shells-term-keys) 'term)
		    ((member key project-shells-eshell-keys) 'eshell)
		    ((member key project-shells-vterm-keys) 'vterm)
		    (t 'shell)))
	     (dir (or (cl-second shell-info) proj-root))
	     (func (cl-fourth shell-info))
	     (session-dir (expand-file-name (format "%s/%s" proj key)
					    project-shells-session-root))
	     (saved-env nil))
	(when (eq dir 'ask)
	  (let* ((dest (completing-read
			"Destination: "
			project-shells--dest-history
			nil nil nil 'project-shells--dest-history)))
	    (setf dir (if (or (string-prefix-p "/" dest)
			      (string-prefix-p "~" dest))
			  dest
			(format "/ssh:%s:" dest)))))
	(setf saved-env (project-shells--set-shell-env session-dir))
	(unwind-protect
	    (progn
	      (mkdir session-dir t)
	      (project-shells--create shell-name dir type)
	      (cl-case type
		(term
		 (term-send-raw-string (project-shells--term-command-string)))
		(eshell
		 (setq-local eshell-history-file-name
			     (project-shells--histfile-name session-dir))
		 (eshell-read-history)))
	      (when (or (string-prefix-p "/ssh:" dir)
			(string-prefix-p "/sudo:" dir))
		(set-process-sentinel (get-buffer-process (current-buffer))
				      #'shell-write-history-on-exit))
	      (setf project-shells-project-name proj
		    project-shells-project-root proj-root)
	      (when project-shells-default-init-func
		(funcall project-shells-default-init-func session-dir type))
	      (project-shells-mode)
	      (when func
		(funcall func session-dir)))
	  (project-shells--restore-shell-env saved-env))))))

;;;###autoload
(cl-defun project-shells-activate (p)
  "Create or switch to the shell buffer for the key just typed"
  (interactive "p")
  (let* ((keys (this-command-keys-vector))
	 (key (seq-subseq keys (1- (seq-length keys))))
	 (key-desc (key-description key)))
    (project-shells-activate-for-key
     key-desc (and (/= p 1) project-shells-empty-project))))

;;;###autoload
(cl-defun project-shells-setup (map &optional setup)
  "Configure the project shells with the prefix keymap and the
setup, for format of setup, please refer to document of
project-shells-setup."
  (when setup
    (setf project-shells-setup setup))
  (cl-loop
   for key in project-shells-keys
   do (define-key map (kbd key) 'project-shells-activate)))

;;; Minor mode

(defvar project-shells-map
  (let ((map (make-sparse-keymap)))
    (project-shells-setup map)
    (define-key map (kbd "s") 'project-shells-switch-to-last)
    map)
  "Sub-keymap for project-shells mode.")
(fset 'project-shells-map project-shells-map)

(defvar project-shells-mode-map
  (let ((sub-map (make-sparse-keymap))
	(map (make-sparse-keymap)))
    (project-shells-setup sub-map)
    (define-key map (kbd project-shells-keymap-prefix)
      'project-shells-map)
    map)
  "Keymap for project-shells mode.")

;;;###autoload
(define-minor-mode project-shells-mode
  nil
  :keymap project-shells-mode-map
  :group project-shells)

;;;###autoload
(define-globalized-minor-mode global-project-shells-mode
  project-shells-mode project-shells-mode)

(provide 'project-shells)

;;; project-shells.el ends here
