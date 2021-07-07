;;; company-phpactor.el --- company-mode backend for Phpactor -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Friends of Emacs-PHP development

;; Author: Martin Tang <martin.tang365@gmail.com>
;;         Mikael Kermorgant <mikael@kgtech.fi>
;; Created: 18 Apr 2018
;; Version: 0.1.0
;; Package-Version: 20200121.1218
;; Package-Commit: 272217fbb6b7e7f70615fc518d77c6d75f33a44f
;; Keywords: tools, php
;; Package-Requires: ((emacs "24.3") (company "0.9.6") (phpactor "0.1.0"))
;; URL: https://github.com/emacs-php/phpactor.el
;; License: GPL-3.0-or-later

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Company integration for Phpactor.

;;; Code:
(require 'company)
(require 'phpactor)

(defgroup company-phpactor nil
  "Company backend for Phpactor."
  :prefix "company-phpactor-"
  :group 'company
  :group 'phpactor)

(defcustom company-phpactor-request-async t
  "When non-NIL, asynchronous recuest to Phpactor."
  :type 'boolean
  :group 'company-phpactor)

(defun company-phpactor--grab-symbol ()
  "If point is at the end of a symbol, return it.
Otherwise, if point is not inside a symbol, return an empty string.
Here we create a temporary syntax table in order to add $ to symbols."
  (let (($temp-syn-table (make-syntax-table php-mode-syntax-table)))
    (modify-syntax-entry ?\$ "_" $temp-syn-table)

    (with-syntax-table $temp-syn-table
      (if (looking-at "\\_>")
          (buffer-substring (point) (save-excursion (skip-syntax-backward "w_")
                                                    (point)))
        (unless (and (char-after) (memq (char-syntax (char-after)) '(?w ?_)))
          "")))))

(defun company-phpactor--get-suggestions ()
  "Get completions for current cursor."
  (let ((response (phpactor--rpc "complete" (phpactor--command-argments :source :offset))))
    (plist-get (plist-get (plist-get response  :parameters) :value) :suggestions)))

(defun company-phpactor--get-candidates (suggestions)
  "Build a list of candidates with text-properties extracted from phpactor's output `SUGGESTIONS'."
  (let (candidate)
    (mapcar
     (lambda (suggestion)
       (setq candidate (plist-get suggestion :name))
       (put-text-property 0 1 'annotation (plist-get suggestion :short_description) candidate)
       (put-text-property 0 1 'type (plist-get suggestion :type) candidate)
       (if (string= (plist-get suggestion :type) "class")
           (put-text-property 0 1 'class_import (plist-get suggestion :class_import) candidate))
       candidate)
     suggestions)))

(defun company-phpactor--post-completion (arg)
  "Trigger auto-import of completed item ARG when relevant."
  (if (get-text-property 0 'class_import arg)
      (phpactor-import-class (get-text-property 0 'class_import arg)))
  (if (member (get-text-property 0 'type arg) '(list "method" "function"))
      (let ((parens-require-spaces nil)) (insert-parentheses))))

(defun company-phpactor--annotation (arg)
  "Show additional info (ARG) from phpactor as lateral annotation."
  (message (concat " " (get-text-property 0 'annotation arg))))

(defun company-phpactor--get-candidates-async (callback)
  "Get completion candidates asynchronously calling `CALLBACK' by Phpactor."
  (if (not company-phpactor-request-async)
      (funcall callback (company-phpactor--get-candidates (company-phpactor--get-suggestions)))
    (phpactor--rpc-async "complete" (phpactor--command-argments :source :offset)
      (lambda (proc)
        (let* ((response (phpactor--parse-json (process-buffer proc)))
               (suggestions
                (plist-get (plist-get (plist-get response  :parameters) :value) :suggestions)))
          (funcall callback (company-phpactor--get-candidates suggestions)))))))

;;;###autoload
(defun company-phpactor (command &optional arg &rest ignored)
  "`company-mode' completion backend for Phpactor."
  (interactive (list 'interactive))
  (when phpactor-executable
    (save-restriction
      (widen)
      (pcase command
        (`post-completion (company-phpactor--post-completion arg))
        (`annotation (company-phpactor--annotation arg))
        (`interactive (company-begin-backend 'company-phpactor))
        (`prefix (company-phpactor--grab-symbol))
        (`candidates (cons :async #'company-phpactor--get-candidates-async))))))

(provide 'company-phpactor)
;;; company-phpactor.el ends here
