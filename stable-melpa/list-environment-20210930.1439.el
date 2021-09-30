;;; list-environment.el --- A tabulated process environment editor  -*- lexical-binding: t; -*-

;; Copyright (C) 2015-2021  Charles L.G. Comstock

;; Author: Charles L.G. Comstock <dgtized@gmail.com>
;; Version: 0.1
;; Package-Version: 20210930.1439
;; Package-Commit: 0a72a5a9c1abc090b25202a0387e3f766994b053
;; Packages-Requires: ((emacs "24.1"))
;; Keywords: processes, unix

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

;; List process environment variables in a readable and tabulated fashion. Edit
;; or clear the environment variable at point, and add new name=value pairs.

;;; Todo:

;; * Command to revert environment variable to value in `initial-environment'
;; * Smarter editing for colon separated values like PATH
;; * Better support for long names or values greater than line length

;;; Code:

(require 'tabulated-list)

(defun list-environment-addenv ()
  "Set a new environment variable."
  (interactive)
  (call-interactively 'setenv)
  (tabulated-list-revert))

(defun list-environment-clear ()
  "Remove current environment variable value."
  (interactive)
  (let ((current-prefix-arg t))
    (list-environment-setenv)))

(defun list-environment-setenv ()
  "Edit the value of current environment variable."
  (interactive)
  (let ((name (tabulated-list-get-id)))
    (minibuffer-with-setup-hook
        (lambda () (insert name))
        (call-interactively 'setenv))
    (tabulated-list-revert)))

(defun list-environment-entries ()
  "Generate environment variable entries list for tabulated-list."
  (mapcar (lambda (env)
            (let* ((kv (split-string env "="))
                   (key (car kv))
                   (val (mapconcat #'identity (cdr kv) "=")))
              (list key (vector key val))))
          process-environment))

(define-derived-mode list-environment-mode
    tabulated-list-mode "Process-Environment"
  "Major mode for listing process environment.
\\{list-environment-mode-map\}"
  (setq tabulated-list-format [("Name" 25 t)
                               ("Value" 50 t)]
        tabulated-list-sort-key (cons "Name" nil)
        tabulated-list-padding 2
        tabulated-list-entries #'list-environment-entries)
  (tabulated-list-init-header))

(define-key list-environment-mode-map (kbd "s") 'list-environment-setenv)
(define-key list-environment-mode-map (kbd "a") 'list-environment-addenv)
(define-key list-environment-mode-map (kbd "d") 'list-environment-clear)

;;;###autoload
(defun list-environment ()
  "List process environment in a tabulated view."
  (interactive)
  (let ((buffer (get-buffer-create "*Process-Environment*")))
    (pop-to-buffer buffer)
    (list-environment-mode)
    (tabulated-list-print)))

(provide 'list-environment)
;;; list-environment.el ends here
