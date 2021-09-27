;;; project-abbrev.el --- Customize abbreviation expansion in the project  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Shen, Jen-Chieh
;; Created date 2018-06-02 10:15:37

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Customize abbreviation expansion in the project.
;; Keyword: abbreviation customizable shortcut
;; Version: 0.0.4
;; Package-Version: 20210715.1213
;; Package-Commit: 4b059ff6ce8cc2ca817247fcc251994bee2090e4
;; Package-Requires: ((emacs "25.1"))
;; URL: https://github.com/jcs-elpa/project-abbrev

;; This file is NOT part of GNU Emacs.

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
;;
;; Customize abbreviation expansion in the project.
;;

;;; Code:

(require 'subr-x)

(defgroup project-abbrev nil
  "Reminder what is the status of each line for current buffer/file."
  :prefix "project-abbrev-"
  :group 'tools
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/project-abbrev"))

(defcustom project-abbrev-config-file "project-abbrev.config"
  "File for your own customizable config file relative to project root directory."
  :group 'project-abbrev
  :type 'string)

;;; Util

(defsubst project-abbrev--config-file-get-string-from-file (file-path)
  "Return FILE-PATH's file content."
  (with-temp-buffer (insert-file-contents file-path) (buffer-string)))

(defsubst project-abbrev--parse-ini (file-path)
  "Parse a .ini file from FILE-PATH."
  (let ((tmp-ini (project-abbrev--config-file-get-string-from-file file-path))
        (tmp-ini-list '()) (tmp-pair-list nil) (tmp-keyword "") (tmp-value "")
        (count 0))
    (setq tmp-ini (split-string tmp-ini "\n"))
    (dolist (tmp-line tmp-ini)
      ;; check not comment.
      (unless (string-match-p "#" tmp-line)
        ;; Split it.
        (setq tmp-pair-list (split-string tmp-line "="))

        ;; Assign to temporary variables.
        (setq tmp-keyword (nth 0 tmp-pair-list))
        (setq tmp-value (nth 1 tmp-pair-list))

        ;; Check empty value.
        (when (and (not (string= tmp-keyword ""))
                   (not (equal tmp-value nil)))
          (let ((tmp-list '()))
            (push tmp-keyword tmp-list)
            (setq tmp-ini-list (append tmp-ini-list tmp-list)))
          (let ((tmp-list '()))
            (push tmp-value tmp-list)
            (setq tmp-ini-list (append tmp-ini-list tmp-list)))))
      (setq count (1+ count)))

    ;; return list.
    tmp-ini-list))

(defsubst project-abbrev--get-properties (ini-list in-key)
  "Get properties data.  Search by key and return value.
INI-LIST : ini list.  Please use this with/after using
`project-abbrev--parse-ini' function.
IN-KEY : key to search for value."
  (let ((tmp-index 0) (tmp-key "") (tmp-value "") (returns-value ""))
    (while (< tmp-index (length ini-list))
      ;; Get the key and data value.
      (setq tmp-key (nth tmp-index ini-list))
      (setq tmp-value (nth (1+ tmp-index) ini-list))
      ;; Find the match.
      (when (string= tmp-key in-key) (setq returns-value tmp-value))
      ;; Search for next key word.
      (setq tmp-index (+ tmp-index 2)))
    ;; Found nothing, return empty string.
    returns-value))

(defun project-abbrev--kill-thing-at-point (thing)
  "Kill the `thing-at-point' for the specified kind of THING."
  (let ((bounds (bounds-of-thing-at-point thing)))
    (if bounds
        (kill-region (car bounds) (cdr bounds))
      (user-error "No %s at point" thing))))

;;; Core

;;;###autoload
(defun project-abbrev-complete-word ()
  "Complete the current word that point currently on."
  (interactive)
  (let ((config-filepath (concat (cdr (project-current)) project-abbrev-config-file))
        (abbrev-list '())
        (current-word (thing-at-point 'word))
        (swap-word ""))
    (setq abbrev-list (project-abbrev--parse-ini config-filepath))
    ;; Get the corresponding target complete word.
    (setq swap-word (project-abbrev--get-properties abbrev-list current-word))
    ;; Swap word cannot be empty string.
    (if (string-empty-p swap-word)
        (user-error "[WARNING] No project abbreviation found")
      (project-abbrev--kill-thing-at-point 'word)
      (insert swap-word))))

(provide 'project-abbrev)
;;; project-abbrev.el ends here
