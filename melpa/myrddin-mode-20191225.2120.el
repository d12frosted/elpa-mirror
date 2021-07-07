;;; myrddin-mode.el --- Major mode for editing Myrddin source files -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Jakob L. Kreuze

;; Author: Jakob L. Kreuze <zerodaysfordays@sdf.lonestar.org>
;; Version: 0.1
;; Package-Version: 20191225.2120
;; Package-Commit: 51c0a2cb9dfc9526cd47e71313f5a745c99cadcc
;; Package-Requires: ((emacs "24.3"))
;; Keywords: languages
;; URL: https://git.sr.ht/~jakob/myrddin-mode

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; myrddin-mode provides support for editing Myrddin, including automatic
;; indentation and syntactical font-locking.

;;; Code:

(require 'rx)

(defgroup myrddin nil
  "Support for Myrddin code."
  :link '(url-link "https://git.sr.ht/~jakob/myrddin-mode")
  :group 'languages)

(defcustom myrddin-indent-offset 4
  "Indent Myrddin code by this number of spaces."
  :type 'integer
  :group 'myrddin
  :safe #'integerp)


;;;
;;; Syntax tables.
;;;

(defvar myrddin-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; Operators.
    (dolist (i '(?+ ?- ?* ?/ ?% ?& ?| ?^ ?! ?< ?> ?~ ?@))
      (modify-syntax-entry i "." table))

    ;; Strings.
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?\\ "\\" table)

    ;; Angle brackets.
    (modify-syntax-entry ?< "(>" table)
    (modify-syntax-entry ?> ")<" table)

    ;; Comments.
    (modify-syntax-entry ?/  ". 124b" table)
    (modify-syntax-entry ?*  ". 23n"  table)
    (modify-syntax-entry ?\n "> b"    table)
    (modify-syntax-entry ?\^m "> b"   table)

    table))


;;;
;;; Font locking.
;;;

(defconst myrddin-mode-keywords
  '("$noret"
    "break"
    "const" "continue"
    "elif" "else" "extern"
    "for"
    "generic" "goto"
    "if" "impl" "in"
    "match"
    "pkg" "pkglocal"
    "sizeof" "struct"
    "trait" "type"
    "union"
    "use"
    "var"
    "while"))

(defconst myrddin-mode-constants
  '("true" "false" "void"))

(defvar myrddin-mode-block-keywords
  '("elif" "else" "for" "if" "match" "struct" "trait" "while"))

(defconst myrddin-mode-identifier-rx
  '(and (or alpha ?_)
        (zero-or-more (or alnum ?_))))

(defconst myrddin-mode-type-name-rx
  '(and
    (eval myrddin-mode-identifier-rx)
    (optional (or (and ?[ (zero-or-more any) ?])
                  ?#))))

(defconst myrddin-mode-variable-declaration-regexp
  (rx
   (and (or "const" "var" "generic")
        (zero-or-more (or "extern" "pkglocal" "#noret"))
        (and (one-or-more whitespace)
             (group
              symbol-start
              (or alpha ?_)
              (one-or-more (or alnum ?_))
              symbol-end)))))

(defvar myrddin-mode-type-specification-regexp
  (rx
   (and (or (and "->"
                 (zero-or-more whitespace))
            (and (eval myrddin-mode-identifier-rx)
                 (zero-or-more whitespace)
                 ?:
                 (zero-or-more whitespace)))
        (group
         symbol-start
         (eval myrddin-mode-type-name-rx)
         symbol-end))))

(defvar myrddin-mode-label-regexp
  (rx (and ?: (or alpha ?_) (one-or-more (or alnum ?_)) symbol-end)))

(defvar myrddin-mode-font-lock-keywords
  `((,(regexp-opt myrddin-mode-keywords 'symbols) . font-lock-keyword-face)
    (,(regexp-opt myrddin-mode-constants 'symbols) . font-lock-constant-face)
    (,myrddin-mode-label-regexp . font-lock-constant-face)
    (,(rx (or ?{ "const" "var" "generic")) ,myrddin-mode-type-specification-regexp
     nil nil (1 font-lock-type-face))
    (,myrddin-mode-variable-declaration-regexp 1 font-lock-variable-name-face)))


;;;
;;; Indentation.
;;;

(defun myrddin-mode--preceding-nonempty-line ()
  "Return the text of and the indentation level of the closest
preceding line that does not consist entirely of whitespace, or
NIL if there is no preceding line."
  (unless (bobp)
    (save-excursion
      (let (last-line)
        (while (not (and last-line (plusp (length (string-trim last-line)))))
          (previous-line)
          (back-to-indentation)
          (setf last-line (buffer-substring-no-properties
                           (line-beginning-position)
                           (line-end-position))))
        (values last-line (/ (current-column) myrddin-indent-offset))))))


(defun myrddin-mode--nearest-match-level ()
  (save-excursion
    (while (not (or (bobp) (looking-at "match")))
      (previous-line)
      (back-to-indentation))
    (/ (current-column) myrddin-indent-offset)))

(defun myrddin-mode--calculate-indent (prev-line prev-level)
  (save-excursion
    (back-to-indentation)
    (cond
     ;; Handle match arms by finding the indentation of the nearest match
     ;; statement.
     ((looking-at (rx ?|))
      (* myrddin-indent-offset (myrddin-mode--nearest-match-level)))
     ;; Deindent any lines beginning with a syntactic element for closing a
     ;; block, unless it occurs immediately following the beginning of a block.
     ((looking-at (rx (or "}" ";;" "elif" "else")))
      (if (string-match-p
           (rx (eval (cons 'or (cons "{" myrddin-mode-block-keywords))))
           prev-line)
          (* myrddin-indent-offset prev-level)
        (max 0 (* myrddin-indent-offset (1- prev-level)))))
     ;; Indent any lines immediately following a line containing a syntactic
     ;; element for opening a block.
     ((string-match-p
       (rx (eval (cons 'or (append '("|" "{") myrddin-mode-block-keywords))))
       prev-line)
      (* myrddin-indent-offset (1+ prev-level)))
     (t (* myrddin-indent-offset prev-level)))))

(defun myrddin-mode-indent-line ()
  "Indent current line for Myrddin mode.
Return the amount the indentation changed by."
  (interactive)
  (let ((prev-line (myrddin-mode--preceding-nonempty-line)))
    (if prev-line
        (cl-destructuring-bind (prev-line prev-level) prev-line
            (let ((indent (myrddin-mode--calculate-indent prev-line prev-level)))
              (when indent
                (if (<= (current-column) (current-indentation))
                    (indent-line-to indent)
                  (save-excursion (indent-line-to indent))))))
      ;; The first line in the file should begin on column 0.
      (indent-line-to 0))))


;;;
;;; Mode declaration.
;;;

;;;###autoload
(define-derived-mode myrddin-mode prog-mode "Myrdin"
  "Major mode for Myrddin code."
  :group 'myrddin
  :syntax-table myrddin-mode-syntax-table
  (setq-local font-lock-defaults '(myrddin-mode-font-lock-keywords
                                   nil nil nil nil))
  (setq-local indent-line-function 'myrddin-mode-indent-line)
  (setq comment-start "/*")
  (setq comment-end "*/"))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.myr\\'" . myrddin-mode))

(provide 'myrddin-mode)
;;; myrddin-mode.el ends here
