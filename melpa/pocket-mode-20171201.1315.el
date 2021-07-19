;;; pocket-mode.el --- Manage your pocket  -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2017 DarkSun

;; Author: DarkSun <lujun9972@gmail.com>
;; Created: 2016-5-23
;; Version: 0.1
;; Package-Version: 20171201.1315
;; Package-Commit: 229de7d35b7e5605797591c46aa8200d7efc363c
;; Keywords: convenience, pocket
;; Package-Requires: ((emacs "24.4") (pocket-api "0.1"))

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
;; pocket-mode's code can be found here:
;;   http://github.com/lujun9972/pocket-mode

;; Quick start:

;; execute the following commands:
;; `pocket-list' to list posts in pocket.com
;; then press ~v~ to view post in eww
;; press ~<RET>~ or ~click down mouse-1~ to browse current post with external browser
;; press ~<next>~ to list posts in next-page
;; press ~<prior>~ to list posts in previous-page
;; Press ~a~ to archive the post
;; Press ~C-u a~ to readd the post
;; Press ~d~ to delete the post
;; Press ~C-u d~ to add the post

;;; Code:

(require 'cl-lib)
(require 'pocket-api)

(defgroup pocket-mode nil
  "Manage your pocket"
  :group 'tools)

(defvar pocket-current-item 0)

(defcustom pocket-buffer-name "*pocket*"
  "Specify buffer name"
  :type 'string
  :group 'pocket-mode)

(defcustom pocket-items-per-page 20
  "How many items will be displayed per page"
  :type 'number
  :group 'pocket-mode)

(defcustom pocket-auto-refresh nil
  "Non-nil means to refresh after archive/readd/delete/add a post"
  :type 'boolean
  :group 'pocket-mode)

(defcustom pocket-archive-when-browse nil
  "Non-nil means make post archived after browse the post"
  :type 'boolean
  :group 'pocket-mode)

(cl-defun pocket-retrieve (&key (offset pocket-current-item) (count pocket-items-per-page))
  "Retrieve pocket items"
  (let* ((pocket-response (pocket-api-get :offset offset :count count))
         (item-list (cdr (assoc 'list pocket-response)))
         entries)
    (dolist (item item-list)
      (let ((item-id (cdr (assoc 'item_id item)))
            (entry-data (mapcar (lambda (item-format)
                                  (cdr (assoc-string (car item-format) item)))
                                tabulated-list-format)))
        (unless (member nil entry-data) ;如果有nil的话,会渲染失败
          (push (list item-id (apply #'vector entry-data)) entries))))
    (reverse entries)))

;; (pocket-retrieve)

(defun pocket--select-or-create-buffer-window (buffer-or-name)
  "若frame中有显示`buffer-or-name'的window,则选中该window,否则创建新window显示该buffer"
  (let ((buf (get-buffer-create buffer-or-name)))
    (unless (get-buffer-window buf)
      (split-window)
      (switch-to-buffer buf))
    (select-window (get-buffer-window buf))))

;; define pocket-mode

(defun pocket--get-current-entry-value (title)
  (let ((pos (cl-position-if (lambda (title-format)
                               (string= title (car title-format)))
                             tabulated-list-format))
        (entry (tabulated-list-get-entry)))
    (elt entry pos)))

;;;###autoload
(defun pocket-eww-view ()
  (interactive)
  (let ((url (pocket--get-current-entry-value "resolved_url"))
        (pocket-buf (current-buffer))) ;Current buffer should be the pocket buffer
    (pocket--select-or-create-buffer-window "*eww*")
    (eww-browse-url url)
    (when pocket-archive-when-browse
      (with-current-buffer pocket-buf
        (pocket-archive-or-readd)))))

;;;###autoload
(defun pocket-browser-view ()
  (interactive)
  (let* ((url (pocket--get-current-entry-value "resolved_url"))
         (pocket-buf (current-buffer))) ;Current buffer should be the pocket buffer
    (browse-url url)
    (when pocket-archive-when-browse
      (with-current-buffer pocket-buf
        (pocket-archive-or-readd )))))

;;;###autoload
(defun pocket-archive ()
  (interactive)
  (pocket-api-archive (tabulated-list-get-id))
  (message "%s archived" (pocket--get-current-entry-value "resolved_title"))
  (when pocket-auto-refresh
    (pocket-refresh)))

;;;###autoload
(defun pocket-readd ()
  (interactive)
  (pocket-api-readd (tabulated-list-get-id))
  (message "%s readded" (pocket--get-current-entry-value "resolved_title"))
  (when pocket-auto-refresh
    (pocket-refresh)))

;;;###autoload
(defun pocket-archive-or-readd (&optional prefix)
  (interactive "P")
  (if prefix
      (pocket-readd)
    (pocket-archive)))

;;;###autoload
(defun pocket-delete ()
  (interactive)
  (pocket-api-delete (tabulated-list-get-id))
  (message "%s deleted" (pocket--get-current-entry-value "resolved_title"))
  (when pocket-auto-refresh
    (pocket-refresh)))

;;;###autoload
(defun pocket-add ()
  (interactive)
  (let ((url (read-string "pocket url:" (case major-mode
                                          ('eww-mode (eww-current-url))
                                          ('w3m-mode w3m-current-url)
                                          (t "")))))
    (pocket-api-add url)
    (message "%s added" url))
  (when (and pocket-auto-refresh (eq major-mode 'pocket-mode))
    (pocket-refresh)))

;;;###autoload
(defun pocket-delete-or-add (&optional prefix)
  (interactive "P")
  (if prefix
      (pocket-add)
    (pocket-delete)))


;;;###autoload
(defun pocket-next-page (&optional N)
  (interactive)
  (let ((N (or N pocket-items-per-page)))
    (setq pocket-current-item (+ pocket-current-item N))
    (condition-case err
        (list-pocket)
      (error (setq pocket-current-item (- pocket-current-item 1))
             (signal (car err) (cdr err))))))

;;;###autoload
(defun pocket-previous-page (&optional N)
  (interactive)
  (let ((N (or N pocket-items-per-page)))
    (setq pocket-current-item (- pocket-current-item N))
    (when (< pocket-current-item 0)
      (setq pocket-current-item 0))
    (list-pocket)))

;;;###autoload
(defun pocket-refresh ()
  (interactive)
  (with-current-buffer pocket-buffer-name
    (tabulated-list-print t)))

;;;###autoload
(define-derived-mode pocket-mode tabulated-list-mode "pocket-mode"
  "mode for viewing pocket.com"
  (when (pocket-api-access-granted-p)
    (pocket-api-authorize))
  (setq tabulated-list-format [("resolved_title" 60 nil)
                               ("resolved_url" 60 t)]
        tabulated-list-entries 'pocket-retrieve)
  (tabulated-list-init-header)
  (define-key pocket-mode-map (kbd "v") 'pocket-eww-view)
  (define-key pocket-mode-map (kbd "<RET>") 'pocket-browser-view)
  (define-key pocket-mode-map (kbd "<down-mouse-1>") 'pocket-browser-view)
  (define-key pocket-mode-map (kbd "<next>") 'pocket-next-page)
  (define-key pocket-mode-map (kbd "<prior>") 'pocket-previous-page)
  (define-key pocket-mode-map (kbd "a") 'pocket-archive-or-readd)
  (define-key pocket-mode-map (kbd "d") 'pocket-delete-or-add)
  (define-key pocket-mode-map (kbd "r") 'pocket-refresh)
  (define-key pocket-mode-map (kbd "j") 'next-line)
  (define-key pocket-mode-map (kbd "k") 'previous-line)
  (define-key pocket-mode-map (kbd "h") 'backward-char)
  (define-key pocket-mode-map (kbd "l") 'forward-char))

;;;###autoload
(defun pocket-list ()
  "list paper in pocket.com"
  (interactive)
  (switch-to-buffer (get-buffer-create pocket-buffer-name))
  (pocket-mode)
  (tabulated-list-print t))

;;;###autoload
(defalias 'list-pocket #'pocket-list)


(provide 'pocket-mode)

;;; pocket-mode.el ends here
