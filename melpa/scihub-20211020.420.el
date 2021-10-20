;;; scihub.el --- Sci-Hub integration                 -*- lexical-binding: t -*-

;; Copyright (C) 2018 Mario Rodas <marsam@users.noreply.github.com>

;; Author: Mario Rodas <marsam@users.noreply.github.com>
;; URL: https://github.com/emacs-pe/scihub.el
;; Package-Version: 20211020.420
;; Package-Commit: d96c462e7f340f142ce3c5ffd31fa267223fd854
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))

;; This file is NOT part of GNU Emacs.

;;; License:

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

;; Sci-Hub integration.  See: <URL:https://en.wikipedia.org/wiki/Sci-Hub>.

;;; Code:
(eval-when-compile
  (require 'cl-lib)
  (require 'subr-x)
  (defvar url-request-data)
  (defvar url-request-method)
  (defvar url-http-end-of-headers)
  (defvar url-request-extra-headers))

(require 'dom)
(require 'url-parse)

(declare-function mail-narrow-to-head "mail-parse")
(declare-function url-generic-parse-url "url-parse")
(declare-function url-http-parse-response "url-http")

(defgroup scihub nil
  "Sci-Hub integration"
  :prefix "scihub-"
  :group 'applications)

(defcustom scihub-homepage "https://sci-hub.se/"
  "Sci-hub homepage.

Use \\[scihub-homepage] to set it to an active Sci-Hub domain.

See also `https://en.wikipedia.org/wiki/Sci-Hub' for updated domains."
  :type 'string
  :type '(choice
          (const :tag "sci-hub.se" "https://sci-hub.se/")
          (const :tag "sci-hub.st" "https://sci-hub.st/")
          string)
  :group 'scihub)

(defcustom scihub-download-directory (expand-file-name "~/papers/")
  "Directory where the papers will be downloaded."
  :type '(directory :must-match t)
  :group 'scihub)

(defcustom scihub-fetch-domain 'scihub-fetch-domains-lovescihub
  "Function used to fetch active Sci-Hub domains."
  :type '(radio (function-item scihub-fetch-domains-lovescihub)
                (function-item scihub-fetch-domains-scihub_ck)
                (function :tag "Function"))
  :group 'scihub)

(defcustom scihub-open-after-download t
  "Whether to open pdf after download."
  :type 'boolean
  :group 'scihub)

(define-error 'scihub-error "Unknown scihub error")
(define-error 'scihub-not-found "Article not found" 'scihub-error)

(defun scihub-pdf-p (filename)
  "Check if FILENAME is PDF file.

From the PDF specification 1.7:

    The first line of a PDF file shall be a header consisting of
    the 5 characters %PDF- followed by a version number of the
    form 1.N, where N is a digit between 0 and 7."
  (let ((header (with-temp-buffer
                  (set-buffer-multibyte nil)
                  (insert-file-contents-literally filename nil 0 5)
                  (buffer-string))))
    (string-equal (encode-coding-string header 'utf-8) "%PDF-")))

(defun scihub-fetch-domains-lovescihub ()
  "Fetch working Sci-Hub domains using lovescihub.

See: `https://lovescihub.wordpress.com/'."
  (let* ((dom (with-current-buffer (url-retrieve-synchronously "https://lovescihub.wordpress.com/")
                (goto-char (1+ url-http-end-of-headers))
                (libxml-parse-html-region (point) (point-max))))
         (content (car (dom-by-class dom "entry-content"))))
    (cl-loop for node in (dom-children (nth 5 content))
             when (eq (car-safe node) 'a)
             collect (dom-attr node 'href))))

(defun scihub-fetch-domains-scihub_ck ()
  "Fetch working Sci-Hub domains using scihub_ck.

See: `https://wadauk.github.io/scihub_ck/'."
  (let ((dom (with-current-buffer (url-retrieve-synchronously "https://wadauk.github.io/scihub_ck/")
               (goto-char (1+ url-http-end-of-headers))
               (libxml-parse-html-region (point) (point-max)))))
    (cl-loop for div in (dom-by-class dom "eleven wide column")
             collect (dom-attr (assq 'a div) 'href))))

(defun scihub-read-catpcha (image-url)
  "Read captcha from Sci-Hub IMAGE-URL."
  (with-current-buffer (get-buffer-create "*scihub-captcha*")
    (let ((inhibit-read-only t)
          (data (with-current-buffer (url-retrieve-synchronously image-url)
                  (goto-char (1+ url-http-end-of-headers))
                  (buffer-substring (point) (point-max))))
          (type (if (or (and (fboundp 'image-transforms-p)
                             (image-transforms-p))
                        (not (fboundp 'imagemagick-types)))
                    nil
                  'imagemagick)))
      (erase-buffer)
      (insert-image (create-image data type 'data-p)))
    (display-buffer (current-buffer))
    (prog1 (read-string "Enter captcha: ")
      (kill-buffer))))

(defun scihub-solve-captcha (url path dom)
  "Solve captcha for URL and DOM and save the file to PATH."
  (let ((urlobj (url-generic-parse-url url))
        (id (dom-attr (car (dom-by-tag dom 'input)) 'value))
        (captcha (dom-attr (dom-by-id dom "captcha") 'src)))
    (setf (url-filename urlobj) captcha)
    (let ((url-request-method "POST")
          (url-request-data (url-build-query-string
                             `(("id" ,id)
                               ("answer" ,(scihub-read-catpcha (url-recreate-url urlobj))))))
          (url-request-extra-headers '(("Content-Type" . "application/x-www-form-urlencoded"))))
      (with-current-buffer (url-retrieve-synchronously url)
        (goto-char (point-min))
        (cl-assert (= (url-http-parse-response) 302) nil "Invalid Sci-Hub captcha")
        (mail-narrow-to-head)
        (setf (url-filename urlobj) (mail-fetch-field "Location"))
        (url-copy-file (url-recreate-url urlobj) path)))))

(defun scihub-url-filename (url)
  "Read filename from an URL."
  (let* ((name (url-file-nondirectory url))
         (file (and (not (string-blank-p name)) (expand-file-name name scihub-download-directory))))
    (if (and file (not (file-exists-p file))) file (read-file-name "Save to file: " scihub-download-directory name))))

(defun scihub-fetch-callback (status query filename)
  "Callback for Sci-Hub, check whether url STATUS erred.

QUERY is the initial query passed to `scihub', and FILENAME is the
path where the PDF will be downloaded."
  (if (plist-get status :error)
      (message (error-message-string (plist-get status :error)))
    (let* ((dom (with-current-buffer (current-buffer)
                  (goto-char (1+ url-http-end-of-headers))
                  (libxml-parse-html-region (point) (point-max))))
           (save-link (dom-attr (dom-search dom (lambda (d) (and (stringp (caddr d)) (string-suffix-p " save" (caddr d))))) 'onclick)))
      (if (not save-link)
          (signal 'scihub-not-found (list query))
        (let* ((url (string-remove-suffix "'" (string-remove-prefix "location.href='" save-link)))
               (pdf-url (if (string-match-p url-nonrelative-link url) url (concat "http:" url)))
               (pdf-file (or filename (scihub-url-filename pdf-url)))
               (potential-file (make-temp-name (expand-file-name "scihub" temporary-file-directory))))
          (url-copy-file pdf-url potential-file)
          (if (scihub-pdf-p potential-file)
              (copy-file potential-file pdf-file 1)
            (scihub-solve-captcha pdf-url pdf-file (let ((coding-system-for-read 'utf-8))
                                                     (with-temp-buffer
                                                       (insert-file-contents potential-file)
                                                       (libxml-parse-html-region (point-min) (point-max))))))
          (delete-file potential-file)
          (when scihub-open-after-download
            (find-file-existing pdf-file)))))))

;;;###autoload
(defun scihub-homepage ()
  "Set a valid Sci-hub homepage."
  (interactive)
  (let ((url (completing-read "Sci-Hub Domain: " (funcall scihub-fetch-domain) nil t)))
    (if (yes-or-no-p "Save the domain for future sessions? ")
        (customize-save-variable 'scihub-homepage url)
      (customize-set-variable 'scihub-homepage url))))

;;;###autoload
(defun scihub (query &optional filename)
  "Download a paper from Sci-Hub with QUERY to FILENAME."
  (interactive (list (read-string "Enter URL, PMID / DOI or search string: ")
                     (and current-prefix-arg (read-file-name "Save paper PDF to file: " scihub-download-directory))))
  (let ((url-request-method "POST")
        (url-request-data (url-build-query-string `(("request" ,query))))
        (url-request-extra-headers '(("Content-Type" . "application/x-www-form-urlencoded"))))
    (url-retrieve scihub-homepage #'scihub-fetch-callback (list query filename))))

(provide 'scihub)
;;; scihub.el ends here
