;;; temporary-persistent.el --- Keep temp notes buffers persistent -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2023 Kostafey <kostafey@gmail.com>

;; Author: Kostafey <kostafey@gmail.com>
;; URL: https://github.com/kostafey/temporary-persistent
;; Package-Version: 20230115.1425
;; Package-Commit: edbde738769e79ac212ae84ae7898ffd5f19e0f1
;; Keywords: temp, buffers, notes
;; Version: 0.1
;; Package-Requires: ((emacs "24.3") (names "20151201.0") (dash "2.12.1") (s "1.10.0"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; temporary-persistent.el -  easy way to switch temp buffers and keep them
;; persistent. It provides `temporary-persistent-switch-buffer' function
;; to create temporary buffers named *temp*, *temp-1* and so on, witch is
;; associated to files and will be saved any time you run `kill-buffer' or
;; `kill-emacs'.
;; Furtermore, you can save them manually any time via `save-buffer' function.
;; See README.md for more information.

;;; Code:

(require 's)
(require 'dash)
(require 'names)

(defgroup temporary-persistent nil
  "Keep temp notes buffers persistent."
  :group 'convenience)

(define-namespace temporary-persistent-

(defcustom default-submodes (list 'auto-fill-mode
                                  'auto-complete-mode)
  "List of submodes enabled in new temp buffer."
  :type 'list
  :group 'temporary-persistent)

(defcustom store-folder "~/temp"
  "Directory to keep files with temporary buffers content."
  :type 'string
  :group 'temporary-persistent)

(defcustom buffer-name-template "temp"
  "Template for temporary buffers names."
  :type 'string
  :group 'temporary-persistent)

(defun save-and-kill-buffer ()
  "Save buffer contents and kill buffer."
  (save-buffer)
  (set (make-local-variable 'kill-buffer-query-functions) nil)
  (kill-buffer (current-buffer)))

(defun save-all-related-buffers ()
  "Save all buffers corresponding to `buffer-name-template'."
  (-map
   (lambda (buf)
     (if (string-match
          (concat "^\\*" buffer-name-template "\\(-[0-9]+\\)?" "\\*$" )
          (buffer-name buf))
         (save-buffer buf)))
   (buffer-list)))

:autoload
(defun switch-buffer (&optional num)
  "Switch to temp buffer."
  (interactive "P")
  (let* ((temp-file-name (if (and num (numberp num))
                             (concat buffer-name-template
                                     "-"
                                     (int-to-string num))
                           buffer-name-template))
         (temp-file-path (progn
                           (unless (file-exists-p store-folder)
                             (make-directory store-folder t))
                           (expand-file-name temp-file-name store-folder)))
         (temp-buffer-name (concat "*" temp-file-name "*")
                           buffer-name-template))
    (if (not (get-buffer temp-buffer-name))
        (progn
          (find-file temp-file-path)
          (rename-buffer temp-buffer-name)
          (-map (lambda (mode)
                  (when (fboundp mode)
                    (funcall mode t)))
                default-submodes))
      (switch-to-buffer temp-buffer-name))
    (set (make-local-variable 'kill-buffer-query-functions)
         'temporary-persistent-save-and-kill-buffer)))
)

(add-hook 'kill-emacs-hook 'temporary-persistent-save-all-related-buffers)

(provide 'temporary-persistent)

;;; temporary-persistent.el ends here
