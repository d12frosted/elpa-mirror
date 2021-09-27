;;; license-templates.el --- Create LICENSE using GitHub API  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Shen, Jen-Chieh
;; Created date 2020-07-24 11:11:15

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Create LICENSE using GitHub API.
;; Keyword: license api template
;; Version: 0.1.3
;; Package-Version: 20200906.2047
;; Package-Commit: 9d945eecb31c6be02bf0388c5c6883dfd1782bb9
;; Package-Requires: ((emacs "24.3") (request "0.3.0"))
;; URL: https://github.com/jcs-elpa/license-templates

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
;; Create LICENSE using GitHub API.
;;

;;; Code:

(require 'json)
(require 'url)

(defgroup license-templates nil
  "Create LICENSE using GitHub API."
  :prefix "license-templates-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/license-templates"))

(defcustom license-templates-filename "LICENSE"
  "Filename when creating new license file."
  :type 'string
  :group 'license-templates)

(defvar license-templates--names nil
  "List of names of available templates.")

(defvar license-templates--info-list nil
  "List of license data information.")

(defvar url-http-end-of-headers)

;;; Util

(defun license-templates--url-to-string (url)
  "Get data by URL and convert it to string."
  (with-current-buffer (url-retrieve-synchronously url)
    (set-buffer-multibyte t)
    (prog1 (buffer-substring (1+ url-http-end-of-headers) (point-max))
      (kill-buffer))))

(defun license-templates--url-to-json (url)
  "Get data by URL and convert it to JSON."
  (with-current-buffer (url-retrieve-synchronously url)
    (set-buffer-multibyte t)
    (goto-char url-http-end-of-headers)
    (prog1 (let ((json-array-type 'list)) (json-read))
      (kill-buffer))))

;;; Core

(defun license-templates--form-data (name url content)
  "Form license data by NAME, URL, CONTENT."
  (list :name name :url url :content content))

(defun license-templates--get-content-by-url (url)
  "Get the content by license URL."
  (let ((license-json (license-templates--url-to-json url))
        (content ""))
    (dolist (data license-json)
      (let ((key (car data)) (val (cdr data)))
        (when (equal key 'body) (setq content val))))
    content))

(defun license-templates--collect-data (lice)
  "Collect data from license data (LICE)."
  (let (name url content)
    (dolist (data lice)
      (let ((key (car data)) (val (cdr data)))
        (cl-case key
          ('key (setq name val))  ; key is the name.
          ('url
           (setq url val)
           (setq content (license-templates--get-content-by-url url))))))
    (license-templates--form-data name url content)))

(defun license-templates--get-info ()
  "Get all necessary information."
  (setq license-templates--info-list '())
  (let ((licenses-json
         (license-templates--url-to-json "https://api.github.com/licenses")))
    (dolist (lice licenses-json)
      (push (license-templates--collect-data lice)
            license-templates--info-list)))
  (setq license-templates--info-list (reverse license-templates--info-list)))

(defun license-templates--safe-get-info ()
  "Get the license information without refreshing cache."
  (unless license-templates--info-list (license-templates--get-info)))

(defun license-templates-names ()
  "Return list of names of available license."
  (license-templates--safe-get-info)
  (unless license-templates--names
    (dolist (data license-templates--info-list)
      (push (plist-get data :name) license-templates--names))
    (setq license-templates--names (reverse license-templates--names)))
  license-templates--names)

(defun license-templates--get-content-by-name (name)
  "Return license template by NAME."
  (license-templates--safe-get-info)
  (let ((content ""))
    (dolist (data license-templates--info-list)
      (when (equal (plist-get data :name) name)
        (setq content (plist-get data :content))))
    content))

;;;###autoload
(defun license-templates-insert (name)
  "Insert license for NAME."
  (interactive
   (list (completing-read "License template: "
                          (license-templates-names)
                          nil t)))
  (insert (license-templates--get-content-by-name name)))

;;;###autoload
(defun license-templates-new-file (name &optional dir)
  "Create a license file with NAME in DIR."
  (interactive
   (list (completing-read "License template: "
                          (license-templates-names)
                          nil t)
         (if current-prefix-arg
             (read-directory-name "Create license in directory: ")
           default-directory)))
  (let ((file (expand-file-name license-templates-filename dir)))
    (when (file-exists-p file)
      (user-error "Can't create '%s', because it already exists"
                  (abbreviate-file-name file)))
    (write-region (license-templates--get-content-by-name name) nil file)))

(provide 'license-templates)
;;; license-templates.el ends here
