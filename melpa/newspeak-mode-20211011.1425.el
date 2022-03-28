;;; newspeak-mode.el --- Major mode for the Newspeak programming language  -*- lexical-binding:t -*-

;; Author: Daniel Szmulewicz
;; Maintainer: Daniel Szmulewicz <daniel.szmulewicz@gmail.com>
;; Version: 1.0
;; © 2021 Daniel Szmulewicz
;; Package-Requires: ((emacs "24.3"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;; Major mode for Newspeak (https://newspeaklanguage.org//)
;; URL: https://github.com/danielsz/newspeak-mode

;; Provides the following functionality:
;; - Syntax highlighting.
;; - Indentation

;;; Code:

(require 'rx)

;;; syntax table

(defconst newspeak-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?\( "() 1" table)
    (modify-syntax-entry ?\) ")( 4" table)
    (modify-syntax-entry ?|  "." table) ; punctuation
    (modify-syntax-entry ?* ". 23" table) ; Comment
    (modify-syntax-entry ?' "\"" table) ; String
    (modify-syntax-entry ?# "'" table) ; Expression prefix
    (modify-syntax-entry ?: "_" table)  ; colon is part of symbol
    (modify-syntax-entry ?< "(>" table) ; Type-hint-open interferes with rainbow-delimiters mode for symbol >
    (modify-syntax-entry ?> ")<" table) ; Type-hint-close
    table)
  "Newspeak mode syntax table.")

;;;;; Customization

(defgroup newspeak ()
  "Custom group for the Newspeak major mode"
  :group 'languages)

;;;;; font-lock
;;;;; syntax highlighting

(defface newspeak-font-lock-type-face
  '((t (:inherit font-lock-type-face :bold t)))
  "Face description for types"
  :group 'newspeak)

(defface newspeak-font-lock-builtin-face
  '((t (:inherit font-lock-builtin-face)))
  "Face description for access modifiers"
  :group 'newspeak)

(defface newspeak-font-lock-constant-face
  '((t (:inherit font-lock-constant-face)))
  "Face description for reserved keywords"
  :group 'newspeak)

(defface newspeak-font-lock-keyword-face
  '((t (:inherit font-lock-keyword-face)))
  "Face description for block arguments"
  :group 'newspeak)

(defface newspeak-font-lock-warning-face
  '((t (:inherit font-lock-warning-face)))
  "Face description for `Newspeak3'"
  :group 'newspeak)

(defface newspeak-font-lock-variable-name-face
  '((t (:inherit font-lock-variable-name-face)))
  "Face description for slot assignments"
  :group 'newspeak)

(defface newspeak-font-lock-function-name-face
  '((t (:inherit font-lock-function-name-face)))
  "Face description for keyword and setter sends"
  :group 'newspeak)

(defface newspeak-font-lock-string-face
  '((t (:inherit font-lock-string-face)))
  "Face description for strings"
  :group 'newspeak)

(defface newspeak-font-lock-comment-face
  '((t (:inherit font-lock-comment-face)))
  "Face description for comments"
  :group 'newspeak)

(defvar newspeak-prettify-symbols-alist
  '(("^" . ?⇑)
    ("::=" . ?⇐)))

;; regexes definitions

(defconst newspeak--reserved-words (rx (or "yourself" "super" "outer" "true" "false" "nil" (seq symbol-start "self" symbol-end) (seq symbol-start "class" symbol-end))))
(defconst newspeak--access-modifiers (rx (or "private" "public" "protected")))
(defconst newspeak--block-arguments (rx word-start ":" (* alphanumeric)))
(defconst newspeak--symbol-literals (rx (seq ?# (* alphanumeric))))
(defconst newspeak--peculiar-construct (rx line-start "Newspeak3" line-end))
(defconst newspeak--class-names (rx word-start upper-case (* alphanumeric)))
(defconst newspeak--slots (rx (seq (or alpha ?_) (* (or alphanumeric ?_)) (+ whitespace) ?= (+ whitespace))))
(defconst newspeak--type-hints (rx (seq ?< (* alphanumeric) (zero-or-more (seq ?\[ (zero-or-more (seq (* alphanumeric) ?, whitespace)) (* alphanumeric) ?\])) ?>)))
(defconst newspeak--keyword-or-setter-send (rx (or alpha ?_) (* (or alphanumeric ?_)) (** 1 2 ?:)))

(defconst newspeak-font-lock
  `((,newspeak--reserved-words . 'newspeak-font-lock-constant-face)                 ;; reserved words
    (,newspeak--access-modifiers . 'newspeak-font-lock-builtin-face)                ;; access modifiers
    (,newspeak--block-arguments . 'newspeak-font-lock-keyword-face)                 ;; block arguments
    (,newspeak--symbol-literals . 'newspeak-font-lock-keyword-face)                 ;; symbol literals
    (,newspeak--peculiar-construct . 'newspeak-font-lock-warning-face)              ;; peculiar construct
    (,newspeak--class-names . 'newspeak-font-lock-type-face)                        ;; class names
    (,newspeak--slots . 'newspeak-font-lock-variable-name-face)                     ;; slots
    (,newspeak--type-hints . 'newspeak-font-lock-type-face)                         ;; type hints
    (,newspeak--keyword-or-setter-send . 'newspeak-font-lock-function-name-face)))  ;; keyword send and setter send

;;;;

(defcustom newspeak-basic-indent 2
  "'Tab size'; used for simple indentation alignment."
  :type 'integer)

;;;; Scanner

(defun newspeak--thought-control (tok)
  "Take a TOK and return a simpler one."
  (cond
   ((string-match newspeak--access-modifiers tok) "modifier")
   ((string-match newspeak--class-names tok) "class-name")
   ((string-match newspeak--keyword-or-setter-send tok) "keyword-or-setter-send")
   ((string= tok "class") "class")
   ((eq ?' (string-to-char tok)) "string-delimiter")
   ((eq ?\( (string-to-char tok)) "open-parenthesis")
   ((eq ?\) (string-to-char tok)) "close-parenthesis")
   ((eq ?\[ (string-to-char tok)) "open-block")
   ((eq ?\] (string-to-char tok)) "close-block")
   ((eq ?^ (string-to-char tok)) "return")
   ((eq ?| (string-to-char tok)) "|")
   ((eq ?< (string-to-char tok)) (progn
				   (backward-char)
				   (if (looking-at newspeak--type-hints)
				       (progn (goto-char (match-end 0))
 					      "type-hint")
				     (progn
				       (forward-char)
				       tok))))
   ((string= tok "]>") (progn
			 (forward-char)
			 (forward-char)
			 (if (looking-back newspeak--type-hints 3)
				   (progn (goto-char (match-beginning 0))
 					  "type-hint")
				 (progn
				   (backward-char)
				   (backward-char)
				   tok))))
   (t tok)))

(defun newspeak--default-forward-token ()
  "Skip token forward and return it."
  (if (forward-comment 1)
      "comment"
    (buffer-substring-no-properties
     (point)
     (progn (if (zerop (skip-syntax-forward ".()"))
		(skip-syntax-forward "w_'"))
            (point)))))

(defun newspeak--default-backward-token ()
  "Skip token backward and return it."
  (cond
   ((newspeak--within-comment-p) (progn (goto-char (nth 8 (syntax-ppss)))
					"comment"))
   ((forward-comment -1) "comment")
   ((newspeak--within-string-p) (progn (goto-char (nth 8 (syntax-ppss)))
				  "string"))
   (t (buffer-substring-no-properties
     (point)
     (progn (if (zerop (skip-syntax-backward ".()\""))
		(skip-syntax-backward "w_'"))
            (point))))))

(defun newspeak--forward-token ()
  "Skip token forward and return it, along with its levels."
  (let ((tok (newspeak--default-forward-token)))
    (newspeak--thought-control tok)))

(defun newspeak--backward-token ()
  "Skip token backward and return it, along with its levels."
  (let ((tok (newspeak--default-backward-token)))
    (newspeak--thought-control tok)))

(defun newspeak--scan-ahead (&optional count)
  "Find nearest token going forward.  Return number of tokens specified by COUNT, or just one."
  (let (lst)
    (save-excursion
      (while (< (length lst) (or count 1))
	(push (newspeak--forward-token) lst))
      (if count
	  lst
	(car lst)))))

(defun newspeak--scan-behind (&optional count)
  "Find nearest token going backward.  Return number of tokens specified by COUNT, or just one."
  (let (lst)
    (save-excursion
      (while (< (length lst) (or count 1))
	(push (newspeak--backward-token) lst))
      (if count
	  lst
	(car lst)))))

;;;; Indentation logic

(defun newspeak--within-slots-p ()
  "Return TRUE if we are in a slots declaration."
  (let (lst)
    (save-excursion
      (while (not (or (bobp) (member "|" lst) (member "open-parenthesis" lst)))
	(push (newspeak--backward-token) lst))
      (string= "|" (car lst)))))

(defun newspeak--within-block-p ()
  "Return TRUE if we are in a code block."
  (let (lst)
    (save-excursion
      (while (not (or (bobp) (member "open-block" lst) (member "|" lst) (member "open-parenthesis" lst)))
	(push (newspeak--backward-token) lst))
      (string= "open-block" (car lst)))))

(defun newspeak--first-line-in-block-p ()
  "Return TRUE if we are indenting the first line in a code block."
  (let ((line (line-number-at-pos)))
    (save-excursion
      (re-search-backward (rx "["))
      (= (- line 1) (line-number-at-pos)))))

(defun newspeak--closing-block-p ()
  "Return TRUE if we are indenting the first line in a code block."
  (let ((line (line-number-at-pos)))
    (save-excursion
      (re-search-forward (rx "]"))
      (= line (line-number-at-pos)))))

(defun newspeak--column-token (REGEX)
  "Return column of beginning of line containing REGEX."
  (save-excursion
    (re-search-backward REGEX)
    (back-to-indentation)
    (current-column)))

(defun newspeak--modifier-p ()
  "Return TRUE if line begins with a modifier."
  (save-excursion
    (beginning-of-line)
    (string= "modifier" (newspeak--scan-ahead))))

(defun newspeak--class-p ()
  "Return TRUE if line begins with a modifier."
  (save-excursion
    (beginning-of-line)
    (member"class" (newspeak--scan-ahead 2))))

(defun newspeak--close-parenthesis-p ()
  "Return TRUE if line begins with a close-parenthesis."
  (save-excursion
    (beginning-of-line)
    (string= "close-parenthesis" (newspeak--scan-ahead))))

(defun newspeak--|-p ()
  "Return TRUE if line begins with a |."
  (save-excursion
    (beginning-of-line)
    (string= "|" (newspeak--scan-ahead))))

(defun newspeak--within-comment-p ()
  "Return TRUE if point is within a comment."
  (nth 4 (syntax-ppss)))

(defun newspeak--within-string-p ()
  "Return TRUE if point is within a comment."
  (nth 3 (syntax-ppss)))

(defun newspeak--indent-line ()
  "Main indentation logic."
  (cond
   ((string= "comment" (newspeak--scan-ahead)) nil)
   ((newspeak--class-p) (indent-line-to 0))
   ((newspeak--close-parenthesis-p) (indent-line-to 0))
   ((newspeak--modifier-p) (if (newspeak--within-slots-p)
			       (indent-line-to newspeak-basic-indent)
			       (indent-line-to 0)) )
   ((newspeak--|-p) (if (not (newspeak--within-block-p))
		      (indent-line-to newspeak-basic-indent)))
   ((newspeak--within-block-p) (let ((column (newspeak--column-token (rx "["))))
				 (if (newspeak--closing-block-p)
				     (indent-line-to column)
				   (indent-line-to (+ column newspeak-basic-indent)))))
   (t (indent-line-to (if (> (car (syntax-ppss)) 1)
			  newspeak-basic-indent
			0)))))

;;; M-x compile

(defcustom headless-executable nil
  "Newspeak user-defined location of the headless interpreter."
  :type 'string)

(defvar newspeak-executable (or headless-executable (executable-find "som")) "The path to a Newspeak executable.  Either supplied by user or found in PATH.")

;;;###autoload
(add-to-list 'auto-mode-alist `(,(rx ".ns" eos) . newspeak-mode))

;;;###autoload
(define-derived-mode newspeak-mode prog-mode "newspeak"
  "Major mode for editing Newspeak files."
  (setq-local font-lock-defaults '(newspeak-font-lock))
  (setq-local font-lock-string-face 'newspeak-font-lock-string-face)
  (setq-local font-lock-comment-face 'newspeak-font-lock-comment-face)
  (setq-local prettify-symbols-alist newspeak-prettify-symbols-alist)
  (setq-local comment-start "(*")
  (setq-local comment-end "*)")
  (setq-local indent-line-function #'newspeak--indent-line)
  (setq-local compile-command (format "%s -G %s" newspeak-executable buffer-file-name))
  (setq open-paren-in-column-0-is-defun-start nil))

(provide 'newspeak-mode)

;;; newspeak-mode.el ends here
