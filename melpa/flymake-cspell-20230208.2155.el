;;; flymake-cspell.el --- A Flymake backend for CSpell -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Fritz Grabo

;; Author: Fritz Grabo <hello@fritzgrabo.com>
;; URL: https://github.com/fritzgrabo/flymake-cspell
;; Package-Version: 20230208.2155
;; Package-Commit: c68bf7eef99ddb2fbd780f175e869df2db5d768f
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

;; A Flymake backend for "CSpell -- A Spell Checker for Code!" by
;; Street Side Software.  See https://cspell.org for documentation and
;; customization options.

;;; Code:

(require 'flymake)
(require 'mode-local)

(eval-when-compile
  (require 'cl-lib))

(defvar flymake-cspell-cspell-command "cspell"
  "Name of the cspell command to execute.")

(defvar flymake-cspell--cspell-version nil
  "Version of cspell found on the system.
Retrieved and cached when flymake-cspell is first set up for a buffer.")

(defvar flymake-cspell--format-diag-string
  "Unknown word: %s. Did you mean %s?"
  "Format string used to display an unknown word and its suggestions.")

(defvar-local flymake-cspell--proc nil
  "The cspell process for the current buffer.")

(defvar-local flymake-cspell--file-excluded nil
  "Whether the current buffer is excluded in cspell.
A non-nil value means that the buffer was found to be excluded by
cspell and that flymake will no longer attempt to spell-check it.
Reset the variable or re-open the buffer's file to retry.")

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

(defun flymake-cspell--check-buffer (report-fn &rest _args)
  "Run cspell for current buffer; REPORT-FN is flymake's callback function."
  (when (process-live-p flymake-cspell--proc)
    (kill-process flymake-cspell--proc))

  (unless flymake-cspell--file-excluded
    (let* ((buffer (current-buffer))
           (resource (if (buffer-file-name) (format "stdin://%s" (buffer-file-name)) "stdin"))
           (language-id (or flymake-cspell--cspell-language-id "auto"))
           (command `(,flymake-cspell-cspell-command "lint" "--no-progress" "--no-color" "--show-suggestions" "--reporter" "default" "--language-id" ,language-id ,resource)))
      (save-restriction
        (widen)
        (setq flymake-cspell--proc
              (make-process
               :name "flymake-cspell-check-buffer"
               :noquery t
               :buffer (generate-new-buffer " *flymake-cspell*") ;; note the leading space
               :command command
               :connection-type 'pipe
               :sentinel
               (lambda (proc _event)
                 (when (eq 'exit (process-status proc))
                   (unwind-protect
                       (if (eq proc flymake-cspell--proc)
                           (let ((results (with-current-buffer (process-buffer proc) (buffer-string))))
                             (if (string-match-p "Files checked: 0" results)
                                 (with-current-buffer buffer
                                   (setq flymake-cspell--file-excluded t))
                               (funcall report-fn (flymake-cspell--build-diags buffer results))))
                         (flymake-log :warning "Canceling obsolete check %s" proc))
                     (kill-buffer (process-buffer proc))))))))
      (process-send-string flymake-cspell--proc (buffer-string))
      (process-send-eof flymake-cspell--proc))))

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

(defun flymake-cspell--cspell-version ()
  "Retrieve (cached) version of `cspell`."
  (or flymake-cspell--cspell-version
      (let* ((command (format "%s --version" flymake-cspell-cspell-command))
             (version (string-trim (shell-command-to-string command))))
        (setq flymake-cspell--cspell-version version))))

;;;###autoload
(defun flymake-cspell-setup ()
  "Enable the spell checker for the current buffer."
  (interactive)

  (unless (executable-find flymake-cspell-cspell-command)
    (error "Cannot find cspell executable"))

  (let ((cspell-required-version "6.21.0")
        (cspell-version (flymake-cspell--cspell-version)))
    (if (version< cspell-version cspell-required-version)
        (error "Flymake-cspell requires cspell version \"%s\" or higher; found \"%s\"" cspell-required-version cspell-version)))

  (unless (memq 'flymake-cspell--check-buffer flymake-diagnostic-functions)
    (make-local-variable 'flymake-diagnostic-functions)
    (push 'flymake-cspell--check-buffer flymake-diagnostic-functions)))

(provide 'flymake-cspell)

;;; flymake-cspell.el ends here
