;;; flycheck-aspell.el --- Aspell checker for flycheck -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2021 Leo Gaskin

;; Author: Leo Gaskin <leo.gaskin@le0.gs>
;; Created: 26 May 2019
;; Homepage: https://github.com/leotaku/flycheck-aspell
;; Keywords: wp flycheck spell aspell
;; Package-Commit: 3abe1a6184fefea3e427141131fba40afae3d356
;; Package-Version: 20210618.920
;; Package-X-Original-Version: 0.2.0
;; Package-Requires: ((flycheck "28.0") (emacs "25.1"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This file provides a flymake-based spell-checker for documents
;; using GNU Aspell as a backend.  Please consult the README.md file
;; contained in this directory for further information.

(require 'flycheck)
(require 'pcase)
(require 'rx)
(require 'ispell)
(eval-when-compile
  (require 'cl-lib))

;;; Code:

(defgroup flycheck-aspell nil
  "Aspell checker for flycheck."
  :group 'flycheck
  :prefix "flycheck-aspell-")

(defmacro flycheck-aspell-define-checker (ft ft-doc flags modes)
  "Define a new checker FT with display name FT-DOC valid for MODES.
The Aspell process is additionally passed FLAGS."
  (declare (indent defun))
  (let ((symbol (intern (concat ft "-aspell-dynamic"))))
    `(prog1
         (flycheck-define-checker ,symbol
           ,(format "A spell checker for %s files using aspell." ft-doc)
           :command ("aspell" "pipe" ,@flags "-d"
                     (eval (or ispell-local-dictionary
                               ispell-dictionary
                               "en_US")))
           :error-parser flycheck-aspell--parse
           :modes ,modes)
       (setf (flycheck-checker-get ',symbol 'start)
             #'flycheck-aspell--start-checker))))

(defun flycheck-aspell--start-checker (checker callback)
  (let ((process (flycheck-start-command-checker checker callback)))
    (save-excursion
      ;; enter terse mode for better performance
      (process-send-string process "!\n")
      (dolist (line (split-string (buffer-string) "\n"))
        (process-send-string process (concat "^" line "\n")))
      (process-send-eof process))))

(flycheck-aspell-define-checker "tex"
  "TeX" ("--add-filter" "url" "--add-filter" "tex")
  (plain-tex-mode tex-mode latex-mode context-mode))
(flycheck-aspell-define-checker "markdown"
  "Markdown" ("--add-filter" "url" "--add-filter" "markdown")
  (markdown-mode gfm-mode))
(flycheck-aspell-define-checker "html"
  "HTML" ("--add-filter" "url" "--add-filter" "html")
  (html-mode))
(flycheck-aspell-define-checker "xml"
  "SGML" ("--add-filter" "url" "--add-filter" "sgml")
  (sgml-mode xml-mode))
(flycheck-aspell-define-checker "nroff"
  "Nroff" ("--add-filter" "url" "--add-filter" "nroff")
  (nroff-mode))
(flycheck-aspell-define-checker "texinfo"
  "Texinfo" ("--add-filter" "url" "--add-filter" "texinfo")
  (texinfo-mode))
(flycheck-aspell-define-checker "mail"
  "Mail" ("--add-filter" "url" "--add-filter" "email")
  (message-mode))
(flycheck-aspell-define-checker "c"
  "C" ("--add-filter" "url" "--add-filter" "ccpp")
  (c++mode c-mode rust-mode go-mode))

(defun flycheck-aspell--parse (output checker buffer)
  (let ((final-return nil)
        (errors (flycheck-aspell--process-output output)))
    (pcase-dolist (`(,line-number ,column ,word ,suggestions) errors)
      (push
       (flycheck-error-new-at
        line-number (1+ column)
	    (if (member word ispell-buffer-session-localwords)
		    'info 'error)
        (if (null suggestions)
    	    (concat "Unknown: " word)
          (concat "Suggest: " word " -> " suggestions))
        :checker checker
        :buffer buffer
        :filename (buffer-file-name buffer))
       final-return))
    final-return))

(defun flycheck-aspell--process-output (text)
  (let ((line-number 1)
        (errors '()))
    (dolist (line (split-string text "\n"))
      (if (= 0 (length line))
          (cl-incf line-number)
        (pcase (substring line 0 1)
          ("&" (progn
                 (push (cons line-number (flycheck-aspell--handle-and line)) errors)))
          ("#" (progn
                 (push (cons line-number (flycheck-aspell--handle-hash line)) errors)))
          ("*" nil)
          ("@" nil)
          (_ (error "Unknown beginning of line character in line %s" line)))))
    errors))

(defun flycheck-aspell--handle-hash (line)
  (string-match
   (rx line-start "# "			; start
       (group (+ wordchar)) " "	; error
       (group (+ digit)))		; column
   line)
  (let ((word (match-string 1 line))
	    (column (match-string 2 line)))
    (list (string-to-number column) word nil)))

(defun flycheck-aspell--handle-and (line)
  (string-match
   (rx line-start "& "			; start
       (group (+ wordchar)) " "	; error
       (+ digit) " "			; suggestion count
       (group (+ digit)) ": "	; column
       (group (+? anything)) line-end)
   line)
  (let ((word (match-string 1 line))
	    (column (match-string 2 line))
	    (suggestions (match-string 3 line)))
    (list (string-to-number column) word suggestions)))

(provide 'flycheck-aspell)

;;; flycheck-aspell.el ends here
