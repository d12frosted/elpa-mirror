;;; consult-hatena-bookmark.el --- Consult commands for the Hatena Bookmark -*- lexical-binding: t -*-

;; Copyright (C) 2021, 2022 Yukinori Kitadai

;; Author: Yukinori Kitadai
;; Package-Requires: ((emacs "27.1") (consult "0.9") (async-await "1.1"))
;; Package-Version: 20221125.109
;; Package-Commit: b85484b11705ebd896878d3ac7fdb12bc8c9637a
;; Version: 0.3.1
;; URL: https://github.com/Nyoho/consult-hatena-bookmark

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Preparation: Set `consult-hatena-bookmark-hatena-username'
;; and `consult-hatena-bookmark-hatena-api-key'.

;; Run the function `consult-hatena-bookmark`
;; or `M-x consult-hatena-bookmark`.

;;; Code:

(require 'subr-x)
(require 'consult)
(require 'async-await)

(defgroup consult-hatena-bookmark nil
  "Consulting Hatena Bookmark."
  :group 'convenience)

(defcustom consult-hatena-bookmark-hatena-username nil
  "Your username of Hatena."
  :group 'consult-hatena-bookmark
  :type 'string)

(defcustom consult-hatena-bookmark-hatena-api-key nil
  "Your API key of Hatena.

Your API key is the string of the part of your submission mail address
 before `@'.
See:
https://www.hatena.ne.jp/my/config/mail/upload
https://developer.hatena.ne.jp/ja/documents/auth/apis/wsse ."
  :group 'consult-hatena-bookmark
  :type 'string)

(defvar consult-hatena-bookmark--history nil)

(defvar consult-hatena-bookmark--stopping nil)

(defun consult-hatena-bookmark--position (cand &optional find-file)
  "Return the hatena-bookmark position marker for CAND.
FIND-FILE is the file open function, defaulting to `find-file'."
  (when cand
    (let* ((file-end (next-single-property-change 0 'face cand))
           (line-end (next-single-property-change (+ 1 file-end) 'face cand))
           (col (next-single-property-change (+ 1 line-end) 'face cand))
           (file (substring-no-properties cand 0 file-end))
           (line (string-to-number (substring-no-properties cand (+ 1 file-end) line-end))))
      (setq col (if col (- col line-end 1) 0))
      (consult--position-marker
       (funcall (or find-file #'find-file) file)
       line col))))

(defun consult-hatena-bookmark--state ()
  "Hatena-Bookmark preview state function."
  (let ((open (consult--temporary-files))
        (jump (consult--jump-state)))
    (lambda (cand restore)
      (when restore
        (funcall open))
      (funcall jump
               (consult-hatena-bookmark--position cand (and (not restore) open))
               restore))))

(defun consult-hatena-bookmark--annotator ()
  "Annotate `consult-hatena-bookmark' candidates.
Currently with counts of bookmarks and dates."
  (let* ((align (propertize " " 'display `(space :align-to (- right 29)))))
    (lambda (cand)
      (let ((x (get-text-property 0 'hatena-bookmark-item cand)))
        (concat align
         (if-let (d (alist-get 'count x))
             (format "%5d " d) " ")
         (if-let (d (alist-get 'date x))
             (format "%s" d) ""))))))

(defun consult-hatena-bookmark--string-to-list (str)
  "Parse string STR as JSON and construct candidates."
  (let (candidates)
    (save-match-data
      (if-let (json (json-parse-string str))
          (let* ((meta (gethash "meta" json))
                 (bookmarks (gethash "bookmarks" json))
                 (total (gethash "total" meta)))
            (unless (eq total 0)
              (setq candidates
                    (mapcar (lambda (item)
                              (let* ((ts (gethash "timestamp" item))
                                     (date (format-time-string "%F %T" (seconds-to-time ts)))
                                     (comment (gethash "comment" item))
                                     (entry (gethash "entry" item))
                                     (count (gethash "count" entry))
                                     (url (gethash "url" entry))
                                     (title (gethash "title" entry)))
                                (add-face-text-property 0 (length url) 'consult-file nil url)
                                (add-face-text-property 0 (length comment) 'marginalia-char nil comment)
                                (propertize
                                 (propertize
                                  (concat
                                   (format "%s %s" title url)
                                   (if (string= comment "") "" (format " %s" comment)))
                                  'hatena-bookmark-item
                                  `((date    . ,date)
                                    (comment . ,comment)
                                    (count . ,count)))
                                 'consult--candidate
                                 url)))
                            bookmarks)))
            `(,total ,candidates))))))

(defun consult-hatena-bookmark--make-wsse-header ()
  "A helper function to make WSSE header as a string."
  (let* ((username consult-hatena-bookmark-hatena-username)
         (api-key consult-hatena-bookmark-hatena-api-key)
         (nonce
             (secure-hash 'sha1 (secure-hash 'sha1 (number-to-string (random 100000000000000)) nil nil t) nil nil t))
         (created (format-time-string "%FT%TZ"))
         (digest
          (base64-encode-string
           (secure-hash 'sha1 (concat nonce created api-key) nil nil t))))
    (format
     "UsernameToken Username=\"%s\", PasswordDigest=\"%s\", Nonce=\"%s\", Created=\"%s\""
     username
     digest
     (base64-encode-string nonce)
     created)))

(defun consult-hatena-bookmark--get (input &optional offset limit)
  "Access the Hatena Bookmark API with INPUT.
Use optional argument OFFSET to set `of' (=offset) option to search API.
Use optional argument LIMIT to limit the result of API (default: 20, max: 100)."
  (let* ((url-request-method "GET")
         (url-request-extra-headers
          `(("Authorization" . "WSSE profile=\"UsernameToken\"")
            ("X-WSSE" . ,(consult-hatena-bookmark--make-wsse-header))))
         (limit-string (if limit (format "&limit=%d" limit) ""))
         (url
          (format
           "https://b.hatena.ne.jp/my/search/json?q=%s%s"
           (url-hexify-string input) limit-string)))
    (if offset
        (setq url (concat url (format "&of=%d" offset))))

    (promise-new
     (lambda (resolve reject)
       (with-temp-buffer
         (url-insert-file-contents url)
         (if-let ((ret (consult-hatena-bookmark--string-to-list (buffer-substring (point) (point-max)))))
             (funcall resolve ret)
           (error (funcall reject nil))))))))

(async-defun consult-hatena-bookmark--search-all (callback &optional input)
  "Perform a search query for INPUT, receiving its results with CALLBACK."
  (let (total (offset 0) (first-time t))
    (while (and (or (not total) (< offset total)) (null consult-hatena-bookmark--stopping))
      (let* ((limit (if first-time 20 100))
             (res (await (consult-hatena-bookmark--get input offset limit)))
             (total_ (car res))
             (items (cdr res)))
        (setq first-time nil)
        (if (not total) (setq total total_))
        (setq items (apply #'append items))
        (setq offset (+ offset (length items)))
        (funcall callback items)))))

(defun consult-hatena-bookmark---async-search (async)
  "Async search with ASYNC."
  (lambda (action)
    (pcase action
      (""
       (setq consult-hatena-bookmark--stopping t))
      ((pred stringp)
       (funcall async 'flush)
       (setq consult-hatena-bookmark--stopping nil)
       (consult-hatena-bookmark--search-all
        (lambda (x)
          (funcall async x))
        action))
      ('destroy
       (setq consult-hatena-bookmark--stopping t)
       (funcall async 'destroy))
      (_ (funcall async action)))))

(defun consult-hatena-bookmark--search-generator ()
  "Generate an async search closure."
  (thread-first (consult--async-sink)
    (consult--async-refresh-immediate)
    (consult-hatena-bookmark---async-search)
    (consult--async-throttle)
    (consult--async-split)))

;;;###autoload
(defun consult-hatena-bookmark (&optional initial)
  "Search for your Hatena Bookmark with INITIAL input.
The process fetching your Hatena bookmarks is started asynchronously."
  (interactive)
  (unless consult-hatena-bookmark-hatena-username
    (warn "Set consult-hatena-bookmark-hatena-username."))
  (unless consult-hatena-bookmark-hatena-api-key
    (warn "Set consult-hatena-bookmark-hatena-api-key."))
  (browse-url (consult--read
               (consult-hatena-bookmark--search-generator)
               :prompt "Hatena Bookmark: "
               :category 'hatena-bookmark-item
               :require-match t
               :lookup #'consult--lookup-candidate
               :initial (consult--async-split-initial initial)
               :annotate (consult-hatena-bookmark--annotator)
               :sort nil
               :add-history (consult--async-split-thingatpt 'symbol)
               :history '(:input consult-hatena-bookmark--history))))

(provide 'consult-hatena-bookmark)

;;; consult-hatena-bookmark.el ends here
