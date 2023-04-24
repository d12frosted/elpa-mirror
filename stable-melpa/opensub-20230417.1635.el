;;; opensub.el --- Search and download from open-subtitles  -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Daniel Fleischer

;; Author: Daniel Fleischer <danflscr@gmail.com>
;; Keywords: multimedia
;; Package-Version: 20230417.1635
;; Package-Commit: 0faef3dad6fc9c0eda1db1b237e6f66a8f411b01
;; Homepage: https://github.com/danielfleischer/opensub
;; Version: 1.0.0
;; Package-Requires: ((emacs "25.1"))

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

;; Package to query and download subtitles from opensubtitles.com.
;;
;; Set up an account in opensubtitles.com; get an API key and set it
;; in `opensub-api-key'.
;;
;; To run, call `opensub', provide a query string such as "matrix" or
;; "office s04e13". Select the relevant file among the options, and it
;; will be downloaded to `opensub-download-directory'.

;;; Code:
(require 'cl-lib)
(require 'json)
(require 'webjump)

(defgroup opensub nil
  "Search and fetch subtitles from opensubtitles.com."
  :group 'multimedia)

(defcustom opensub-api-key ""
  "API key for opensubtitles.com."
  :type 'string)

(defcustom opensub-download-directory "~/Downloads/"
  "Directory where subtitles will be downloaded to."
  :type 'directory)

(defvar opensub--json-fn
  (if (version<= "27.1" emacs-version)
      (lambda () (json-parse-buffer :object-type 'alist))
    #'json-read)
  "JSON parsing function.")

(defun opensub--curl (url)
  "Given a URL, return parsed json."
  (with-current-buffer
      (url-retrieve-synchronously url)
    (goto-char (point-min))
    (search-forward "\n\n")
    (delete-region (point-min) (point))
    (funcall opensub--json-fn)))

(defun opensub--curl-retrieve (query)
  "Run a QUERY on opensubtitles.com. Return parsed json."
  (let* ((clean-query (webjump-url-encode query))
         (url-request-method "GET")
         (url-request-extra-headers
          `(("Api-Key" . ,opensub-api-key)
            ("Content-Type" . "application/json")))
         (url (format "https://api.opensubtitles.com/api/v1/subtitles?query=%s"
                      clean-query)))
    (opensub--curl url)))

(defun opensub--get-file-id (results)
  "Given query RESULTS, return the file id of user-selected item."
  (let* ((items (alist-get 'data results))
         (options (cl-mapcar
                   (lambda (item)
                     (concat
                      (let-alist item .attributes.language) ": "
                      (let-alist item .attributes.release)))
                   items))
         (option (completing-read "Select: " options))
         (item  (cl-find-if (lambda (x)
                              (string-suffix-p (let-alist x .attributes.release)
                                               option))
                            items)))
    (alist-get 'file_id (aref (let-alist item .attributes.files) 0))))


(defun opensub--curl-get-download-info (media-id)
  "Given a MEDIA-ID, generate a downloadable link.
Returns alist with link and file name.
Uses a POST call to generate a time-limited link.
May fail if exceeds daily usage limits."
  (let* ((url-request-method "POST")
         (url-request-extra-headers
          `(("Api-Key" . ,opensub-api-key)
            ("Content-Type" . "application/json")))
         (url-request-data
          (format "{\"file_id\": %s}" media-id))
         (response
          (opensub--curl "https://api.opensubtitles.com/api/v1/download")))
    (if (alist-get 'link response) response
      (user-error (alist-get 'message response)))))

(defun opensub--download-subtitle (item)
  "Given ITEM information, downloads subtitle to downloads dir."
  (let* ((link (alist-get 'link item))
         (filename (concat (file-name-as-directory
                            opensub-download-directory)
                           (alist-get 'file_name item))))
    (unless (url-copy-file link filename)
      (error "Couldn't download the subtitle. Try again"))
    filename))

;;;###autoload
(defun opensub ()
  "Run opensub."
  (interactive)
  (let* ((query (read-from-minibuffer "Search a show/movie: "))
         (results (opensub--curl-retrieve query))
         (item-id (opensub--get-file-id results))
         (item (opensub--curl-get-download-info item-id))
         (filename (opensub--download-subtitle item)))
    (message "Subtitle downloaded: `%s'" filename)))

(provide 'opensub)
;;; opensub.el ends here
