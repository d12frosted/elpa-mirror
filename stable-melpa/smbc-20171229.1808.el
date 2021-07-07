;;; smbc.el --- View SMBC from Emacs

;;; Copyright (C) 2016 Saksham Sharma <saksham0808@gmail.com>

;; Url: https://github.com/sakshamsharma/emacs-smbc
;; Package-Version: 20171229.1808
;; Package-Commit: 10538e3d575ba6ef3c94d555af2744b42dfd36c7
;; Author: Saksham Sharma <saksham0808@gmail.com>
;; Version: 1.0
;; Keywords: smbc webcomic

;;; Commentary:

;; For more information, visit https://github.com/sakshamsharma/emacs-smbc
;; This file is not a part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Code:
(require 'dom)
(require 'url)
(require 'xml)

(defun smbc-get-latest ()
  "Get latest SMBC comic and display in new buffer."
  (interactive)
  (smbc-display-image (smbc-get-image-data (smbc-parse-html (smbc-get-index-page)))))

(defun smbc-get-previous ()
  "Get the previous SMBC comic and display in the SMBC buffer."
  (interactive)
  (if smbc-previous-url
      (smbc-display-in-buffer
       (smbc-get-image-data
        (smbc-parse-html (smbc-retrieve smbc-previous-url))) smbc-buffer-name)
    (message "No previous comic.")))

(defun smbc-get-next ()
  "Get the succeeding SMBC comic and display in the SMBC buffer."
  (interactive)
  (if smbc-next-url
      (smbc-display-in-buffer
       (smbc-get-image-data
        (smbc-parse-html (smbc-retrieve smbc-next-url))) smbc-buffer-name)
    (message "No next comic.")))

(defun smbc-get-image-from-image-id (image-id)
  "Fetch image from SMBC, given the IMAGE-ID."
  (interactive
   (list (read-string "Image ID (smbc-comics.com/comic/): ")))
  (smbc-display-image
   (smbc-get-image-data
    (smbc-parse-html
     (smbc-retrieve
      (url-expand-file-name image-id "http://smbc-comics.com/comic/"))))))

(defun smbc-get-image-data (url)
  "Retrieve image data from URL."
  (with-current-buffer (smbc-retrieve url)
    (buffer-string)))

(defun smbc-display-image (image-data)
  "Create new buffer for IMAGE-DATA and then display."
  (let ((buffer-name (generate-new-buffer-name "SMBC")))
    (get-buffer-create buffer-name)
    (smbc-display-in-buffer image-data buffer-name)))

(defun smbc-display-in-buffer (image-data buffer-name)
  "Display given IMAGE-DATA in a buffer named BUFFER-NAME."
  (setq smbc-buffer-name buffer-name)
  ;; If currently in same buffer, don't open a new one
  (if (equal (buffer-name) buffer-name)
      (switch-to-buffer buffer-name)
    (switch-to-buffer-other-window buffer-name))
  (read-only-mode 0)
  (save-excursion
    (erase-buffer)
    (when smbc-current-title
      (insert (propertize smbc-current-title 'face 'info-title-1) "\n"))
    (insert-image (create-image image-data nil t))
    (when smbc-current-alt
      (insert "\n" (propertize smbc-current-alt 'face 'italic)))
    (when smbc-after-image-url
      (insert "\n")
      (insert-image
       (create-image (smbc-get-image-data smbc-after-image-url) nil t))))
  (use-local-map (copy-keymap global-map))
  (local-set-key "\C-cp" 'smbc-get-previous)
  (local-set-key "\C-cn" 'smbc-get-next)
  (special-mode))

(defun smbc-parse-html (buffer)
  "Parse the document in BUFFER."
  (with-current-buffer buffer
    (let ((dom (libxml-parse-html-region (point-min) (point-max))))
      (let ((title (dom-by-tag dom 'title))
            (comic (dom-by-id dom "^cc-comic$"))
            (after-comic (dom-by-id dom "^aftercomic$"))
            (prev (dom-by-class dom "^prev$"))
            (next (dom-by-class dom "^next$")))
        (setq smbc-previous-url (when prev (dom-attr prev 'href))
              smbc-next-url (when next (dom-attr next 'href))
              smbc-current-title (when title (dom-text title))
              smbc-current-alt (when comic (dom-attr comic 'title))
              smbc-after-image-url (when after-comic
                                     (replace-regexp-in-string " " "%20"
                                       (dom-attr
                                        (dom-child-by-tag after-comic 'img)
                                        'src))))
        (when comic
          (replace-regexp-in-string " " "%20" (dom-attr comic 'src)))))))

(defun smbc-get-index-page ()
  "Retrieve the index page of SMBC."
  (smbc-retrieve "/"))

(defun smbc-retrieve (path-or-url)
  "Retrieve a comic page for SMBC."
  (let ((buffer (url-retrieve-synchronously
                 (url-expand-file-name path-or-url "http://smbc-comics.com/"))))
    (with-current-buffer buffer
      (goto-char (point-min))
      (search-forward "\n\n")
      (delete-region (point-min) (point))
      buffer)))

(provide 'smbc)
;;; smbc.el ends here
