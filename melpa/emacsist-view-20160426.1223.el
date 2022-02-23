;;; emacsist-view.el --- Mode for viewing emacsist.com

;; Copyright (C) 2004-2015 DarkSun <lujun9972@gmail.com>.

;; Author: DarkSun <lujun9972@gmail.com>
;; Created: 2015-12-31
;; Version: 0.1
;; Package-Version: 20160426.1223
;; Package-Commit: f67761259ed779a9bc95c9a4e0474522990c5c6b
;; Keywords: convenience, usability
;; Homepage: https://github.com/lujun9972/emacsist-view

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
;; emacsist-view's code can be found here:
;;   https://github.com/lujun9972/emacsist-view

;;; Commentary:

;; Mode for viewing emacsist.com

;; Quick start:

;; execute the following commands:
;; `list-emacsist' to list posts in emacsist.com
;; then press ~v~ to view post in eww
;; press ~<RET>~ or ~click down mouse-1~ to browse current post with external browser
;; press ~<next>~ to list posts in next-page
;; press ~<prior>~ to list posts in previous-page

;;; Code:

(defvar emacsist-current-page 1)

(defun emacsist-url (page)
  "Return the url of emacsist.com"
  (format "http://emacsist.com/list/%d/com" page))

(defun emacsist-extract-paper-link (line)
  (string-match "href=\"\\(http://emacsist.com/[0-9]+\\)\" data-wid=\"[0-9]+\">\\(.+\\)</a>" line)
  (let ((url (match-string-no-properties 1 line))
        (title (decode-coding-string (match-string-no-properties 2 line) 'utf-8)))
    (propertize title 'help-echo url)))

(defun emacsist-extract-author-link (line)
  (string-match "href=\"\\(http://emacsist.com/[^\"]+\\)\" class=\"author\">\\(.+\\)</a>" line)
  (let ((url (match-string-no-properties 1 line))
        (author (decode-coding-string (match-string-no-properties 2 line) 'utf-8)))
    (propertize author 'help-echo url)))


(defun emacsist-extract-links (&optional url)
  "Extract links from HTML which is the source code of emacsist URL."
  (let* ((url (or url (emacsist-url emacsist-current-page)))
         (buf (url-retrieve-synchronously url))
         paper-link author-link entries)
    (unless buf
      (error "fetch % failed" url))
    (with-current-buffer buf
      (goto-char (point-min))
      (while (search-forward "<span class=\"title\">" nil t)
        (forward-line)
        (setq paper-link (emacsist-extract-paper-link (thing-at-point 'line)))
        (forward-line)
        (setq author-link (emacsist-extract-author-link (thing-at-point 'line)))
        (push (list nil (vector paper-link author-link)) entries)))
    (kill-buffer buf)
    (unless entries
      (error "NO MORE DATA"))
    (reverse entries)))

(defun emacsist--select-or-create-buffer-window (buffer-or-name)
  "若frame中有显示`buffer-or-name'的window,则选中该window,否则创建新window显示该buffer."
  (let ((buf (get-buffer-create buffer-or-name)))
    (unless (get-buffer-window buf)
      (split-window)
      (switch-to-buffer buf))
    (select-window (get-buffer-window buf))))

;; define emacsist-mode

(defun emacsist-eww-view ()
  (interactive)
  (let ((url (get-text-property (point) 'help-echo)));help-echo is also the url
    (emacsist--select-or-create-buffer-window "*eww*")
    (eww-browse-url url)))

(defun emacsist-browser-view ()
  (interactive)
  (let ((url (get-text-property (point) 'help-echo)));help-echo is also the url
    (browse-url url)))

(defun emacsist-next-page (&optional N)
  (interactive)
  (let ((N (or N 1)))
    (setq emacsist-current-page (+ emacsist-current-page N))
    (condition-case err
        (list-emacsist)
      (error (setq emacsist-current-page (- emacsist-current-page 1))
             (signal (car err) (cdr err))))))

(defun emacsist-previous-page (&optional N)
  (interactive)
  (let ((N (or N 1)))
    (setq emacsist-current-page (- emacsist-current-page N))
    (when (< emacsist-current-page 0)
      (setq emacsist-current-page 0))
    (list-emacsist)))

(define-derived-mode emacsist-mode tabulated-list-mode "emacsist-mode"
  "Mode for viewing emacsist.com"
  (setq tabulated-list-format [("title" 60 nil)
                               ("author" 10 t)]
        tabulated-list-entries 'emacsist-extract-links)
  (tabulated-list-init-header))

(define-key emacsist-mode-map (kbd "v") 'emacsist-eww-view)
(define-key emacsist-mode-map (kbd "<RET>") 'emacsist-browser-view)
(define-key emacsist-mode-map (kbd "<down-mouse-1>") 'emacsist-browser-view)
(define-key emacsist-mode-map (kbd "<next>") 'emacsist-next-page)
(define-key emacsist-mode-map (kbd "<prior>") 'emacsist-previous-page)

;;;###autoload
(defun list-emacsist ()
  "List paper in emacsist.com"
  (interactive)
  (switch-to-buffer (get-buffer-create "*emacsist*"))
  (emacsist-mode)
  (tabulated-list-print t))

(provide 'emacsist-view)

;;; emacsist-view.el ends here
