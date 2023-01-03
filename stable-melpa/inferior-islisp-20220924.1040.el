;;; inferior-islisp.el ---  Run inferior ISLisp processes            -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Fermin Munoz

;; Author: Fermin Munoz
;; Maintainer: Fermin Munoz <fmfs@posteo.net>
;; Created: 24 Sep 2021
;; Version: 0.2.0
;; Keywords: islisp, lisp, programming
;; URL: https://gitlab.com/sasanidas/islisp-mode
;; Package-Requires: ((emacs "26.3") (islisp-mode "0.2"))
;; License: GPL-3.0-or-later

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Quick intro
;;
;; It is recommended to use inferior-islisp-mode~ alongside islisp-mode for better integration.
;; REPL integration for the ISLisp programming language
;; It contains a simple but useful REPL and some common functions to interact with it.

;;; Code:

;;;; The requires

(require 'comint)
(require 'islisp-mode)
(require 'inf-lisp)

(defgroup inferior-islisp nil
  "Run a ISLisp process in a buffer."
  :group 'islisp)

(defcustom inferior-islisp-command-line '("eisl")
  "Command line for calling an inferior islisp process."
  :type 'string
  :group 'inferior-islisp)

(defcustom inferior-islisp-source-modes '(islisp-mode)
  "List of modes which indicate a buffer contains ISLisp source code."
  :type '(repeat function)
  :group 'inferior-islisp)

(defcustom inferior-islisp-prompt "^>>? *"
  "Command line for calling an inferior islisp process."
  :type 'string
  :group 'inferior-islisp)

(defcustom inferior-islisp-load-command "(load \"%s\")\n"
  "Format-string for building a ISLisp expression to load a file."
  :type 'string
  :group 'inferior-islisp)

(defvar inferior-islisp-mode-hook '()
  "Hook for customising Inferior ISLisp mode.")

(defvar inferior-islisp-buffer "*inferior-islisp*"
  "Inferior ISLisp buffer name.")

(defvar inferior-islisp-prev-l-c-dir-file nil
  "Record last directory and file used in loading or compiling.
This holds a cons cell of the form `(DIRECTORY . FILE)'
describing the last `islisp-load-file' or `islisp-compile-file' command.")

(defun inferior-islisp-proc ()
  "Return the `inferior-islisp-buffer' process."
  (let ((proc (get-buffer-process (get-buffer inferior-islisp-buffer))))
    (or proc
	(error "No ISLisp subprocess; see variable `inferior-islisp-buffer'"))))

(defun inferior-islisp-eval-region (start end &optional _and-go)
  "Send the current region from START to END the inferior ISLisp process."
  (interactive "r\nP")
  (comint-send-region (inferior-islisp-proc) start end)
  (comint-send-string (inferior-islisp-proc) "\n"))

(defun inferior-islisp-eval-string (string)
  "Send STRING to the inferior Lisp process to be executed."
  (comint-send-string (inferior-islisp-proc) (concat string "\n")))

(defun inferior-islisp-do-defun (do-region)
  "Send the current defun in DO-REGION to the inferior Lisp process."
  (save-excursion
    (beginning-of-defun)
    (forward-sexp)
    (let ((end (point)) (case-fold-search t))
      (beginning-of-defun)
      (funcall do-region (point) end))))

(defun inferior-islisp-eval-defun (&optional _and-go)
  "Send the current defun to the inferior ISLisp process."
  (interactive "P")
  (inferior-islisp-do-defun 'inferior-islisp-eval-region))

(defun inferior-islisp-eval-last-sexp (&optional _and-go)
  "Send the previous sexp to the inferior ISLisp process."
  (interactive "p")
  (let* ((close (point-max))
	 (start (save-excursion
		  (when (and (eolp) (not (bolp)))
		    (backward-char))
		  (setq close (1- (scan-lists (point) 1 1)))
		  (when (< close (line-end-position))
		    (goto-char (1+ close))
		    (backward-list)
		    (point)))))
    (comint-send-string (inferior-islisp-proc)
			(buffer-substring-no-properties
			 start
			 (+ (point) 1)))
    (comint-send-string (inferior-islisp-proc) "\n")))

;;TODO: This is Easy-ISLisp specific
(defun inferior-islisp-load-file (file-name)
  "Load a ISLisp file with FILE-NAME into the inferior ISLisp process."
  (interactive "f")
  (comint-check-source file-name)
  (setq inferior-islisp-prev-l-c-dir-file (cons (file-name-directory    file-name)
						(file-name-nondirectory file-name)))
  (comint-send-string (inferior-islisp-proc)
		      (format inferior-islisp-load-command file-name))

  (comint-send-string (inferior-islisp-proc)
		      (format "(format (standard-output) \"Loaded: %s\")\n" file-name)))

;;TODO: This is Easy-ISLisp specific
(defun inferior-islisp-compile-file (file-name)
  "Compile a ISLisp FILE-NAME in the inferior ISLisp process."
  (interactive (comint-get-source "Compile ISLisp file: " inferior-islisp-prev-l-c-dir-file
				  inferior-islisp-source-modes nil))
  (comint-check-source file-name)
  (setq inferior-islisp-prev-l-c-dir-file (cons (file-name-directory    file-name)
				 (file-name-nondirectory file-name)))
  (comint-send-string (inferior-islisp-proc) (concat "(compile-file \"" file-name "\")\n")))

;;;###autoload
(defun inferior-islisp ()
  "Launch the `inferior-islisp' comint buffer."
  (interactive)
  (unless (comint-check-proc "*inferior-islisp*")
    (set-buffer (apply (function make-comint)
		       "inferior-islisp" inferior-islisp-command-line))
    (inferior-islisp-mode))
  (pop-to-buffer-same-window (get-buffer-create inferior-islisp-buffer)))

(define-derived-mode inferior-islisp-mode comint-mode "Inferior ISLisp"
  (islisp-mode-variables)
  (setq-local comint-prompt-regexp inferior-islisp-prompt
	      mode-line-process '(":%s")
	      comint-get-old-input (function lisp-get-old-input)
	      comint-prompt-read-only t)
  (islisp-use-implementation))


(provide 'inferior-islisp)
;;; inferior-islisp.el ends here
