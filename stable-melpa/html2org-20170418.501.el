;;; html2org.el --- Convert html to org format text   -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2018 DarkSun

;; Author: DarkSun <lujun9972@gmail.com>
;; URL: http://github.com/lujun9972/html2org.el
;; Created: 2017-4-10
;; Package-Version: 20170412.0
;; Version: 0.1
;; Keywords: convenience, html, org
;; Package-Requires: ((emacs "24.4"))

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

;;; Source code
;;
;; html2org's code can be found here:
;;   http://github.com/lujun9972/html2org.el


;;; Commentary:
;; 

;;; Code:

(require 'dom)
(require 'shr)
(require 'subr-x)
(require 'org)

(defun html2org-tag-a (dom)
  "Convert DOM into ‘org-mode’ style link."
  (let ((url (dom-attr dom 'href))
        ;; (title (dom-attr dom 'title))
        (text (dom-texts dom))
        (start (point)))
    (when (and shr-target-id
               (equal (dom-attr dom 'name) shr-target-id))
      ;; We have a zero-length <a name="foo"> element, so just
      ;; insert...  something.
      (when (= start (point))
        (shr-ensure-newline)
        (shr-insert " "))
      (put-text-property start (1+ start) 'shr-target-id shr-target-id))
    (if (string-empty-p (string-trim text))
        (shr-insert (format "[[%s]]" url))
      (shr-insert (format "[[%s][" url))
      (shr-generic dom)
      (shr-insert "]]"))))

(defun html2org-tag-table (dom)
  "Convert DOM into org-mde style table."
  (let ((start (point)))
    (shr-tag-table dom)
    (org-table-convert-region start (point))
    (goto-char (point-max))))

(defun html2org-fontize-dom (dom type)
  "Fontize the text of DOM in TYPE."
  (unless (or (looking-back "[[:blank:]*/_]")
              (save-excursion
                (= (point) (progn (beginning-of-line)
                                  (point)))))
    (shr-insert " "))
  (shr-insert type)
  (shr-generic dom)
  (shr-insert type)
  (unless (looking-at-p "[[:blank:]]")
    (shr-insert " ")))

(defun html2org-tag-b (dom)
  "Convert DOM into org style bold text."
  (html2org-fontize-dom dom "*"))

(defun html2org-tag-i (dom)
  "Convert DOM into org style italic text."
  (html2org-fontize-dom dom "/"))

(defun html2org-tag-em (dom)
  "Convert DOM into org style italic text."
  (html2org-fontize-dom dom "/"))

(defun html2org-tag-strong (dom)
  "Convert DOM into org style bold text."
  (html2org-fontize-dom dom "*"))

(defun html2org-tag-u (dom)
  "Convert DOM into org style underline text."
  (html2org-fontize-dom dom "_"))

(defun html2org-transform-dom (dom)
  "Transform DOM into org format text."
  (let ((shr-external-rendering-functions '((a . html2org-tag-a)
                                            (b . html2org-tag-b)
                                            (i . html2org-tag-i)
                                            (em . html2org-tag-em)
                                            (strong . html2org-tag-strong)
                                            (u . html2org-tag-u)
                                            (table . html2org-tag-table))))
    (with-temp-buffer
      (shr-insert-document dom)
      (replace-regexp-in-string "^\\(\\*[[:blank:]]+\\)" ",\\1" (buffer-string)))))

(defun html2org--shr (start end)
  (let ((dom (libxml-parse-html-region start end)))
    (html2org-transform-dom dom)))

(defun html2org--pandoc (start end)
  (let ((orign-buffer (current-buffer)))
    (with-temp-buffer
      (let ((output-buf (current-buffer)))
        (with-current-buffer orign-buffer
          (shell-command-on-region start end "pandoc -f html -t org" output-buf)))
      (buffer-substring-no-properties (point-min) (point-max)))))

;;;###autoload
(defun html2org (&optional buf start end replace)
  "Convert HTML to org text in the BUF between START and END.

If REPLACE is nil, it just return the converted org content
 without change the buffer;
Otherwise, it replace the orgin content with converted org content.
When called interactively, it means do the replacement."
  (interactive)
  (let ((buf (or buf (current-buffer)))
        (shr-external-rendering-functions '((a . html2org-tag-a)))
        (replace (if (called-interactively-p 'any)
                     t
                   replace)))
    (with-current-buffer buf
      (let* ((start (or start (if (use-region-p)
                                  (region-beginning)
                                (point-min))))
             (end (or end (if (use-region-p)
                              (region-end)
                            (point-max))))
             (org-content (if (executable-find "pandoc")
                              (html2org--pandoc start end)
                            (html2org--shr start end))))
        (if replace
            (setf (buffer-substring start end) org-content)
          org-content)))))


(provide 'html2org)

;;; html2org.el ends here
