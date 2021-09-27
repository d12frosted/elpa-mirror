;;; htmltagwrap.el --- Wraps a chunk of HTML code in tags  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Shen, Jen-Chieh
;; Created date 2018-12-04 16:09:31

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Wraps a chunk of HTML code in tags.
;; Keyword: keybindings
;; Version: 0.0.3
;; Package-Version: 20200929.559
;; Package-Commit: ec85e68a4cba064d4caa593e1dec69b1b35b12dd
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/jcs-elpa/htmltagwrap

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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Wraps a chunk of HTML code in tags.
;;

;;; Code:

(defgroup htmltagwrap nil
  "Wraps a chunk of HTML code in tags."
  :prefix "htmltagwrap-"
  :group 'editing
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/htmltagwrap"))

(defcustom htmltagwrap-tag "p"
  "The default HTML tag to insert."
  :group 'htmltagwrap
  :type 'string)

(defcustom htmltagwrap-indie-tag-wrap-not-inline t
  "Make newline when wrap if the region is not on the same line."
  :group 'htmltagwrap
  :type 'boolean)

(defcustom htmltagwrap-indent-region-after-wrap t
  "Indent region after do html tag wrap."
  :group 'htmltagwrap
  :type 'boolean)

(defun htmltagwrap-safe-do-tag-wrap ()
  "Check if able to do tag wrap."
  ;; NOTE(jenchieh): Rules design here..
  (and (use-region-p)))

(defun htmltagwrap-insert-open-tag (&optional nl)
  "Insert the opening tag.
NL : make new line when insert?"
  (let ((empty-line (not (htmltagwrap-current-line-empty-p))))
    (insert (concat "<" htmltagwrap-tag ">"))
    (when (and nl
               htmltagwrap-indie-tag-wrap-not-inline
               empty-line)
      (save-excursion
        (newline-and-indent)))))

(defun htmltagwrap-insert-close-tag (&optional nl)
  "Insert the closing tag.
NL : make new line when insert?"
  (when (and nl
             htmltagwrap-indie-tag-wrap-not-inline
             (not (htmltagwrap-current-line-empty-p)))
    (newline-and-indent))
  (when htmltagwrap-indent-region-after-wrap
    (call-interactively #'indent-for-tab-command))
  (insert (concat "</" htmltagwrap-tag ">")))

(defun htmltagwrap-get-line-interger ()
  "Get the current line as integer."
  (string-to-number (format-mode-line "%l")))

(defun htmltagwrap-get-line-at-point (pt)
  "Get the line number at PT."
  (save-excursion
    (goto-char pt)
    (htmltagwrap-get-line-interger)))

(defun htmltagwrap-current-line-empty-p ()
  "Current line empty, but accept spaces/tabs in there."
  (save-excursion
    (beginning-of-line)
    (looking-at "[[:space:]\t]*$")))

;;;###autoload
(defun htmltagwrap-tag-wrap ()
  "Wraps a chunk of HTML code in tags."
  (interactive)
  (when (htmltagwrap-safe-do-tag-wrap)
    (let ((re (region-end)) (rb (region-beginning)) same-line)
      ;; Check same line.
      (when (= (htmltagwrap-get-line-at-point re) (htmltagwrap-get-line-at-point rb))
        (setq same-line t))

      ;; Insert closing tag.
      (goto-char re)
      (htmltagwrap-insert-close-tag (not same-line))

      ;; Insert opening tag.
      (goto-char rb)
      (htmltagwrap-insert-open-tag (not same-line))

      ;; Back to opening tag position.
      (backward-char 1)

      ;; Do indent region?
      (when htmltagwrap-indent-region-after-wrap
        (indent-region rb re)))))

(provide 'htmltagwrap)
;;; htmltagwrap.el ends here
