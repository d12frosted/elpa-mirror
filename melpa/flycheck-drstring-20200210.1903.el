;;; flycheck-drstring.el --- Doc linting for Swift using DrString -*- lexical-binding: t -*-

;; Copyright (C) 2020 Daniel Martín <mardani29@yahoo.es>

;; Author: Daniel Martín <mardani29@yahoo.es>
;; URL: https://github.com/danielmartin/flycheck-drstring
;; Package-Version: 20200210.1903
;; Package-Commit: d8d5a560e792a6657ef5ac69934c74f1ed51372d
;; Created: 1 February 2020
;; Version: 0.1
;; Package-Requires: ((emacs "25.1") (flycheck "0.25") (swift-mode "8.0"))
;; Keywords: tools flycheck

;;; License:

;; This file is not part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package adds support for linting documentation in Swift files
;; using DrString (https://github.com/dduan/DrString/).  To configure
;; this package, add the following line to your initialization file:

;; (flycheck-drstring-setup)

;; DrString is a CLI tool that can be installed using your favorite
;; package manager.  For example, if you use Homebrew:

;; $ brew install dduan/formulae/drstring

;;; Code:

(require 'flycheck)
(require 'swift-mode)

(defun flycheck-drstring--font-lock-error-explanation (explanation)
  "Apply Swift font lock on the Swift code in EXPLANATION."
  (with-temp-buffer
    (insert explanation)
    (cond ((not (boundp 'swift-mode))
           ;; Do not fontify if `swift-mode' is unavailable.
           (buffer-string))
          (t (delay-mode-hooks (swift-mode))
             (goto-char (point-min))
             ;; "Bad example" and "Good example" delimit the areas of Swift
             ;; sample code that we want to fontify.
             (let ((bad-example-beginning
                    (re-search-forward "Bad example:\n------------------------------------"
                                       nil t))
                   (bad-example-end
                    (re-search-forward "------------------------------------"
                                       nil t))
                   (good-example-beginning
                    (re-search-forward "Good example:\n------------------------------------"
                                       nil t))
                   (good-example-end
                    (re-search-forward "------------------------------------"
                                       nil t)))
               (when (and bad-example-beginning
                          bad-example-end
                          good-example-beginning
                          good-example-end)
                 (with-no-warnings
                   (font-lock-fontify-region bad-example-beginning bad-example-end)
                   (font-lock-fontify-region good-example-beginning good-example-end)))
               (buffer-string))))))

(defun flycheck-drstring--insert-error-explanation (error-id)
  "Insert an explanation for DrString's ERROR-ID in `flycheck-explain-error-buffer'."
  (with-current-buffer flycheck-explain-error-buffer
    (let ((explanation
           (shell-command-to-string
            (format "drstring explain %s" (shell-quote-argument error-id))))
          (inhibit-read-only t)
          (inhibit-modification-hooks t))
      (erase-buffer)
      (insert (flycheck-drstring--font-lock-error-explanation explanation)))))

(defun flycheck-drstring-error-explainer (error)
  "Explain a DrString ERROR."
  (when-let ((error-id (flycheck-error-id error))
             (loading-msg "Loading..."))
    ;; We need to load the explanation in the next event loop
    ;; because otherwise `flycheck' will delete our font-lock
    ;; text properties when creating the Help buffer.
    (run-at-time 0 nil #'flycheck-drstring--insert-error-explanation error-id)
    loading-msg))

(defun flycheck-drstring-parse-errors (output checker buffer)
  "Parse errors from OUTPUT, given a Flycheck CHECKER, and a BUFFER.
This function returns a list of `flycheck-error' structures or
nil if no error could be parsed."
  (with-temp-buffer
    (let ((current-file)                ; File that contains the error that is being parsed.
          (current-line)                ; Line number where the current error is.
          (current-column)              ; Column number where the current error is.
          (errors)                      ; List of `flycheck-error' parsed so far.
          ;; Note that DrString only outputs warnings.
          (error-header
           (flycheck-rx-to-string
            '(: (file-name) ":" line ":" column ": warning:" (one-or-more nonl) "\n")))
          (error-description
           (flycheck-rx-to-string
            '(: "|" (group-n 1 (one-or-more nonl)) "|" " " (group-n 2 (one-or-more nonl)) "\n"))))
      (insert output)
      (goto-char (point-min))
      (while (not (eobp))
        (cond ((looking-at error-header)
               (let ((filename (match-string 1))
                     (line (match-string 2))
                     (column (match-string 3)))
                 (setq current-file filename)
                 (setq current-line line)
                 (setq current-column column)
                 (forward-line)))
              ((looking-at error-description)
               (let ((error-id (match-string 1))
                     (message (match-string 2)))
                 (push (flycheck-error-new-at
                        (flycheck-string-to-number-safe current-line)
                        (flycheck-string-to-number-safe current-column)
                        'warning
                        (unless (string-empty-p message) message)
                        :id (unless (string-empty-p error-id) error-id)
                        :checker checker
                        :buffer buffer
                        :filename (if (or (null current-file) (string-empty-p current-file))
                                      (buffer-file-name)
                                    current-file))
                       errors)
                 (forward-line)))
              (t (forward-line))))
      (nreverse errors))))

(flycheck-define-checker drstring
  "A documentation linter for Swift files."
  :command ("drstring"
            "check"
            "-i"
            source)
  :error-parser flycheck-drstring-parse-errors
  :error-explainer flycheck-drstring-error-explainer
  :modes swift-mode)

;;;###autoload
(defun flycheck-drstring-setup ()
  "Convenience function to set up Flycheck support for DrString."
  (add-to-list 'flycheck-checkers 'drstring))

(provide 'flycheck-drstring)
;;; flycheck-drstring.el ends here
