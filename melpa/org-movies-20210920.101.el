;;; org-movies.el --- Manage watchlist with Org mode -*- lexical-binding: t -*-

;; Author: Anh T Nguyen
;; Version: 0.1
;; Package-Version: 20210920.101
;; Package-Commit: e96fecaffa2924de64a507aa31d2934e667ee1ea
;; Package-Requires: ((emacs "26.1") (org "9.0") (request "0.3.0"))
;; Homepage: https://github.com/teeann/org-movies
;; Keywords: hypermedia, outlines, Org


;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
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

;; This package lets you import IMDb watchlist CSV file into an Org-mode file
;; and quickly convert an IMDb movie URL into a Org-mode heading

;;; Code:
(require 'org)
(require 'request)

(defgroup org-movies nil
  "Org watchlist management."
  :group 'org)

(defcustom org-movies-api-key ""
  "Key for interacting with OMDb API."
  :type 'string
  :group 'org-movies)

(defun org-movies--genres-to-tags (genres)
  "Convert GENRES to org genres."
  (concat
   ":"
   (mapconcat
    ;; replace '-' with '_'
    (lambda (s) (subst-char-in-string ?- ?_ (string-trim s)))
    (split-string genres ",")
    ":")
   ":"))

(defun org-movies--get-imdb-id (url)
  "Get IMDb id from URL."
  (string-match "\/title\/\\([a-z0-9]+\\)\/" url)
  (substring url (match-beginning 1) (match-end 1)))

;;;###autoload
(cl-defun org-movies-format (info &optional (level 2))
  "Get Org node from INFO alist of movie data.

LEVEL specifies Org heading level."
  (let* ((title (alist-get 'Title info))
         (year (alist-get 'Year info))
         (tags (org-movies--genres-to-tags (alist-get 'Genre info)))
         (heading (concat (make-string level ?*) " " title " " tags))
         (poster (alist-get 'Poster info))
         (director (alist-get 'Director info))
         (rating (alist-get 'imdbRating info))
         (added (format-time-string "[%Y-%02m-%02d]")))
    (format "%s
:PROPERTIES:
:YEAR: %s
:ADDED: %s
:POSTER: %s
:DIRECTOR: %s
:RATING: %s
:END:
" heading year added poster director rating)))

;;;###autoload
(cl-defun org-movies-from-url (url &optional (level 2))
  "Get movie org heading from URL.

LEVEL specifies Org heading level."
  (interactive
   (list (read-from-minibuffer
          "URL: " (or (thing-at-point 'url)
                      (when interprogram-paste-function
                        (funcall interprogram-paste-function))))))
  (let* ((imdb-id (org-movies--get-imdb-id url))
         (omdb-url (format "https://www.omdbapi.com/?i=%s&apikey=%s" imdb-id org-movies-api-key))
         org-node)
    (request omdb-url
      :parser #'json-read
      :sync t
      :success (cl-function
                (lambda (&key data &allow-other-keys)
                  (setq org-node (org-movies-format data level)))))
    org-node))

;;;###autoload
(defun org-movies-add-url ()
  "Get movie Org heading from url and insert at point."
  (interactive)
  (insert (call-interactively #'org-movies-from-url)))

(defun org-movies--get-urls-from-csv (csv)
  "Get all urls from CSV file."
  (let (urls)
    (with-current-buffer (find-file-noselect csv)
      (goto-char (point-min))
      (while (< (point) (point-max))
        (if (search-forward-regexp ",\\(http[^,]+\\)" (line-end-position) t)
            (push
             (buffer-substring-no-properties (match-beginning 1) (match-end 1))
             urls))
        (forward-line 1)))
    urls))

;;;###autoload
(defun org-movies-import-csv (csv-file org-file)
  "Import IMDb watchlist to Org file.

CSV-FILE specifies the IMDb watchlist file, ORG-FILE specifies the Org file to export to."
  (interactive "fCSV file to import: \nFOrg file to export: ")
  (let* ((urls (org-movies--get-urls-from-csv csv-file)))
    (cl-loop for url in urls do
             (request (format "https://www.omdbapi.com/?i=%s&apikey=%s"
                              (org-movies--get-imdb-id url)
                              org-movies-api-key)
               :parser #'json-read
               :success (cl-function
                         (lambda (&key data &allow-other-keys)
                           (with-current-buffer (find-file org-file)
                             (insert (org-movies-format data)))))))))

(provide 'org-movies)
;;; org-movies.el ends here
