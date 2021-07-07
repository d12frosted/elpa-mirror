;;; hound.el --- Display hound search results in a compilation window

;; Author: Ryan Young
;; Version: 1.2.1
;; Package-Version: 20200122.1700
;; Package-Commit: 35e2cdc81fcc904b450a7ef3ec00fd25df6a4431
;; Created: February 13, 2013
;; Package-Requires: ((request "0.2.0") (cl-lib "0.5"))

;;; Commentary:
;; Most of this is taken straight from ag.el, and then heavily modified to query a
;; running hound server instead of running ag to provide the search results.
;;
;; At a high level, this will send a query to the hound service api, parse the json
;; response, massage that data and dump it into a buffer, then apply a compilation
;; mode to the buffer that lets you jump directly to the search result files.


;;; License:

;; This file is not part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:
(require 'request)
(require 'cl-lib)
(require 'compile)
(require 'json)
(require 'url-util)

;;; ----------------------------------------------------------------------------
;;; ----- Customizable vars

(defcustom hound-reuse-window t
  "Non-nil means we open search results in the same window, hiding the results buffer."
  :type 'boolean
  :group 'hound)
(defcustom hound-host "http://localhost"
  "This is the hostname specifying where the hound server is running"
  :type 'string
  :safe 'string
  :group 'hound)

(defcustom hound-api-port "6080"
  "This is the port number of the hound service"
  :type 'string
  :safe 'string
  :group 'hound)
(defcustom hound-repo-substitution '()
  "list of (repo_name local_directory_name), in the event that your local checkout of the
repository is in a differently named directory"
  :group 'hound)
(defcustom hound-root-directory "~"
  "When in compilation mode, this path will set the root directory to look for the files in
so that we can locate and open the file."
  :type 'string
  :group 'hound)
(defface hound-hit-face '((t :inherit compilation-info))
  "Face name to use for hound matches."
  :group 'hound)

(defvar hound/most-recent-query "")

(put 'hound-host 'safe-local-variable #'stringp)
(put 'hound-api-port 'safe-local-variable #'stringp)

;;; ----------------------------------------------------------------------------
;;; ----- Public functions

;;;###autoload
(defun hound-link (query)
  (interactive (list (read-from-minibuffer "Search string: " (hound/dwim-at-point))))
  (message "%s" (hound/get-search-url query nil)))

;;;###autoload
(defun hound (query)
  (interactive (list (read-from-minibuffer "Search string: " (hound/dwim-at-point))))
  (setq hound/most-recent-query query)
  (request
   (hound/get-search-url query t)
   :parser 'json-read
   :error (cl-function (lambda (&rest args &key error-thrown &allow-other-keys)
                         (message "Got error: %S" error-thrown)))
   :success (cl-function
             (lambda (&key data &allow-other-keys) (hound/handle-http-response data)))))


;;; ----------------------------------------------------------------------------
;;; ----- HTTP request to grab search results

(defun hound/get-search-url (query api-p)
  (let* ((api-url (concat hound-host ":" hound-api-port "/api/v1/search?"))
         (web-url (concat hound-host "?"))
         (url (if api-p api-url web-url)))
    (concat url "&repos=*&q=" (url-hexify-string query) )))

(defun hound/dwim-at-point ()
  (cond ((use-region-p)
         (buffer-substring-no-properties (region-beginning) (region-end)))
        ((symbol-at-point)
         (substring-no-properties
          (symbol-name (symbol-at-point))))))

(defun hound/json-process-individual-repository (repo)
  (let ((repo-name (symbol-name (car repo)))
        (file-matches (cdr (assq 'Matches repo))))
    (mapc
     (lambda (file-match) (hound/json-process-file-match file-match repo-name))
     file-matches)))

(defun hound/json-process-file-match (file-match repo-name)
  (let ((filename (cdr (assq 'Filename file-match)))
        (line-matches (cdr (assq 'Matches file-match))))
    (mapc
     (lambda (line-match)
       (let* ((linenumber (cdr (assq 'LineNumber line-match)))
              (text (cdr (assq 'Line line-match))))
         (insert (hound/match-to-string repo-name filename linenumber text))
         (newline)))
     line-matches)))

(defun hound/handle-http-response (response)
  (kill-buffer (get-buffer-create "*hound search*"))
  (with-current-buffer (get-buffer-create "*hound search*")
    (insert (format "Hound Results for %s:\n%s\n\n" hound/most-recent-query (hound/get-search-url hound/most-recent-query nil)))
    (mapc 'hound/json-process-individual-repository (cdr (assq 'Results response)))
    (goto-char (point-min))
    (hound-mode)
    (highlight-phrase hound/most-recent-query 'hound-match-face))
  (switch-to-buffer "*hound search*")
  (message "hound search complete"))


;;; ----------------------------------------------------------------------------
;;; ----- Dumping results into the search results buffer

(defun hound/replace-repo-name (repo)
  (let* ((new-repo (cadr (assoc repo hound-repo-substitution))))
    (if new-repo new-repo repo)))
(defun hound/match-to-string (repo filename linenum text)
  (format "%s/%s [Line %d] %s" (hound/replace-repo-name repo) filename linenum text))


;;; ----------------------------------------------------------------------------
;;; ----- Compilation mode setup

;; much of this taken from ag.el
(defmacro hound/with-patch-function (fun-name fun-args fun-body &rest body)
  "Temporarily override the definition of FUN-NAME whilst BODY is executed.
Assumes FUNCTION is already defined (see http://emacs.stackexchange.com/a/3452/304)."
  `(cl-letf (((symbol-function ,fun-name)
              (lambda ,fun-args ,fun-body)))
     ,@body))

(defun hound/next-error-function (n &optional reset)
  "Open the search result at point in the current window or a different window, according to `hound-reuse-window'."
  (if hound-reuse-window
      ;; prevent changing the window
      (hound/with-patch-function
       'pop-to-buffer (buffer &rest args) (switch-to-buffer buffer)
       (compilation-next-error-function n reset))

    ;; just navigate to the results as normal
    (compilation-next-error-function n reset)))

(define-compilation-mode hound-mode "Hound"
  "Hound results compilation mode"
  (let ((smbl  'compilation-hound-nogroup)
        (pttrn '("^\\(.*\\) \\[Line \\([1-9][0-9]*\\)\\] \\(.*\\)" 1 2)))
    (set (make-local-variable 'compilation-error-regexp-alist) (list smbl))
    (set (make-local-variable 'compilation-error-regexp-alist-alist) (list (cons smbl pttrn))))
  (set (make-local-variable 'compilation-error-face) 'hound-hit-face)
  (set (make-local-variable 'next-error-function) 'hound/next-error-function)
  (set (make-local-variable 'default-directory) hound-root-directory))

(define-key hound-mode-map (kbd "p") 'compilation-previous-error)
(define-key hound-mode-map (kbd "n") 'compilation-next-error)


(provide 'hound)

;;; hound.el ends here
