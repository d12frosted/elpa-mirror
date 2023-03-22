;;; git-io.el --- Integration for git.io URL shortening in buffer  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Tejas Bubane

;; Author: Tejas Bubane <tejasbubane@gmail.com>
;; URL: https://github.com/tejasbubane/emacs-git-io
;; Package-Version: 20230322.1038
;; Package-Commit: fb25f9432e6454edd621a7512ee7abc6220151a5
;; Keywords: convenience files
;; Version: 0.1.1
;; Package-Requires: ((emacs "24.4"))

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

;;; Commentary:

;; Provides interactive command `git-io-shorten` to replace URL at point
;; with a shortened one using git.io
;; Gets the URL at current cursor position, makes a request to https://git.io/
;; to get the shortened URL and replaces the original url with the shortened one.

;;; Code:

(require 'subr-x)

(defun git-io-delete-before ()
  "Search for location header and delete everything before the match."
  (let ((location-header "Location: "))
    (goto-char (point-min))
    (re-search-forward location-header)
    (delete-region (point) (point-min))))

(defun git-io-delete-after ()
  "Delete buffer contents after the matched location header."
  (goto-char (line-end-position))
  (delete-region (point) (point-max)))

(defun git-io-extract-shortened-url ()
  "Delete everything except shortened URL found in location header."
  (git-io-delete-before)
  (git-io-delete-after)
  (string-trim (buffer-string)))

(defun git-io-shorten-url (input-url)
  "Argument INPUT-URL URL to shorten."
  (let ((gitio-url "https://git.io")
        (url-request-method "POST")
        (url-request-extra-headers
         '(("Content-Type" . "multipart/form-data")))
        (url-request-data (concat "url=" input-url)))
    (with-current-buffer
        (url-retrieve-synchronously gitio-url)
      (git-io-extract-shortened-url))))

;;;###autoload
(defun git-io-shorten ()
  "Replace thing at point with shortened URL."
  (interactive)
  (let* ((bounds (bounds-of-thing-at-point 'url))
         (start (car bounds))
         (end (cdr bounds))
         (original-url (string-trim (buffer-substring-no-properties start end)))
         (short-url (git-io-shorten-url original-url)))
    (delete-region start end)
    (insert short-url)
    (message short-url)))

(provide 'git-io)
;;; git-io.el ends here
