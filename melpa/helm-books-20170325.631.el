;;; helm-books.el --- Helm interface for searching books
;; Author: grugrut <grugruglut+github@gmail.com>
;; URL: https://github.com/grugrut/helm-books
;; Package-Version: 20170325.631
;; Package-Commit: 625aadec1541a5ca36951e4ce1301f4b6fe2bf3f
;; Version: 1.0
;; Package-Requires: ((helm "1.7.7"))

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

;; Helm interface for searching books

;;; Code:

(eval-when-compile
  (defvar url-http-end-of-headers))

(require 'helm)
(require 'helm-net)
(require 'json)

(defgroup helm-books nil
  "Helm interface for searching books"
  :prefix "helm-books-"
  :group 'helm)

(defcustom helm-books-custom-format "#title#\n:PROPERTIES:\n:AUTHORS:#author#\n:END:"
  "A format of 'helm-books--custom-format-action'.
#title#, #author#, #publisher#, #publishDate# are replaced imformation of the book."
  :type 'string
  :group 'helm-books)

(defun helm-books--url-retrieve-from-google ()
  "Retrieve information of book using google books api."
  (switch-to-buffer
   (url-retrieve-synchronously
    (concat "https://www.googleapis.com/books/v1/volumes?q=" helm-pattern)))
  (let ((response-string (buffer-substring-no-properties
                          url-http-end-of-headers (point-max))))
    (kill-buffer (current-buffer))
    (json-read-from-string (decode-coding-string response-string 'utf-8))))

(defun helm-books--extract-values-from-google (item)
  "Extract attribute from result of api.
ITEM is each book information."
  (let ((title "")
        (author "")
        (publisher "")
        (publishedDate ""))
    (dolist (i item)
      (when (string= "volumeInfo" (car i))
        (dolist (j (cdr i))
          (when (string= "title" (car j))
            (setq title (cdr j)))
          (when (string= "authors" (car j))
            (setq author (cdr j)))
          (when (string= "publisher" (car j))
            (setq publisher (cdr j)))
          (when (string= "publishedDate" (car j))
            (setq publishedDate (cdr j)))
          )))
    (format "Title:%s, Authors:%s, Publisher:%s, PublishedDate:%s" title author publisher publishedDate)))

(defun helm-books--candidates-from-google ()
  "."
  (mapcar 'helm-books--extract-values-from-google (cdr (nth 2 (helm-books--url-retrieve-from-google)))))

(defun helm-books--candidates ()
  "."
  (funcall #'helm-books--candidates-from-google))

(defun helm-books--custom-format-action (candidate)
  "Insert string using custom format.
CANDIDATE is user selection."
  (let ((returnString helm-books-custom-format))
    (string-match "Title:\\(.+?\\)," candidate)
    (setq returnString (replace-regexp-in-string "#title#" (match-string 1 candidate) returnString))
    (string-match "Authors:\\(.+?\\)," candidate)
    (setq returnString (replace-regexp-in-string "#author#" (match-string 1 candidate) returnString))
    (string-match "Publisher:\\(.+?\\)," candidate)
    (setq returnString (replace-regexp-in-string "#publisher#" (match-string 1 candidate) returnString))
    (string-match "PublishDate:\\(.+?\\)," candidate)
    (setq returnString (replace-regexp-in-string "#publishedDate#" (match-string 1 candidate) returnString))
    (insert returnString)
    returnString
    ))
(defun helm-books--google-search-action (candidate)
  "Google search the title of user selection.
CANDIDATE is user selection."
  (string-match "Title:\\(.+?\\)," candidate)
  (helm-google-suggest-action (match-string 1 candidate)))

(defvar helm-books--source
  (helm-build-sync-source  "Books"
    :candidates #'helm-books--candidates
    :requires-pattern 1
    :volatile t
    :action (helm-make-actions
             "Insert custom format" #'helm-books--custom-format-action
             "Insert" #'insert
             "Google Search" #'helm-books--google-search-action)))

;;;###autoload
(defun helm-books ()
  "Books searcher with helm interface."
  (interactive)
  (let ((helm-input-idle-delay 0.3))
    (helm :sources '(helm-books--source)
          :prompt "Search books: "
          :buffer "*helm books*")))

(provide 'helm-books)

;;; helm-books.el ends here
