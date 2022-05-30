;;; flycheck-jest.el --- Flycheck extension for Jest. -*- lexical-binding: t -*-

;; Copyright (C) 2017 James Nguyen

;; Authors: James Nguyen <james@jojojames.com>
;; Maintainer: James Nguyen <james@jojojames.com>
;; URL: https://github.com/jojojames/flycheck-jest
;; Package-Version: 20220530.1418
;; Package-Commit: 8181c5d2e1318c6ddcff21c6f3f6d76413545645
;; Version: 1.0
;; Package-Requires: ((emacs "25.1") (flycheck "0.25"))
;; Keywords: languages jest

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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Flycheck extension for Jest.
;; (with-eval-after-load 'flycheck
;;   (flycheck-jest-setup))

;;; Code:

(require 'flycheck)
(require 'cl-lib)

;; Compatibility
(eval-and-compile
  (with-no-warnings
    (if (version< emacs-version "26")
        (progn
          (defalias 'flycheck-jest-if-let* #'if-let)
          (defalias 'flycheck-jest-when-let* #'when-let)
          (function-put #'flycheck-jest-if-let* 'lisp-indent-function 2)
          (function-put #'flycheck-jest-when-let* 'lisp-indent-function 1))
      (defalias 'flycheck-jest-if-let* #'if-let*)
      (defalias 'flycheck-jest-when-let* #'when-let*))))

;; Customization

(defgroup flycheck-jest nil
  "A `flycheck' extension for jest."
  :group 'programming)

;;; Flycheck
(defvar flycheck-jest-modes '(web-mode js-mode typescript-mode rjsx-mode)
  "A list of modes for use with `flycheck-jest'.")

(flycheck-def-executable-var jest "jest")

(flycheck-def-option-var flycheck-jest-extra-flags nil jest
  "Extra flags appended to arguments of jest."
  :type '(repeat (string :tag "Flags"))
  :safe #'flycheck-string-list-p)

(flycheck-define-checker jest
  "Flycheck plugin for for Jest."
  :command ("jest"
            "--json"
            "--testPathPattern"
            (eval buffer-file-name)
            (eval flycheck-jest-extra-flags))
  :error-parser flycheck-jest--parse
  :modes (web-mode js-mode typescript-mode rjsx-mode)
  :predicate
  (lambda ()
    (funcall #'flycheck-jest--should-use-p))
  :working-directory
  (lambda (checker)
    (flycheck-jest--find-jest-project-directory checker)))

;;;###autoload
(defun flycheck-jest-setup ()
  "Setup Flycheck for Jest."
  (interactive)
  (add-to-list 'flycheck-checkers 'jest)

  (add-hook 'flycheck-before-syntax-check-hook
            #'flycheck-jest--set-flychecker-executable))

(defun flycheck-jest--find-jest-project-directory (&optional _checker)
  "Return directory containing project-related jest files or nil."
  (when buffer-file-name
    (flycheck-jest-when-let*
        ((path (or
                (locate-dominating-file buffer-file-name "node_modules/.bin/jest")
                (locate-dominating-file buffer-file-name "app.json")
                (locate-dominating-file buffer-file-name ".npmrc")
                (locate-dominating-file buffer-file-name ".git")
                (locate-dominating-file buffer-file-name "package.json"))))
      (expand-file-name path))))

(defun flycheck-jest--set-flychecker-executable ()
  "Set `flycheck-jest' executable according to jest location."
  (when (flycheck-jest--should-use-p)
    (setq flycheck-jest-executable
          (format "%snode_modules/.bin/jest"
                  (flycheck-jest--find-jest-project-directory)))))

(defun flycheck-jest--should-use-p ()
  "Return whether or not `flycheck-jest' should run."
  (and buffer-file-name
       (memq major-mode flycheck-jest-modes)
       (string-match-p "test" buffer-file-name)
       (file-exists-p
        (format "%snode_modules/.bin/jest"
                (flycheck-jest--find-jest-project-directory)))))

(defun flycheck-jest--parse (output checker buffer)
  "`flycheck' parser for jest output.

CHECKER is the jest checker.
BUFFER is the buffer being checked."
  (let* ((json-entries (flycheck-parse-json output))
         (jest-results (mapcan (lambda (json-entry)
                                 (flycheck-jest--parse-json json-entry))
                               json-entries)))
    (seq-map (lambda (jest-result)
               (flycheck-error-new-at
                (plist-get jest-result :line)
                (plist-get jest-result :column)
                'error (plist-get jest-result :error)
                :checker checker
                :buffer buffer
                :filename (plist-get jest-result :filename)))
             jest-results)))

(defun flycheck-jest--parse-json (json)
  "Parse JSON and return result.

Result is a list of plists with the form:

'(:line 12
  :column 23
  :error \"This is an error message.\"
  :filename \"absolute-path-to-file\")"
  (when (and (assq 'success json)
             (not (alist-get 'success json)))
    (let ((testResults (alist-get 'testResults json)))
      (car
       (seq-map
        (lambda (testResult)
          (let ((filename (alist-get 'name testResult))
                (message (alist-get 'message testResult)))
            (mapcar
             (lambda (s)
               (cond
                ((string-match-p "at Object." s)
                 (let* ((split (split-string s "at Object." t))
                        (error-message (string-trim (car split)))
                        (linenumbers-str (cadr split))
                        (line (flycheck-jest--extract-line linenumbers-str))
                        (col (flycheck-jest--extract-column linenumbers-str)))
                   `(
                     :line ,line
                     :column ,col
                     :error ,error-message
                     :filename ,filename)))
                ;; FIXME: This is fairly duplicated and it'd be nice to figure
                ;; out how to grab the line and column numbers without resorting
                ;; to explicit pattern patches.
                ((string-match-p "at _callee\\(\[[:digit:]]\\)\\$" s)
                 (let* ((split (split-string
                                s "at _callee\\(\[[:digit:]]\\)\\$" t))
                        (error-message (string-trim (car split)))
                        ;; The cadr of the split will be a stacktrace. We only
                        ;; care about the first line of the stacktrace.
                        (linenumbers-str (car (split-string (cadr split) "\n")))
                        (line (flycheck-jest--extract-line linenumbers-str))
                        (col (flycheck-jest--extract-column linenumbers-str)))
                   `(
                     :line ,line
                     :column ,col
                     :error ,error-message
                     :filename ,filename)))
                (:default nil)))
             (seq-filter (lambda (s)
                           (not (string-blank-p s)))
                         (split-string message "●" t)))))
        testResults)))))

(defun flycheck-jest--extract-line (s)
  "Extract line number from S."
  (let ((split (split-string s ":")))
    (string-to-number (cadr split))))

(defun flycheck-jest--extract-column (s)
  "Extract column number from S."
  (let* ((split (split-string s ":" t))
         (split2 (split-string (car (cddr split)) ")")))
    (string-to-number (car split2))))

(provide 'flycheck-jest)
;;; flycheck-jest.el ends here
