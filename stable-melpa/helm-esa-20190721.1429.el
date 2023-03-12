;;; helm-esa.el --- Esa with helm interface -*- lexical-binding: t; -*-

;; Copyright (C) 2019 by Takashi Masuda

;; Author: Takashi Masuda <masutaka.net@gmail.com>
;; URL: https://github.com/masutaka/emacs-helm-esa
;; Package-Version: 20190721.1429
;; Package-Commit: d93b4af404346870cb2cf9c257d055332ef3f577
;; Version: 1.1.0
;; Package-Requires: ((emacs "26.2") (helm "3.2") (request "0.3.0"))

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
;; helm-esa.el provides a helm interface to esa (https://esa.io/).

;;; Code:

(require 'cl-lib)
(require 'helm)
(require 'json)
(require 'request)
(require 'subr-x)

(defgroup helm-esa nil
  "esa with helm interface"
  :prefix "helm-esa-"
  :group 'helm)

(defcustom helm-esa-team-name nil
  "A name of your esa team name."
  :type '(choice (const nil)
		 string)
  :group 'helm-esa)

(defcustom helm-esa-access-token nil
  "Your esa access token.
You can create on https://{team_name}.esa.io/user/applications
The required scope is `Read`."
  :type '(choice (const nil)
		 string)
  :group 'helm-esa)

(defcustom helm-esa-search-query "watched:true kind:stock"
  "Query for searching esa articles.
See https://docs.esa.io/posts/104"
  :type '(choice (const nil)
		 string)
  :group 'helm-esa)

(defcustom helm-esa-file
  (expand-file-name "helm-esa" user-emacs-directory)
  "A cache file search articles with `helm-esa-search-query'."
  :type '(choice (const nil)
		 string)
  :group 'helm-esa)

(defcustom helm-esa-candidate-number-limit 100
  "Candidate number limit."
  :type 'integer
  :group 'helm-esa)

(defcustom helm-esa-interval (* 1 60 60)
  "Number of seconds to call `helm-esa-http-request'."
  :type 'integer
  :group 'helm-esa)

;;; Internal Variables

(defvar helm-esa-api-per-page 100
  "Page size of esa API.
See https://docs.esa.io/posts/102")

(defconst helm-esa-http-buffer-name " *helm-esa-http*"
  "HTTP Working buffer name of `helm-esa-http-request'.")

(defconst helm-esa-work-buffer-name " *helm-esa-work*"
  "Working buffer name of `helm-esa-http-request'.")

(defvar helm-esa-full-frame helm-full-frame)

(defvar helm-esa-timer nil
  "Timer object for esa caching will be stored here.
DO NOT SET VALUE MANUALLY.")

(defvar helm-esa-debug-mode nil)
(defvar helm-esa-debug-start-time nil)

;;; Macro

(defmacro helm-esa-file-check (&rest body)
  "The BODY is evaluated only when `helm-esa-file' exists."
  `(if (file-exists-p helm-esa-file)
       ,@body
     (message "%s not found. Please wait up to %d minutes."
	      helm-esa-file (/ helm-esa-interval 60))))

;;; Helm source

(defun helm-esa-load ()
  "Load `helm-esa-file'."
  (helm-esa-file-check
   (with-current-buffer (helm-candidate-buffer 'global)
	(let ((coding-system-for-read 'utf-8))
	  (insert-file-contents helm-esa-file)))))

(defvar helm-esa-action
  '(("Browse URL" . helm-esa-browse-url)
    ("Show URL" . helm-esa-show-url)))

(defun helm-esa-browse-url (candidate)
  "Action for Browse URL.
Argument CANDIDATE a line string of an article."
  (string-match "\\[href:\\(.+\\)\\]" candidate)
  (browse-url (match-string 1 candidate)))

(defun helm-esa-show-url (candidate)
  "Action for Show URL.
Argument CANDIDATE a line string of a article."
  (string-match "\\[href:\\(.+\\)\\]" candidate)
  (message (match-string 1 candidate)))

(defvar helm-esa-source
  (helm-build-in-buffer-source "esa articles"
    :init #'helm-esa-load
    :action 'helm-esa-action
    :candidate-number-limit helm-esa-candidate-number-limit
    :multiline t
    :migemo t)
  "Helm source for esa.")

;;;###autoload
(defun helm-esa ()
  "Search esa articles using `helm'."
  (interactive)
  (let ((helm-full-frame helm-esa-full-frame))
    (helm-esa-file-check
     (helm :sources helm-esa-source
	   :prompt "Find esa articles: "))))

;;; Process handler

(defun helm-esa-http-request (&optional url)
  "Make a new HTTP request for create `helm-esa-file'.
Use `helm-esa-get-url' if URL is nil."
  (unless url ;; 1st page
    (if (get-buffer helm-esa-work-buffer-name)
	(kill-buffer helm-esa-work-buffer-name))
    (get-buffer-create helm-esa-work-buffer-name))
  (helm-esa-http-debug-start)
  (request
   (if url url (helm-esa-get-url))
   :headers `(("Authorization" . ,(concat "Bearer " helm-esa-access-token)))
   :parser 'json-read
   :success (cl-function
	     (lambda (&key data response &allow-other-keys)
	       (helm-esa-http-debug-finish-success (request-response-url response))
	       (let ((next-url))
		 (with-current-buffer (get-buffer helm-esa-work-buffer-name)
		   (goto-char (point-max))
		   (helm-esa-insert-articles data)
		   (setq next-url (helm-esa-next-url data))
		   (if next-url
		       (helm-esa-http-request next-url)
		     (write-region (point-min) (point-max) helm-esa-file))))))
   :error (cl-function
	   (lambda (&key error-thrown response &allow-other-keys)
	     (helm-esa-http-debug-finish-error (request-response-url response) error-thrown)))))

(defun helm-esa-get-url (&optional page)
  "Return esa API endpoint for searching articles.
PAGE is a natural number.  If it doesn't set, it equal to 1."
  (let ((url-query `((per_page ,helm-esa-api-per-page))))
    (if page
	(setq url-query (cons `(page ,page) url-query)))
    (if (>= (length helm-esa-search-query) 1)
	(setq url-query (cons `(q ,helm-esa-search-query) url-query)))
  (format "https://api.esa.io/v1/teams/%s/posts?%s"
	  helm-esa-team-name
	  (url-build-query-string url-query))))

(defun helm-esa-insert-articles (response-body)
  "Insert esa article as the format of `helm-esa-file'.
Argument RESPONSE-BODY is http response body as a json"
  (let ((articles (helm-esa-articles response-body))
	article format-wip category name format-tags url)
    (dotimes (i (length articles))
      (setq article (aref articles i)
	    format-wip (helm-esa-article-format-wip article)
	    category (helm-esa-article-category article)
	    name (helm-esa-article-name article)
	    format-tags (helm-esa-article-format-tags article)
	    url (helm-esa-article-url article))
      (insert
       (decode-coding-string
	(if category
	    (format "%s%s/%s %s [href:%s]\n" format-wip category name format-tags url)
	  (format "%s%s %s [href:%s]\n" format-wip name format-tags url))
	'utf-8)))))

(defun helm-esa-next-url (response-body)
  "Return the next page url from RESPONSE-BODY."
  (let ((next-page (helm-esa-next-page response-body)))
    (if next-page
	(helm-esa-get-url next-page))))

(defun helm-esa-next-page (response-body)
  "Return next page number from RESPONSE-BODY."
  (cdr (assoc 'next_page response-body)))

(defun helm-esa-articles (response-body)
  "Return articles from RESPONSE-BODY."
  (cdr (assoc 'posts response-body)))

(defun helm-esa-article-category (article)
  "Return a category of ARTICLE."
  (cdr (assoc 'category article)))

(defun helm-esa-article-format-wip (article)
  "Return if the ARTICLE is WIP."
  (if (eq (cdr (assoc 'wip article)) t)
      "[WIP] " ""))

(defun helm-esa-article-name (article)
  "Return a name of ARTICLE."
  (helm-esa-unescape
   (cdr (assoc 'name article))))

(defun helm-esa-unescape (str)
  "Unescape STR."
  (helm-esa-unescape-sharp
   (helm-esa-unescape-slash str)))

(defun helm-esa-unescape-sharp (str)
  "Unescape '&#35;' in STR to '#'."
  (if (string-match "&#35;" str)
      (replace-match "#" t t str)
    str))

(defun helm-esa-unescape-slash (str)
  "Unescape '&#47;' in STR to '/'."
  (if (string-match "&#47;" str)
      (replace-match "/" t t str)
    str))

(defun helm-esa-article-url (article)
  "Return a url of ARTICLE."
  (cdr (assoc 'url article)))

(defun helm-esa-article-format-tags (article)
  "Return formatted tags of ARTICLE."
  (let ((result ""))
    (mapc
     (lambda (tag)
       (setq result (concat result " #" tag)))
     (helm-esa-article-tags article))
    (string-trim result)))

(defun helm-esa-article-tags (article)
  "Return tags of ARTICLE, as an list."
  (append (cdr (assoc 'tags article)) nil))

;;; Debug

(defun helm-esa-http-debug-start ()
  "Start debug mode."
  (setq helm-esa-debug-start-time (current-time)))

(defun helm-esa-http-debug-finish-success (url)
  "Stop debug mode.
SYMBOL-STATUS is symbol.  e.g: success
URL is a request url."
  (if helm-esa-debug-mode
      (message "[esa] Succeed to GET %s (%0.1fsec) at %s."
	       url
	       (time-to-seconds
		(time-subtract (current-time)
			       helm-esa-debug-start-time))
	       (format-time-string "%Y-%m-%d %H:%M:%S" (current-time)))))

(defun helm-esa-http-debug-finish-error (url error-thrown)
  "Stop debug mode for error.
URL is a request url.
ERROR-THROWN is (ERROR-SYMBOL . DATA), or nil."
  (if helm-esa-debug-mode
      (message "[esa] Fail %S to GET %s (%0.1fsec) at %s."
	       error-thrown
	       url
	       (time-to-seconds
		(time-subtract (current-time)
			       helm-esa-debug-start-time))
	       (format-time-string "%Y-%m-%d %H:%M:%S" (current-time)))))

;;; Timer

(defun helm-esa-set-timer ()
  "Set timer."
  (setq helm-esa-timer
	(run-at-time "0 sec"
		     helm-esa-interval
		     #'helm-esa-http-request)))

(defun helm-esa-cancel-timer ()
  "Cancel timer."
  (when helm-esa-timer
    (cancel-timer helm-esa-timer)
    (setq helm-esa-timer nil)))

;;;###autoload
(defun helm-esa-initialize ()
  "Initialize `helm-esa'."
  (unless helm-esa-team-name
    (error "Variable `helm-esa-team-name' is nil"))
  (unless helm-esa-access-token
    (error "Variable `helm-esa-access-token' is nil"))
  (helm-esa-set-timer))

(provide 'helm-esa)

;;; helm-esa.el ends here
