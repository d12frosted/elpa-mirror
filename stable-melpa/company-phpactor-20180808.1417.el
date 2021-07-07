;;; company-phpactor.el --- company-mode backend for Phpactor -*- lexical-binding t; -*-

;; Copyright (C) 2018  Friends of Emacs-PHP development

;; Author: Martin Tang <martin.tang365@gmail.com>
;; Created: 18 Apr 2018
;; Version: 0.1.0
;; Package-Version: 20180808.1417
;; Package-Commit: 61e4eab638168b7034eef0f11e35a89223fa7687
;; Keywords: tools, php
;; Package-Requires: ((emacs "24.3") (cl-lib "0.5") (company "0.9.6"))
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

(defun company-phpactor--get-candidates ()
  "Build a list of candidates with text-properties extracted from phpactor's output."
  (let ((suggestions (company-phpactor--get-suggestions)) candidate)
    (mapcar
     (lambda (suggestion)
       (setq candidate (plist-get suggestion :name))
       (put-text-property 0 1 'annotation (plist-get suggestion :info) candidate)
       (put-text-property 0 1 'type (plist-get suggestion :type) candidate)
       candidate)
     suggestions)))

(defun company-phpactor--post-completion (arg)
  "Trigger auto-import of completed item ARG when relevant."
  (if (string= (get-text-property 0 'type arg) "t")
      (phpactor-import-class (get-text-property 0 'annotation arg))))

(defun company-phpactor--annotation (arg)
  "Show additional info (ARG) from phpactor as lateral annotation."
  (message (concat " " (get-text-property 0 'annotation arg))))

;;;###autoload
(defun company-phpactor (command &optional arg &rest ignored)
  "`company-mode' completion backend for Phpactor."
  (interactive (list 'interactive))
  (save-restriction
    (widen)
    (cl-case command
      (post-completion (company-phpactor--post-completion arg))
      (annotation (company-phpactor--annotation arg))
      (interactive (company-begin-backend 'company-phpactor))
      (prefix (company-phpactor--grab-symbol))
      (candidates (all-completions arg (company-phpactor--get-candidates))))))

(provide 'company-phpactor)
;;; company-phpactor.el ends here
