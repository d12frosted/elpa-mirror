;;; helm-hatena-bookmark.el --- Hatena::Bookmark with helm interface -*- lexical-binding: t; -*-

;; Copyright (C) 2016 by Takashi Masuda

;; Author: Takashi Masuda <masutaka.net@gmail.com>
;; URL: https://github.com/masutaka/emacs-helm-hatena-bookmark
;; Package-Version: 20210724.732
;; Package-Commit: a6a2b37370ac84ca2cae5ef65b2b144a010b1584
;; Version: 2.4.4
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
;; helm-hatena-bookmark.el provides a helm interface to Hatena::Bookmark.

;;; Code:

(require 'helm)

(defgroup helm-hatena-bookmark nil
  "Hatena::Bookmark with helm interface"
  :prefix "helm-hatena-bookmark-"
  :group 'helm)

(define-obsolete-variable-alias 'helm-hatena-bookmark:username
  'helm-hatena-bookmark-username "2.2.0")

(defcustom helm-hatena-bookmark-username nil
  "A username of your Hatena account."
  :type '(choice (const nil)
		 string)
  :group 'helm-hatena-bookmark)

(defcustom helm-hatena-bookmark-file
  (expand-file-name "helm-hatena-bookmark" user-emacs-directory)
  "A cache file of your Hatena::Bookmark."
  :type '(choice (const nil)
		 string)
  :group 'helm-hatena-bookmark)

(defcustom helm-hatena-bookmark-candidate-number-limit 100
  "Candidate number limit."
  :type 'integer
  :group 'helm-hatena-bookmark)

(define-obsolete-variable-alias 'helm-hatena-bookmark:interval
  'helm-hatena-bookmark-interval "2.2.0")

(defcustom helm-hatena-bookmark-interval (* 1 60 60)
  "Number of seconds to call `helm-hatena-bookmark-http-request'."
  :type 'integer
  :group 'helm-hatena-bookmark)

;;; Internal Variables

(defvar helm-hatena-bookmark-url nil
  "Cache a result of `helm-hatena-bookmark-get-url'.
DO NOT SET VALUE MANUALLY.")

(defvar helm-hatena-bookmark-curl-program nil
  "Cache a result of `helm-hatena-bookmark-find-curl-program'.
DO NOT SET VALUE MANUALLY.")

(defvar helm-hatena-bookmark-sed-program nil
  "Cache a result of `helm-hatena-bookmark-find-sed-program'.
DO NOT SET VALUE MANUALLY.")

(defconst helm-hatena-bookmark-http-buffer-name " *helm-hatena-bookmark*"
  "Working buffer name of `helm-hatena-bookmark-http-request'.")

(defvar helm-hatena-bookmark-full-frame helm-full-frame)

(defvar helm-hatena-bookmark-timer nil
  "Timer object for Hatena::Bookmark caching will be stored here.
DO NOT SET VALUE MANUALLY.")

(defvar helm-hatena-bookmark-debug-mode nil)
(defvar helm-hatena-bookmark-http-debug-start-time nil)
(defvar helm-hatena-bookmark-filter-debug-start-time nil)

;;; Macro

(defmacro helm-hatena-bookmark-file-check (&rest body)
  "The BODY is evaluated only when `helm-hatena-bookmark-file' exists."
  `(if (file-exists-p helm-hatena-bookmark-file)
       ,@body
     (message "%s not found. Please wait up to %d minutes."
	      helm-hatena-bookmark-file (/ helm-hatena-bookmark-interval 60))))

;;; Helm source

(defun helm-hatena-bookmark-load ()
  "Load `helm-hatena-bookmark-file'."
  (helm-hatena-bookmark-file-check
   (with-current-buffer (helm-candidate-buffer 'global)
     (let ((coding-system-for-read 'utf-8))
       (insert-file-contents helm-hatena-bookmark-file)))))

(defvar helm-hatena-bookmark-action
  '(("Browse URL" . helm-hatena-bookmark-browse-url)
    ("Show URL" . helm-hatena-bookmark-show-url)
    ("Show Summary" . helm-hatena-bookmark-show-summary)))

(defun helm-hatena-bookmark-browse-url (candidate)
  "Action for Browse URL.
Argument CANDIDATE a line string of a bookmark."
  (string-match "\\[href:\\(.+\\)\\]$" candidate)
  (browse-url (match-string 1 candidate)))

(defun helm-hatena-bookmark-show-url (candidate)
  "Action for Show URL.
Argument CANDIDATE a line string of a bookmark."
  (string-match "\\[href:\\(.+\\)\\]$" candidate)
  (message (match-string 1 candidate)))

(defun helm-hatena-bookmark-show-summary (candidate)
  "Action for Show Summary.
Argument CANDIDATE a line string of a bookmark."
  (string-match "\\[summary:\\(.+\\)\\]\\[" candidate)
  (message (match-string 1 candidate)))

(define-obsolete-variable-alias 'helm-hatena-bookmark:source
  'helm-hatena-bookmark-source "2.2.0")

(defvar helm-hatena-bookmark-source
  (helm-build-in-buffer-source "Hatena:Bookmark"
    :init 'helm-hatena-bookmark-load
    :action 'helm-hatena-bookmark-action
    :candidate-number-limit helm-hatena-bookmark-candidate-number-limit
    :multiline t
    :migemo t)
  "Helm source for Hatena::Bookmark.")

;;;###autoload
(defun helm-hatena-bookmark ()
  "Search Hatena::Bookmark using `helm'."
  (interactive)
  (let ((helm-full-frame helm-hatena-bookmark-full-frame))
    (helm-hatena-bookmark-file-check
     (helm :sources helm-hatena-bookmark-source
	   :prompt "Find Bookmark: "))))

;;; Process handler

(defun helm-hatena-bookmark-http-request ()
  "Make a new HTTP request for create `helm-hatena-bookmark-file'."
  (let ((buffer-name helm-hatena-bookmark-http-buffer-name)
	(proc-name "helm-hatena-bookmark")
	(curl-args `("--include" "--compressed" ,helm-hatena-bookmark-url))
	proc)
    (unless (get-buffer-process buffer-name)
      (helm-hatena-bookmark-http-debug-start)
      (setq proc (apply 'start-process
			proc-name
			buffer-name
			helm-hatena-bookmark-curl-program
			curl-args))
      (set-process-sentinel proc 'helm-hatena-bookmark-http-request-sentinel))))

(defun helm-hatena-bookmark-http-request-sentinel (process _event)
  "Handle a response of `helm-hatena-bookmark-http-request'.
Argument PROCESS is a http-request process.
Argument _EVENT is a string describing the type of event."
  (let ((buffer-name helm-hatena-bookmark-http-buffer-name))
    (condition-case nil
	(with-current-buffer (get-buffer buffer-name)
	  (unless (helm-hatena-bookmark-valid-http-responsep process)
	    (error "Invalid http response"))
	  (unless (helm-hatena-bookmark-filter-http-response)
	    (error "Fail to filter http response"))
	  (write-region (point-min) (point-max) helm-hatena-bookmark-file))
      (error nil))
    (kill-buffer buffer-name)))

(defun helm-hatena-bookmark-valid-http-responsep (process)
  "Return if the http response is valid.
Argument PROCESS is a http-request process.
Should to call in `helm-hatena-bookmark-http-buffer-name'."
  (save-excursion
    (let ((result))
      (goto-char (point-min))
      (setq result (re-search-forward
		    (concat "^" (regexp-quote "HTTP/2 200")) (point-at-eol) t))
      (helm-hatena-bookmark-http-debug-finish result process)
      result)))

(defun helm-hatena-bookmark-filter-http-response ()
  "Filter a response of `helm-hatena-bookmark-http-request'."
  (let ((sed-args '("-n" "N; N; s/\\(.*\\)\\n\\(\\[.*\\]\\)\\?\\(.*\\)\\n\\(http.*\\)/\\2 \\1 [summary:\\3][href:\\4]/p"))
	result)
    (helm-hatena-bookmark-filter-debug-start)
    (delete-region (point-min) (+ (helm-hatena-bookmark-point-of-separator) 1))
    (apply 'call-process-region
	   (point-min) (point-max)
	   helm-hatena-bookmark-sed-program t '(t nil) nil
	   sed-args)
    (setq result (> (point-max) (point-min)))
    (helm-hatena-bookmark-filter-debug-finish result)
    result))

(defun helm-hatena-bookmark-point-of-separator ()
  "Return point between header and body of the http response, as an integer."
  (save-excursion
    (goto-char (point-min))
    (re-search-forward "^?$" nil t)))

;;; Debug

(defsubst helm-hatena-bookmark-time-subtract-to-seconds (t1 t2)
  "Subtract two time values, T1 minus T2.
Return the seconds format."
  (time-to-seconds (time-subtract t1 t2)))

(defsubst helm-hatena-bookmark-format-time-string (time)
  "Return time string of TIME with fixed format."
  (format-time-string "%Y-%m-%d %H:%M:%S" time))

(defun helm-hatena-bookmark-http-debug-start ()
  "Start http debug mode."
  (setq helm-hatena-bookmark-http-debug-start-time (current-time)))

(defun helm-hatena-bookmark-http-debug-finish (result process)
  "Stop http debug mode.
RESULT is boolean.
PROCESS is a http-request process."
  (if helm-hatena-bookmark-debug-mode
      (message "[B!] %s to GET %s (%0.1fsec) at %s."
	       (if result "Success" "Failure")
	       (car (last (process-command process)))
	       (helm-hatena-bookmark-time-subtract-to-seconds
		(current-time) helm-hatena-bookmark-http-debug-start-time)
	       (helm-hatena-bookmark-format-time-string (current-time)))))

(defun helm-hatena-bookmark-filter-debug-start ()
  "Start filter debug mode."
  (setq helm-hatena-bookmark-filter-debug-start-time (current-time)))

(defun helm-hatena-bookmark-filter-debug-finish (result)
  "Stop filter debug mode.
RESULT is boolean."
  (if helm-hatena-bookmark-debug-mode
      (message "[B!] %s to filter the http response (%dbytes, %0.1fsec) at %s."
	       (if result "Success" "Failure")
	       (- (point-max) (point-min))
	       (helm-hatena-bookmark-time-subtract-to-seconds
		(current-time) helm-hatena-bookmark-filter-debug-start-time)
	       (helm-hatena-bookmark-format-time-string (current-time)))))

;;; Timer

(defun helm-hatena-bookmark-set-timer ()
  "Set timer."
  (setq helm-hatena-bookmark-timer
	(run-at-time "0 sec"
		     helm-hatena-bookmark-interval
		     #'helm-hatena-bookmark-http-request)))

(defun helm-hatena-bookmark-cancel-timer ()
  "Cancel timer."
  (when helm-hatena-bookmark-timer
    (cancel-timer helm-hatena-bookmark-timer)
    (setq helm-hatena-bookmark-timer nil)))

;;;###autoload
(defun helm-hatena-bookmark-initialize ()
  "Initialize `helm-hatena-bookmark'."
  (setq helm-hatena-bookmark-url
	(helm-hatena-bookmark-get-url))
  (setq helm-hatena-bookmark-curl-program
	(helm-hatena-bookmark-find-curl-program))
  (setq helm-hatena-bookmark-sed-program
	(helm-hatena-bookmark-find-sed-program))
  (helm-hatena-bookmark-set-timer))

(define-obsolete-function-alias 'helm-hatena-bookmark:initialize
  'helm-hatena-bookmark-initialize "2.2.0")

(defun helm-hatena-bookmark-get-url ()
  "Return Hatena::Bookmark URL or error if `helm-hatena-bookmark-username' is nil."
  (unless helm-hatena-bookmark-username
    (error "Variable `helm-hatena-bookmark-username' is nil"))
  (format "https://b.hatena.ne.jp/%s/search.data"
	  helm-hatena-bookmark-username))

(defun helm-hatena-bookmark-find-curl-program ()
  "Return an appropriate `curl' program pathname or error if not found."
  (or
   (executable-find "curl")
   (error "Cannot find `curl' helm-hatena-bookmark.el requires")))

(defun helm-hatena-bookmark-find-sed-program ()
  "Return an appropriate `sed' program pathname or error if not found."
  (executable-find
   (cond
    ((eq system-type 'darwin)
     (unless (executable-find "gsed")
       (error "Cannot find `gsed' helm-hatena-bookmark.el requires.  (example `$ brew install gnu-sed')"))
     "gsed")
    (t
     "sed"))))

(provide 'helm-hatena-bookmark)

;;; helm-hatena-bookmark.el ends here
