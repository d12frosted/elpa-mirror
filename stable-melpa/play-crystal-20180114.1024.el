;;; play-crystal.el --- https://play.crystal-lang.org integration.

;; Copyright © 2018 Vitalii Elenhaupt <velenhaupt@gmail.com>
;; Author: Vitalii Elenhaupt
;; URL: https://github.com/veelenga/play-crystal.el
;; Package-Version: 20180114.1024
;; Package-Commit: 0b4810a9025213bd11dbcbfd38b3ca928829e0a5
;; Keywords: convenience
;; Package-Requires: ((emacs "24.4") (dash "2.12.0") (request "0.2.0"))

;; This file is not part of GNU Emacs.

;;; License:

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

;; https://play.crystal-lang.org/ is a web resource to submit/run/share Crystal code.
;; This package allows you to use this resource without exiting your favorite Emacs.

;; Usage:

;; Run one of the predefined interactive functions.
;;
;; Insert code identified by RUN-ID into the current buffer:
;;
;;    (play-crystal-insert RUN-ID)
;;
;; Insert code identified by RUN-ID into another buffer:
;;
;;    (play-crystal-insert-another-buffer RUN-ID)
;;
;; Show code identified by RUN-ID in a browser using ’browse-url’:
;;
;;    (play-crystal-browse RUN-ID)
;;
;; Create new run submitting code from the current region:
;;
;;    (play-crystal-submit-region)
;;
;; Create new run submitting code from the current buffer:
;;
;;    (play-crystal-submit-buffer)

;;; Code:

(require 'cl-lib)

(require 'json)
(require 'request)

(defgroup play-crystal nil
  "https://play.crystal-lang.org/ integration."
  :prefix "play-crystal-"
  :group 'applications)

(defconst play-crystal-version "0.1.2")
(defconst play-crystal-baseurl "https://play.crystal-lang.org")
(defconst play-crystal-runs-path "/runs")
(defconst play-crystal-runrequests-path "/run_requests")

(defvar play-crystal-buffer-name "*Play-Crystal*"
  "Buffer name for code insertions.")

(defvar play-crystal-debug-buffer-name "*Play-Crystal-Debug*"
  "Buffer name for responses from play.crystal-lang.org.")

(defconst play-crystal-default-headers
  '(("Accept" . "application/json")
    ("Content-Type" . "application/json; charset=UTF-8")
    ("User-Agent" . ,(format "play-crystal.el/%s" play-crystal-version))))

(cl-defun play-crystal--run-url (run)
  "An html url to the run identified by RUN-ID."
  (format "%s/#/r/%s" play-crystal-baseurl (play-crystal-run-id run)))

(cl-defun play-crystal--request
    (endpoint
     &key
     (type "GET")
     (params nil)
     (data nil)
     (parser 'json-read)
     (error nil)
     (success nil)
     (complete 'play-crystal--default-callback)
     (headers play-crystal-default-headers)
     (timeout nil)
     (sync nil)
     (status-code nil)
     (authorized nil))
  "Process a request to play.crystal-lang.org endpoint."
  (request (url-expand-file-name endpoint play-crystal-baseurl)
           :type type
           :data data
           :params params
           :headers headers
           :parser parser
           :success success
           :complete complete
           :error error
           :timeout timeout
           :status-code status-code
           :sync sync))

(cl-defun play-crystal--default-callback (&key data response error-thrown &allow-other-keys)
  (with-current-buffer (get-buffer-create play-crystal-debug-buffer-name)
    (let ((error-message (assoc-default 'message (assoc-default 'error data))))
      (if (not (s-blank-str? error-message))
          (message error-message)
        (and error-thrown (message (error-message-string error-thrown)))))
    (let ((inhibit-read-only t))
      (erase-buffer)
      (and (stringp data) (insert data))
      (let ((raw-header (request-response--raw-header response)))
        (unless (or (null raw-header) (s-blank-str? raw-header))
          (insert "\n" raw-header))))))

(cl-defstruct (play-crystal-run (:constructor play-crystal-run-new))
  "A structure holding the information about the run."
  id language version code exit-code created-at url html-url)

(cl-defun play-crystal--run (data)
  "Create a 'play-crystal-run' struct from api repsonse DATA."
  (let-alist (assoc-default 'run data)
    (play-crystal-run-new
     :id .id
     :language .language
     :version .version
     :code .code
     :exit-code .exit_code
     :created-at .created_at
     :url .url
     :html-url .html_url)))

(cl-defun play-crystal--chunk (data)
  "Pre-formatted play crystal code chunk."
  (let ((run (play-crystal--run data)))
    (concat
     (format "\n# URL: %s" (play-crystal--run-url run))
     (format "\n# Created at: %s" (play-crystal-run-created-at run))
     (format "\n# Language: %s" (play-crystal-run-language run))
     (format "\n# Version: %s" (play-crystal-run-version run))
     (format "\n# Exit code: %d" (play-crystal-run-exit-code run))
     (format "\n%s" (play-crystal-run-code run))
     (format "\n# End of run #%s" (play-crystal-run-id run)))))

(cl-defun play-crystal--read-run-id ()
  "Read run id."
  (list (read-string "Enter run id: ")))

(cl-defun play-crystal--run-path (run-id)
  "Return a path to the run."
  (format "%s/%s" play-crystal-runs-path run-id))

;;;###autoload
(defun play-crystal-insert (run-id)
  "Insert code identified by RUN-ID into the current buffer."
  (interactive (play-crystal--read-run-id))
  (play-crystal--request
   (play-crystal--run-path run-id)
   :success (cl-function
             (lambda (&key data &allow-other-keys)
               (insert (play-crystal--chunk data))))))

;;;###autoload
(defun play-crystal-insert-another-buffer (run-id)
  "Insert code identified by RUN-ID into another buffer."
  (interactive (play-crystal--read-run-id))
  (play-crystal--request
   (play-crystal--run-path run-id)
   :success (cl-function
             (lambda (&key data &allow-other-keys)
               (progn
                 (switch-to-buffer play-crystal-buffer-name)
                 (erase-buffer)
                 (when (fboundp 'crystal-mode) (crystal-mode))
                 (insert (play-crystal--chunk data)))))))

;;;###autoload
(defun play-crystal-browse (run-id)
  "Show code identified by RUN-ID in a browser using 'browse-url'."
  (interactive (play-crystal--read-run-id))
  (play-crystal--request
   (play-crystal--run-path run-id)
   :success (cl-function
             (lambda (&key data &allow-other-keys)
               (browse-url
                (play-crystal--run-url (play-crystal--run data)))))))

(defun play-crystal--kill-new-message (url)
  "Make URL the latest kill and print a message."
  (kill-new url)
  (message "%s" url))

(cl-defun play-crystal--create-hook (data)
  "After create hook."
  (let* ((run (play-crystal--run data))
         (url (play-crystal--run-url run)))
    (if (y-or-n-p "Code successfully submitted. Open in browser? ")
        (browse-url url)
      (play-crystal--kill-new-message url))))

(cl-defun play-crystal--create (code)
  "Create new run submitting crystal code."
  (play-crystal--request
   play-crystal-runrequests-path
   :type "POST"
   :data (json-encode `(("run_request" .(("language" . "crystal")
                                         ("code" . ,code)))))
   :success (cl-function
             (lambda (&key data &allow-other-keys)
               (play-crystal--create-hook (assoc-default 'run_request data))))))

(cl-defun play-crystal--region (&key
                                (beg (and (use-region-p) (region-beginning)))
                                (end (and (use-region-p) (region-end))))
  "Return code in current region."
  (buffer-substring-no-properties beg end))

;;;###autoload
(defun play-crystal-submit-region ()
  "Create new run submitting code from the current region."
  (interactive)
  (play-crystal--create (play-crystal--region)))

;;;###autoload
(defun play-crystal-submit-buffer ()
  "Create new run submitting code from the current buffer."
  (interactive)
  (play-crystal--create (play-crystal--region :beg (point-min) :end (point-max))))

(print (play-crystal--region :beg (point-min) :end (point-max)))

(provide 'play-crystal)
;;; play-crystal.el ends here
