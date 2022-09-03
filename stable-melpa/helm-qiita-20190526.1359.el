;;; helm-qiita.el --- Qiita with helm interface -*- lexical-binding: t; -*-

;; Copyright (C) 2016 by Takashi Masuda

;; Author: Takashi Masuda <masutaka.net@gmail.com>
;; URL: https://github.com/masutaka/emacs-helm-qiita
;; Version: 1.1.3
;; Package-Requires: ((emacs "24") (helm "2.8.2"))

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
;; helm-qiita.el provides a helm interface to Qiita.

;;; Code:

(require 'helm)
(require 'json)

(defgroup helm-qiita nil
  "Qiita with helm interface"
  :prefix "helm-qiita-"
  :group 'helm)

(defcustom helm-qiita-username nil
  "A username of your Qiita account."
  :type '(choice (const nil)
		 string)
  :group 'helm-qiita)

(defcustom helm-qiita-organization nil
  "A name of your Qiita organization."
  :type '(choice (const nil)
		 string)
  :group 'helm-qiita)

(defcustom helm-qiita-access-token nil
  "Your Qiita access token.
You can create on https://qiita.com/settings/applications
The required scope is `read_qiita`.
Also add `read_qiita_team` in the case of Qiita:Team."
  :type '(choice (const nil)
		 string)
  :group 'helm-qiita)

(defcustom helm-qiita-file
  (expand-file-name "helm-qiita" user-emacs-directory)
  "A cache file of your Qiita Stocks."
  :type '(choice (const nil)
		 string)
  :group 'helm-qiita)

(defcustom helm-qiita-candidate-number-limit 100
  "Candidate number limit."
  :type 'integer
  :group 'helm-qiita)

(defcustom helm-qiita-interval (* 1 60 60)
  "Number of seconds to call `helm-qiita-http-request'."
  :type 'integer
  :group 'helm-qiita)

;;; Internal Variables

(defvar helm-qiita-url nil
  "Cache a result of `helm-qiita-get-url'.
DO NOT SET VALUE MANUALLY.")

(defvar helm-qiita-api-per-page 100
  "Page size of Qiita API.
See https://qiita.com/api/v2/docs")

(defvar helm-qiita-curl-program nil
  "Cache a result of `helm-qiita-find-curl-program'.
DO NOT SET VALUE MANUALLY.")

(defconst helm-qiita-http-buffer-name " *helm-qiita-http*"
  "HTTP Working buffer name of `helm-qiita-http-request'.")

(defconst helm-qiita-work-buffer-name " *helm-qiita-work*"
  "Working buffer name of `helm-qiita-http-request'.")

(defvar helm-qiita-full-frame helm-full-frame)

(defvar helm-qiita-timer nil
  "Timer object for Qiita caching will be stored here.
DO NOT SET VALUE MANUALLY.")

(defvar helm-qiita-debug-mode nil)
(defvar helm-qiita-debug-start-time nil)

;;; Macro

(defmacro helm-qiita-file-check (&rest body)
  "The BODY is evaluated only when `helm-qiita-file' exists."
  `(if (file-exists-p helm-qiita-file)
       ,@body
     (message "%s not found. Please wait up to %d minutes."
	      helm-qiita-file (/ helm-qiita-interval 60))))

;;; Helm source

(defun helm-qiita-load ()
  "Load `helm-qiita-file'."
  (helm-qiita-file-check
   (with-current-buffer (helm-candidate-buffer 'global)
	(let ((coding-system-for-read 'utf-8))
	  (insert-file-contents helm-qiita-file)))))

(defvar helm-qiita-action
  '(("Browse URL" . helm-qiita-browse-url)
    ("Show URL" . helm-qiita-show-url)))

(defun helm-qiita-browse-url (candidate)
  "Action for Browse URL.
Argument CANDIDATE a line string of a stock."
  (string-match "\\[href:\\(.+\\)\\]" candidate)
  (browse-url (match-string 1 candidate)))

(defun helm-qiita-show-url (candidate)
  "Action for Show URL.
Argument CANDIDATE a line string of a stock."
  (string-match "\\[href:\\(.+\\)\\]" candidate)
  (message (match-string 1 candidate)))

(defvar helm-qiita-source
  (helm-build-in-buffer-source "Qiita stocks"
    :init 'helm-qiita-load
    :action 'helm-qiita-action
    :candidate-number-limit helm-qiita-candidate-number-limit
    :multiline t
    :migemo t)
  "Helm source for Qiita.")

;;;###autoload
(defun helm-qiita ()
  "Search Qiita Stocks using `helm'."
  (interactive)
  (let ((helm-full-frame helm-qiita-full-frame))
    (helm-qiita-file-check
     (helm :sources helm-qiita-source
	   :prompt "Find Qiita Stocks: "))))

;;; Process handler

(defun helm-qiita-http-request (&optional url)
  "Make a new HTTP request for create `helm-qiita-file'.
Use `helm-qiita-url' if URL is nil."
  (let ((http-buffer-name helm-qiita-http-buffer-name)
	(work-buffer-name helm-qiita-work-buffer-name)
	(proc-name "helm-qiita")
	(curl-args `("--include" "-X" "GET" "--compressed"
		     "--header" ,(concat "Authorization: Bearer " helm-qiita-access-token)
		     ,(if url url helm-qiita-url)))
	proc)
    (unless (get-buffer-process http-buffer-name)
      (unless url ;; 1st page
	(if (get-buffer work-buffer-name)
	    (kill-buffer work-buffer-name))
	(get-buffer-create work-buffer-name))
      (helm-qiita-http-debug-start)
      (setq proc (apply 'start-process
			proc-name
			http-buffer-name
			helm-qiita-curl-program
			curl-args))
      (set-process-sentinel proc 'helm-qiita-http-request-sentinel))))

(defun helm-qiita-http-request-sentinel (process _event)
  "Handle a response of `helm-qiita-http-request'.
PROCESS is a http-request process.
_EVENT is a string describing the type of event.
If next-link is exist, requests it.
If the response is invalid, stops to request."
  (let ((http-buffer-name helm-qiita-http-buffer-name))
    (condition-case nil
	(let (response-body next-link)
	  (with-current-buffer (get-buffer http-buffer-name)
	    (unless (helm-qiita-valid-http-responsep process)
	      (error "Invalid http response"))
	    (setq next-link (helm-qiita-next-link))
	    (setq response-body (helm-qiita-response-body)))
	  (kill-buffer http-buffer-name)
	  (with-current-buffer (get-buffer helm-qiita-work-buffer-name)
	    (goto-char (point-max))
	    (helm-qiita-insert-stocks response-body)
	    (if next-link
		(helm-qiita-http-request next-link)
	      (write-region (point-min) (point-max) helm-qiita-file))))
      (error
       (kill-buffer http-buffer-name)))))

(defun helm-qiita-valid-http-responsep (process)
  "Return if the http response is valid.
Argument PROCESS is a http-request process.
Should to call in `helm-qiita-http-buffer-name'."
  (save-excursion
    (let ((result))
      (goto-char (point-min))
      (setq result (re-search-forward "^HTTP/2 200" (point-at-eol) t))
      (helm-qiita-http-debug-finish result process)
      result)))

(defun helm-qiita-next-link ()
  "Return the next link the http response has."
  (save-excursion
    (let ((field-body))
      (goto-char (point-min))
      (when (re-search-forward "^Link: " (helm-qiita-point-of-separator) t)
	(setq field-body (buffer-substring-no-properties (point) (point-at-eol)))
	(cond
	 ((string-match "^<\\(https://.*\\)>; rel=\"first\", <\\(https://.*\\)>; rel=\"prev\", <\\(https://.*\\)>; rel=\"next\"" field-body)
	  (match-string 3 field-body))
	 ((string-match "^<\\(https://.*\\)>; rel=\"first\", <\\(https://.*\\)>; rel=\"next\"" field-body)
	  (match-string 2 field-body)))))))

(defun helm-qiita-point-of-separator ()
  "Return point between header and body of the http response, as an integer."
  (save-excursion
    (goto-char (point-min))
    (re-search-forward "^?$" nil t)))

(defun helm-qiita-response-body ()
  "Read http response body as a json.
Should to call in `helm-qiita-http-buffer-name'."
  (json-read-from-string
   (buffer-substring-no-properties
    (+ (helm-qiita-point-of-separator) 1) (point-max))))

(defun helm-qiita-insert-stocks (response-body)
  "Insert Qiita stock as the format of `helm-qiita-file'.
Argument RESPONSE-BODY is http response body as a json"
  (let ((stock))
    (dotimes (i (length response-body))
      (setq stock (aref response-body i))
      (insert (format "%s %s [href:%s]\n"
		      (helm-qiita-stock-title stock)
		      (helm-qiita-stock-format-tags stock)
		      (helm-qiita-stock-url stock))))))

(defun helm-qiita-stock-title (stock)
  "Return a title of STOCK."
  (cdr (assoc 'title stock)))

(defun helm-qiita-stock-url (stock)
  "Return a url of STOCK."
  (cdr (assoc 'url stock)))

(defun helm-qiita-stock-format-tags (stock)
  "Return formatted tags of STOCK."
  (let ((result ""))
    (mapc
     (lambda (tag)
       (setq result (format "%s[%s]" result tag)))
     (helm-qiita-stock-tags stock))
    result))

(defun helm-qiita-stock-tags (stock)
  "Return tags of STOCK, as an list."
  (let ((tags (cdr (assoc 'tags stock))) result)
    (dotimes (i (length tags))
      (setq result (cons (cdr (assoc 'name (aref tags i))) result)))
    (reverse result)))

;;; Debug

(defun helm-qiita-http-debug-start ()
  "Start debug mode."
  (setq helm-qiita-debug-start-time (current-time)))

(defun helm-qiita-http-debug-finish (result process)
  "Stop debug mode.
RESULT is boolean.
PROCESS is a http-request process."
  (if helm-qiita-debug-mode
      (message "[Q] %s to GET %s (%0.1fsec) at %s."
	       (if result "Success" "Failure")
	       (car (last (process-command process)))
	       (time-to-seconds
		(time-subtract (current-time)
			       helm-qiita-debug-start-time))
	       (format-time-string "%Y-%m-%d %H:%M:%S" (current-time)))))

;;; Timer

(defun helm-qiita-set-timer ()
  "Set timer."
  (setq helm-qiita-timer
	(run-at-time "0 sec"
		     helm-qiita-interval
		     #'helm-qiita-http-request)))

(defun helm-qiita-cancel-timer ()
  "Cancel timer."
  (when helm-qiita-timer
    (cancel-timer helm-qiita-timer)
    (setq helm-qiita-timer nil)))

;;;###autoload
(defun helm-qiita-initialize ()
  "Initialize `helm-qiita'."
  (setq helm-qiita-url
	(helm-qiita-get-url))
  (unless helm-qiita-access-token
    (error "Variable `helm-qiita-access-token' is nil"))
  (setq helm-qiita-curl-program
	(helm-qiita-find-curl-program))
  (helm-qiita-set-timer))

(defun helm-qiita-get-url ()
  "Return Qiita URL or error if `helm-qiita-username' is nil."
  (unless helm-qiita-username
    (error "Variable `helm-qiita-username' is nil"))
  (format "https://%s/api/v2/users/%s/stocks?page=1&per_page=%d"
	  (if (stringp helm-qiita-organization)
	      (concat helm-qiita-organization ".qiita.com")
	    "qiita.com")
	  helm-qiita-username
	  helm-qiita-api-per-page))

(defun helm-qiita-find-curl-program ()
  "Return an appropriate `curl' program pathname or error if not found."
  (or
   (executable-find "curl")
   (error "Cannot find `curl' helm-qiita.el requires")))

(provide 'helm-qiita)

;;; helm-qiita.el ends here
