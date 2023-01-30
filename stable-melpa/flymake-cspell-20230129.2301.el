;;; flymake-cspell.el --- A Flymake backend for CSpell -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Fritz Grabo

;; Author: Fritz Grabo <hello@fritzgrabo.com>
;; URL: https://github.com/fritzgrabo/flymake-cspell
;; Package-Version: 20230129.2301
;; Package-Commit: b0bcd0c0394e31598bc3f3bce8719471d6bf478b
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))
;; Keywords: wp

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; A Flymake backend for CSpell -- A Spell Checker for Code!

;;; Code:

(require 'flymake)
(require 'mode-local)

(eval-when-compile
  (require 'cl-lib))

(defvar flymake-cspell--format-diag-string
  "Unknown word: %s. Did you mean %s?"
  "Used to format an unknown word and its suggestions for display.")

(defvar-local flymake-cspell--cspell-language-id nil
  "Cspell language id to use for the current buffer.")

(defmacro flymake-cspell-set-language-ids (&rest defs)
  "Apply cspell language-id to major mode associations in DEFS."
  `(progn
     ,@(mapcan
        (lambda (def)
          (mapcar
           (lambda (mode)
             `(setq-mode-local ,mode flymake-cspell--cspell-language-id ,(car def)))
           (cdr def)))
        defs)))

(flymake-cspell-set-language-ids
 ("c" c-mode c-ts-mode)
 ("commit-msg" git-commit-mode git-commit-elisp-text-mode) ;; external
 ("cpp" c++-mode c++-ts-mode)
 ("css" css-mode css-ts-mode)
 ("dockerfile" dockerfile-mode) ;; external
 ("go" go-mode go-ts-mode)
 ("html" html-mode)
 ("java" java-mode java-ts-mode)
 ("javascript" js-mode js-ts-mode js-jsx-mode)
 ("json" js-json-mode json-ts-mode)
 ("latex" latex-mode)
 ("less" less-css-mode)
 ("markdown" markdown-mode)
 ("python" python-mode)
 ("ruby" ruby-mode)
 ("scss" scss-mode)
 ("shellscript" sh-mode)
 ("sql" sql-mode)
 ("typescript" typescript-ts-mode tsx-ts-mode)
 ("yaml" yaml-mode yaml-ts-mode))

(defvar-local flymake-cspell--proc nil
  "A buffer-local variable handling the cspell process for flymake.")

(defvar-local flymake-cspell--file-excluded 'unchecked
  "Whether the current buffer is excluded in cspell.

A value of `'unchecked' means that the check for exclusion has
not run yet for the buffer.  A nil value means that the buffer
should be checked.  Any other value means that the buffer is
excluded in cspell.")

(defun flymake-cspell--check (report-fn &rest _args)
  "Run cspell for current buffer; REPORT-FN is flymake's callback function."
  (when (process-live-p flymake-cspell--proc)
    (kill-process flymake-cspell--proc))

  (let ((checked-buffer (current-buffer)))
    (unless (buffer-file-name)
      (setq flymake-cspell--file-excluded nil))
    (if (eq flymake-cspell--file-excluded 'unchecked)
        (flymake-cspell--run-for-file
         (buffer-file-name)
         (lambda (results)
           (if (string-match-p "Files checked: 0" results)
               (setq flymake-cspell--file-excluded t)
             (setq flymake-cspell--file-excluded nil)
             (funcall report-fn (flymake-cspell--build-diags checked-buffer results)))))
      (if (null flymake-cspell--file-excluded)
          (flymake-cspell--run-for-buffer
           checked-buffer
           (lambda (results)
             (funcall report-fn (flymake-cspell--build-diags checked-buffer results))))))))

(defun flymake-cspell--run-for-file (file-name fn)
  "Run cspell for FILE-NAME and pass its output into FN."
  (setq flymake-cspell--proc (flymake-cspell--run file-name fn)))

(defun flymake-cspell--run-for-buffer (buffer fn)
  "Run cspell for the contents of BUFFER and pass its output into FN."
  (with-current-buffer buffer
    (save-restriction
      (widen)
      (setq flymake-cspell--proc (flymake-cspell--run "stdin" fn))
      (process-send-string flymake-cspell--proc (buffer-string))
      (process-send-eof flymake-cspell--proc))))

(defun flymake-cspell--run (input fn)
  "Run cspell for INPUT (file name or \"stdin\") and pass its output into FN."
  (make-process
   :name "flymake-cspell-check-buffer"
   :noquery t
   :buffer (generate-new-buffer " *flymake-cspell*")
   :command `("cspell" "lint" "--no-progress" "--no-color" "--show-suggestions" "--language-id" ,(or flymake-cspell--cspell-language-id "auto") ,input)
   :connection-type 'pipe
   :sentinel
   (lambda (proc _event)
     (when (eq 'exit (process-status proc))
       (unwind-protect
           (if (eq proc flymake-cspell--proc)
               (let ((results (with-current-buffer (process-buffer proc) (buffer-string))))
                 (funcall fn results))
             (flymake-log :warning "Canceling obsolete check %s" proc))
         (kill-buffer (process-buffer proc)))))))

(defun flymake-cspell--build-diags (buffer results)
  "Build a list of flymake diagnostics in BUFFER from cspell output in RESULTS."
  (let ((errors (flymake-cspell--extract-errors results)))
    (with-current-buffer buffer
      (save-excursion
        (cl-loop
         for (line column word suggestions) in errors
         for (beg . end) = (flymake-cspell--find-diag-boundaries line column word)
         collect (flymake-make-diagnostic buffer beg end :warning (flymake-cspell--format-diag word suggestions)))))))

(defun flymake-cspell--find-diag-boundaries (line column word)
  "Find beginning and end of WORD at LINE, COLUMN in current buffer."
  (condition-case nil
      (progn
        (goto-char (point-min))
        (forward-line (1- line))
        (let ((pos (+ (point) (1- column))))
          (cons pos (+ pos (length word)))))
    (error (cons 0 0))))

(defun flymake-cspell--format-diag (word suggestions)
  "Format an unknown WORD and its SUGGESTIONS for display."
  (format
   flymake-cspell--format-diag-string
   word
   (or (and (> (length suggestions) 1) suggestions) "no suggestions")))

(defun flymake-cspell--extract-errors (results)
  "Extract errors from cspell output in RESULTS."
  (let (errors)
    (dolist (line (split-string results "\n"))
      (when (string-match "^.*:\\([[:digit:]]+\\):\\([[:digit:]]+\\) - Unknown word (\\([^)]+\\))\\( Suggestions: \\[\\([^]]*\\)\\]\\)?$" line)
        (push (list
               (string-to-number (match-string 1 line)) ;; line
               (string-to-number (match-string 2 line)) ;; column
               (match-string 3 line) ;; word
               (match-string 5 line)) ;; suggestion(s)
              errors)))
    (nreverse errors)))

;;;###autoload
(defun flymake-cspell-setup ()
  "Enable the spell checker for the current buffer."
  (interactive)

  (unless (executable-find "cspell")
    (error "Cannot find cspell executable"))

  (unless (memq 'flymake-cspell--check flymake-diagnostic-functions)
    (make-local-variable 'flymake-diagnostic-functions)
    (push 'flymake-cspell--check flymake-diagnostic-functions)))

(provide 'flymake-cspell)

;;; flymake-cspell.el ends here
