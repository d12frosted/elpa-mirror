;;; ob-git-permalink.el --- Import GitHub code given a permalink -*- lexical-binding: t -*-

;; Copyright (C) 2022 kijima Daigo

;; Author: kijima Daigo <norimaking777@gmail.com>
;; Version: 0.1.0
;; Package-Version: 20220627.46
;; Package-Commit: 14224327a6b34c804b0e90d37b80630a80c56c0a
;; Keywords: docs convenience
;; Package-Requires: ((emacs "25.1"))
;; URL: https://github.com/kijimaD/ob-git-permalink

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

;; Import GitHub code given a permalink.

;; #+begin_src git-permalink
;; https://github.com/emacs-mirror/emacs/blob/a4dcc8b9a94466c792be3743760a4a45cf6e1e61/lisp/emacs-lisp/ring.el#L48-L52
;; #+end_src

;; ↓ evaluate(C-c)

;; (defun ring-p (x)
;;   "Return t if X is a ring; nil otherwise."
;;   (and (consp x) (integerp (car x))
;;        (consp (cdr x)) (integerp (cadr x))
;;        (vectorp (cddr x))))

;;; Code:
(require 'ob)

(add-to-list 'org-babel-tangle-lang-exts '("git-permalink"))

(defun ob-git-permalink-parser-github (url)
  "Parse GitHub URL and return result hash."
  (let* ((hash (make-hash-table)))
    (string-match "http[s]?://github.com/\\(.*?\\)/\\(.*?\\)/blob/\\(.*?\\)/\\(.*\\)#L\\(.*?\\)\\(?:-L\\(.*?\\)\\)?$" url)
    (puthash 'user (match-string 1 url) hash)
    (puthash 'repo (match-string 2 url) hash)
    (puthash 'githash (match-string 3 url) hash)
    (puthash 'path (match-string 4 url) hash)
    (puthash 'start (string-to-number (match-string 5 url)) hash)
    (puthash 'end (if (match-string 6 url)
                      (string-to-number (match-string 6 url))
                    nil) hash)
    hash))

(defun ob-git-permalink-parser (url)
  "Choose parser by URL."
  (cond ((string-match-p "^http[s]?://github.com" url) 'ob-git-permalink-parser-github)
        (t (error "Not found parser"))))

(defun ob-git-permalink-build-link (hash-table)
  "Build link with HASH-TABLE."
  (when (not (hash-table-p hash-table))
    (error "Argument Error: HASH is not hash table"))
  (let* ((user (gethash 'user hash-table))
         (repo (gethash 'repo hash-table))
         (githash (gethash 'githash hash-table))
         (path (gethash 'path hash-table)))
    (format "https://raw.githubusercontent.com/%s/%s/%s/%s" user repo githash path)))

(defun ob-git-permalink-request (url start end)
  "Get code from raw file URL and trim between START and END."
  (let* ((lines)
         (current-line start)
         (buffer (url-retrieve-synchronously url)))
    (with-current-buffer buffer
      ;; remove request header
      (goto-char (point-min))
      (re-search-forward "^$")
      (delete-region (point) (point-min))
      (kill-line)

      ;; trim line
      (forward-line (- current-line 1))
      (push (buffer-substring-no-properties (line-beginning-position) (line-end-position)) lines)
      (forward-line 1)
      (when end
        (while (< (line-number-at-pos) (+ end 1))
          (progn
            (push (buffer-substring-no-properties (line-beginning-position) (line-end-position)) lines)
            (forward-line 1)))))
    (mapconcat (function (lambda (s) (format "%s" s)))
               (reverse lines)
               "\n")))

(defun ob-git-permalink-get-code (url)
  "Get code by URL."
  (let* ((parser (ob-git-permalink-parser url))
         (hash-table (funcall parser url))
         (request-url (ob-git-permalink-build-link hash-table))
         (start (gethash 'start hash-table))
         (end (if (gethash 'start hash-table)
                   (gethash 'end hash-table)
                 start)))
    (ob-git-permalink-request request-url start end)))

;;;###autoload
(defun org-babel-execute:git-permalink (body params)
  "Resolve BODY permalink and insert source code.
If PARAMS url is specified, the parameter is used."
  (let* ((params-url (cdr (assq :url params)))
         (url (if params-url
                  params-url
                body))
         (code (ob-git-permalink-get-code url)))
    (with-temp-buffer
      (insert code)
      (buffer-substring (point-min) (point-max)))))

(provide 'ob-git-permalink)
;;; ob-git-permalink.el ends here
