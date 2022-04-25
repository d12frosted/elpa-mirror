;;; flymake-rakudo.el --- Flymake syntax checker for Rakudo -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Siavash Askari Nasr

;; Author: Siavash Askari Nasr <ciavash@proton.me>
;; URL: https://github.com/Raku/flymake-rakudo
;; Package-Version: 20220424.637
;; Package-Commit: f8e3d03a7207876cd891174702efd572d74f2e49
;; Keywords: language, tools, convenience
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1") (flymake-collection "2.0.0") (let-alist "1.0"))

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
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

;; Raku syntax checking support for Flymake.

;;; Code:

(require 'flymake)
(require 'flymake-collection)
(require 'project)

(eval-when-compile (require 'flymake-collection-define))

(defgroup flymake-rakudo nil
  "Rakudo (Raku implementation) support for Flymake."
  :prefix "flymake-rakudo-"
  :group 'flymake
  :link '(url-link :tag "Github" "https://github.com/Raku/flymake-rakudo"))

(defcustom flymake-rakudo-include-path nil
  "A list of include directories for Raku.

The value of this variable is a list of strings, where each
string is a directory to add to the include path of Raku.
Relative paths are relative to the file being checked."
  :type '(repeat (directory :tag "Include directory")))

(defun flymake-rakudo--find-elements-with-line (alist)
  "Return elements of ALIST which contain .line."
  (cl-loop for element in alist
           if (nested-alist-p element)
           if (assq 'line element) return (list element)
           else append (flymake-rakudo--find-elements-with-line element)))

(defun flymake-rakudo--parse-panic (panic)
  "Parse PANIC field from JSON."
  (if (string-match "\\`\\(Undeclared \\(?:routine\\|name\\)\\)s?:" panic)
      (let ((error-type (match-string 1 panic)) errs)
        (while (string-match "\s*\\(.+?\\) at lines? \\([^\n]+\n\\)" panic (match-end 0))
          (let ((msg (concat error-type " " (match-string 1 panic)))
                (rest-of-line (match-string 2 panic))
                (rest-start-pos 0)
                line-numbers)
            (save-match-data
              (while (string-match "\\([[:digit:]]+\\)\\(?:, \\)?" rest-of-line rest-start-pos)
                (setq rest-start-pos (match-end 0))
                (push (string-to-number (match-string 1 rest-of-line))
                      line-numbers))
              (string-match "\\([^\n]*\\)\n" rest-of-line (match-end 0))
              (mapc
               (lambda (line-number)
                 (push
                  `(panic . ((line . ,line-number) (message . ,(concat msg (match-string 1 rest-of-line)))))
                  errs))
               line-numbers))))
        errs)))

;;;###autoload (autoload 'flymake-rakudo "flymake-rakudo")
(flymake-collection-define-enumerate flymake-rakudo
  "A Raku syntax checker."
  :title "Rakudo"
  :pre-let ((rakudo-exec (executable-find "rakudo"))
            (_env-var (progn
                        (make-local-variable 'process-environment)
                        (setenv "RAKU_EXCEPTIONS_HANDLER" "JSON"))))
  :pre-check (unless rakudo-exec
               (error "Cannot find rakudo executable"))
  :write-type 'pipe
  :command `(,rakudo-exec
             "-c"
             ,@(let ((include-paths flymake-rakudo-include-path))
                 ;; Add project root to path
                 (let ((current-project (project-current)))
                   (if current-project
                       (push (expand-file-name (project-root current-project))
                             include-paths)))
                 (cl-loop for path in include-paths
                          collect (concat "-I" path))))
  :generator
  (let ((json-alist
         (flymake-collection-parse-json
          (buffer-substring-no-properties
           (point-min) (point-max)))))
    (let ((errors (flymake-rakudo--find-elements-with-line json-alist)))
      (let-alist (cdaar json-alist)
        (when .panic
          (setq errors (append errors (flymake-rakudo--parse-panic .panic)))))
      errors))
  :enumerate-parser
  (let-alist it
    (let (column expected)
      (if .pos
          (with-current-buffer flymake-collection-source
            (setq column (save-excursion (goto-char .pos) (current-column)))))
      (if .highexpect
          (let ((padded_expect (mapconcat (lambda (str) (concat "    " str)) .highexpect "\n")))
            (setq expected (concat "\nexpecting any of:\n" padded_expect))))
      (let ((loc (flymake-diag-region flymake-collection-source .line column))
            (message (concat
                      (propertize (symbol-name (car it)) 'face 'flymake-collection-diag-id)
                      "\n"
                      .message
                      expected)))
        (list flymake-collection-source (car loc) (cdr loc) :error message)))))

;;;###autoload
(defun flymake-rakudo-setup ()
  "Add `flymake-rakudo' to `flymake-diagnostic-functions'."
  (interactive)
  (add-hook 'flymake-diagnostic-functions #'flymake-rakudo nil t))

(provide 'flymake-rakudo)

;;; flymake-rakudo.el ends here
