;;; smbc.el --- View SMBC from Emacs

;;; Copyright (C) 2016 Saksham Sharma <saksham0808@gmail.com>

;; Url: https://github.com/sakshamsharma/emacs-smbc
;; Package-Version: 20160706.2222
;; Package-Commit: c377b806118d82140197d9cb1095548477e00497
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
(require 'url)

;; TODO Shift to using an XML parser for rss.php file of smbc
;; Currently not doing that since it will make it hard to adapt
;; for a comic which does not have such a feed

(defun smbc-get-latest ()
  "Get latest SMBC comic and display in new buffer."
  (interactive)
  (smbc-display-image (smbc-get-image-data (smbc-parse-html (smbc-get-index-page)))))

(defun smbc-get-previous ()
  "Get the previous SMBC comic and display in BUFFER-NAME."
  (interactive)
  (let ((prev-id (int-to-string (- (string-to-int smbc-current-image-id) 1))))
    (smbc-display-in-buffer
     (smbc-get-image-data
      (smbc-parse-html (smbc-get-page-given-id prev-id))) smbc-buffer-name)
    (setq smbc-current-image-id prev-id)))

(defun smbc-get-next ()
  "Get the succeeding SMBC comic and display in BUFFER-NAME. Fails if currently latest."
  (interactive)
  (let ((next-id (int-to-string (+ (string-to-int smbc-current-image-id) 1))))
    (smbc-display-in-buffer
     (smbc-get-image-data
      (smbc-parse-html (smbc-get-page-given-id next-id))) smbc-buffer-name)
    (setq smbc-current-image-id next-id)))

(defun smbc-get-image-from-image-id (image-id)
  "Fetch image from SMBC, given the IMAGE-ID."
  (interactive
   (list (read-string "Image ID (smbc-comics.com/): ")))
  (smbc-get-image image-id))

(defun smbc-get-image-data (image-id)
  "Retrieve image data from smbc-comics.com/IMAGE-ID."
  (let ((buffer (url-retrieve-synchronously
                 (concat "http://www.smbc-comics.com/comics/" image-id))))
    (with-current-buffer buffer
      (goto-char (point-min))
      (search-forward "\n\n")
      (buffer-substring (point) (point-max)))))

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
  (erase-buffer)
  (insert-image (create-image image-data nil t))
  (use-local-map (copy-keymap global-map))
  (local-set-key "\C-cp" 'smbc-get-previous)
  (local-set-key "\C-cn" 'smbc-get-next)
  (special-mode))

(defun smbc-parse-html (html-page)
  "Parse the input HTML-PAGE for the comic image url."
  (smbc-chomp (let ((index html-page))
                (replace-regexp-in-string
                 "\" id=\"cc-comic.*" ""
                 (replace-regexp-in-string
                  ".*src=\"http://www.smbc-comics.com/comics/" "" index)))))

(defun smbc-get-index-page ()
  "Retrieve a part of the index page of SMBC."
  (let ((buffer (url-retrieve-synchronously
                 "http://smbc-comics.com")))
    (with-current-buffer buffer
      (goto-char (point-min))
      (search-forward "buythisimg")
      (let ((urlline (thing-at-point 'line)))
        (while (string-match ".*id%3D"
                             urlline)
          (setq urlline (replace-match "" t t urlline)))
        (while (string-match "\">.*"
                             urlline)
          (setq urlline (replace-match "" t t urlline)))
        (setq smbc-current-image-id (smbc-chomp urlline))))
    (with-current-buffer buffer
      (goto-char (point-min))
      (search-forward ".com/comics/")
      (thing-at-point 'line))))

(defun smbc-get-page-given-id (id)
  "Retrieve part of a page with given ID to be used as a GET parameter."
  (let ((buffer (url-retrieve-synchronously
                 (concat "http://smbc-comics.com/index.php?id=" id))))
    (with-current-buffer buffer
      (goto-char (point-min))
      (search-forward "comics/../comics")
      (thing-at-point 'line))))

(defun smbc-chomp (str)
  "Chomp leading and tailing whitespace from STR."
  (while (string-match "\\`\n+\\|^\\s-+\\|\\s-+$\\|\n+\\'"
                       str)
    (setq str (replace-match "" t t str)))
  str)

(provide 'smbc)
;;; smbc.el ends here
