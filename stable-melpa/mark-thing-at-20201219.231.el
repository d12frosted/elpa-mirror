;;; mark-thing-at.el --- Mark a pattern at the current point  -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Paul Landes

;; Version: 0.3
;; Package-Version: 20201219.231
;; Package-Commit: a622d128afc8d2d67de897666a1e2eccba8d7818
;; Author: Paul Landes
;; Maintainer: Paul Landes
;; Keywords: mark point lisp
;; URL: https://github.com/plandes/mark-thing-at
;; Package-Requires: ((emacs "26") (choice-program "0.13"))

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package tracks and creates bindings for region marking functions found in
;; `thingatpt'.  The library adds on functionality that:
;; * Generates functions that marks *things* (per the parlance of `thingatpt.el`
;;   library.
;; * Creates a mode-map and bindings to make it easy to mark (create a region
;;   around) a word, URL, file, number, symbol etc (see the [usage](#usage)
;;   section).
;; * Adds a *number thing*, which allows for traversing and marking numbers.


;;; Code:

(eval-when-compile (require 'cl-lib))
(require 'thingatpt)
(require 'choice-program)

(defvar mark-thing-at-choices
  '(symbol number line-this line list sexp defun
	   filename url word sentence whitespace page)
  "A list of symbols one can use to query with `thing-at-point'.
It is also used for functions such as `bounds-of-thing-at-point'.")

(defvar mark-thing-at-thing-to-command-alist nil
  "An alist of conses with the form `(THING . MARK-COMMAND)'.
Each thing corresponds to its respective mark command.
This is set dynamically by `mark-thing-at-make-functions'.")

(defvar mark-thing-at-mode-map (make-sparse-keymap)
  "Keymap of command `mark-thing-at-mode'.")

(defgroup mark-thing-at nil
  "Mark a pattern at the current point."
  :group 'text)

(defcustom mark-thing-at-keymap-prefix
  "C-x m"
  "Prefix of the keymap used for marking `things' at point.
The default binding clobbers `compose-mail'."
  :group 'mark-thing-at
  :type 'string
  :set (lambda (variable key)
	 (when (boundp variable)
	   (define-key mark-thing-at-mode-map (symbol-value variable) nil))
	 (set-default variable key)
	 (when (fboundp 'mark-thing-at-bind)
	   (mark-thing-at-bind))))

;;;###autoload
(defun mark-thing-at-point (thing)
  "Mark THING \(symbol) at current point.
See function \`bounds-of-thing-at-point' for posibilities of
THING.  This function is also used to for the new region's
bounds.  Also see `thing-at-point' and \`mark-thing-at-choices'."
  (interactive (list (choice-program-complete "Mark thing: "
					      mark-thing-at-choices)))
  (when (not (memq thing mark-thing-at-choices))
    (error "Unknown thing to query: %S" thing))
  (let ((bounds (bounds-of-thing-at-point thing)))
    (when (null bounds)
      (error "No `%S' at point" thing))
    (goto-char (car bounds))
    (push-mark nil t t)
    (goto-char (cdr bounds))))

(defun mark-thing-at-attribs ()
  "Return attributes for the marked thing."
  (mapcar #'(lambda (choice)
	      `((name . ,choice)
		(mark-func . ,(intern (format "mark-%S" choice)))
		(binding-func . ,(intern (format "mark-%S-thing" choice)))))
	  mark-thing-at-choices))

;;;###autoload
(defun mark-thing-at-make-functions ()
  "Create function for each choice with names `mark-*' \\(i.e. `mark-filename').
If this name is already that of a bound function, use `mark-*-thing'."
  (let (func-alist)
    (dolist (elt (mark-thing-at-attribs))
      (let ((name (cdr (assq 'name elt)))
	    (mark-func (cdr (assq 'mark-func elt)))
	    (binding-func (cdr (assq 'binding-func elt)))
	    fname)
	(setq fname (if (fboundp mark-func)
			binding-func
		      mark-func))
	(eval `(defun ,fname ()
		 ,(format "Mark the current %S at point." name)
		 (interactive)
		 (mark-thing-at-point (quote ,name))
		 (message ,(format "Marked %S" name))))
	(setq func-alist (append func-alist (list (cons name fname)))))
      (setq mark-thing-at-thing-to-command-alist func-alist))))

(defun mark-thing-at-make-oplist (long-options)
  "Return an alist useful for making unique keys for options or key bindings.

An alist of \(LONG-OPTION . OPTION-CHAR) conses is returned.

LONG-OPTIONS are options to create character options from, which is a list of
strings."
  (let ((uhash (make-hash-table :test 'eq :size (length long-options)))
	ualist)
    (dolist (option long-options)
      (setq ualist
	    (append ualist
		    (list
		     (cl-block 'uas
		       (dolist (option-char (string-to-list option))
			 (when (not (gethash option-char uhash))
			   (puthash option-char t uhash)
			   (cl-return-from 'uas
			     (cons option option-char)))))))))
    ualist))

(defun mark-thing-at-bind ()
  "Create keybindings for the mark-* functions.
PREFIX is the key used for the keybinding using `global-set-key'.
The functions are dynamically created with
`mark-thing-at-thing-to-command-alist'."
  (let ((option-alist (mark-thing-at-make-oplist
		       (mapcar #'symbol-name mark-thing-at-choices)))
	(keymap (make-sparse-keymap))
	command)
    (dolist (elt option-alist)
      (setq command (cdr (assq (intern (car elt))
			       mark-thing-at-thing-to-command-alist)))
      (define-key keymap (char-to-string (cdr elt)) command))
    (define-key mark-thing-at-mode-map
      (kbd mark-thing-at-keymap-prefix) keymap)))


;;; amended basic types
(defun mark-thing-at-beginning-of-number ()
  "Go to the position of beginning of the number at the cursor."
  (let ((regexp "[0-9\.-]"))
    (save-match-data
      (skip-chars-backward regexp)
      (when (or (looking-at regexp)
		(re-search-backward regexp nil t))
	(skip-chars-backward regexp)))))
(put 'number 'beginning-op 'mark-thing-at-beginning-of-number)

(defun mark-thing-at-end-of-number ()
  "Go to the position of end of the number at the cursor."
  (save-match-data (re-search-forward "[0-9.-]+" nil t)))
(put 'number 'end-op 'mark-thing-at-end-of-number)

;; don't span the next line like the default 'line thing
(put 'line-this 'beginning-op #'(lambda () (beginning-of-line)))
(put 'line-this 'end-op #'(lambda () (end-of-line)))

(mark-thing-at-make-functions)



;;;###autoload
(define-minor-mode mark-thing-at-mode
   "Minor mode for region marking functions found in
`thingatpt'.  The library adds on functionality that:

* Generates functions that marks *things* (per the parlance of `thingatpt'
  library.
* Creates a mode-map and bindings to make it easy to mark (create a region
  around) a word, URL, file, number, symbol etc (see the [usage](#usage)
  section).
* Adds a *number thing*, which allows for traversing and marking numbers.

When called interactively, toggle `mark-thing-at-mode'.  With
prefix ARG, enable `mark-thing-at-mode' if ARG is positive,
otherwise disable it.

When called from Lisp, enable `mark-thing-at-mode' if ARG is
omitted, nil or positive.  If ARG is `toggle', toggle
`mark-thing-at-mode'.  Otherwise behave as if called
interactively.

When turned on, bind keys to a set of function that mark a
pattern at the current point.  These patterns include symbols,
URLs, files, etc.

\\{mark-thing-at-mode-map}"
  :group 'mark-thing-at
  :keymap mark-thing-at-mode-map
  :global t
  (mark-thing-at-bind))

(provide 'mark-thing-at)

;;; mark-thing-at.el ends here
