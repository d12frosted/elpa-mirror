;;; smmry.el --- SMMRY client

;; Copyright (C) 2016 james sangho nah <microamp@protonmail.com>
;;
;; Author: james sangho nah <microamp@protonmail.com>
;; Version: 0.0.3
;; Package-Version: 20161024.901
;; Package-Commit: 986a1b0aec8ab1ef17dbfb7886f47e5558cf738a
;; Keywords: api smmry
;; Homepage: https://github.com/microamp/smmry.el

;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation, either version 3 of the License, or (at your option) any later
;; version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.

;; You should have received a copy of the GNU General Public License along with
;; this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; SMMRY client

;;; Code:

(require 'json)
(require 'url)

(defgroup smmry nil
  "SMRRY client"
  :group 'convenience)

(defcustom smmry-base-url "http://api.smmry.com/"
  "SMMRY base URL."
  :type 'string
  :group 'smmry)

(defcustom smmry-env-api-key "SMMRY_API_KEY"
  "Environment to fetch SMMRY API key from."
  :type 'string
  :group 'smmry)

(defcustom smmry-length 5
  "Default SMMRY length."
  :type 'integer
  :group 'smmry)

(defvar smmry-api-key nil)

(defvar smmry-response-title "sm_api_title")
(defvar smmry-response-content "sm_api_content")
(defvar smmry-response-char-count "sm_api_character_count")
(defvar smmry-response-limitation "sm_api_limitation")

(defvar smmry-response-error "sm_api_error")
(defvar smmry-response-message "sm_api_message")

(defvar smmry-request-input "sm_api_input")

(defun smmry--build-url (api-key &optional url)
  (let ((smmry-url (format "%s&SM_API_KEY=%s&SM_LENGTH=%d"
                           smmry-base-url
                           api-key
                           smmry-length)))
    (if url (format "%s&SM_URL=%s" smmry-url url)
      smmry-url)))

(defun smmry--erroredp (jsonified)
  (let ((error-code (gethash smmry-response-error jsonified)))
    (integerp error-code)))

(defun smmry--build-error-message (jsonified)
  (format "%s %d: %s"
          "*smmry error*"
          (gethash smmry-response-error jsonified)
          (gethash smmry-response-message jsonified)))

(defun smmry--build-buffer-name (jsonified)
  (format "%s %s (%s characters): %s"
          "*smmry response*"
          (gethash smmry-response-title jsonified)
          (gethash smmry-response-char-count jsonified)
          (gethash smmry-response-limitation jsonified)))

;;;###autoload
(defun smmry-by-url ()
  (interactive)
  (let ((smmry-api-key (getenv smmry-env-api-key)))
    (unless smmry-api-key
      (error (format "No API key set in %s" smmry-env-api-key)))
    (let* ((url (read-string "URL: "))
           (smmry-url (smmry--build-url smmry-api-key url)))
      (unless (> (length url) 0)
        (error "Error: empty URL"))
      (let ((url-request-method "GET"))
        (with-current-buffer (url-retrieve-synchronously smmry-url)
          ;; Remove headers
          (declare (special url-http-end-of-headers))
          (goto-char url-http-end-of-headers)
          (delete-region (point-min) (point))
          ;; Parse JSON response body
          (let ((json-object-type 'hash-table))
            (let* ((payload (buffer-string))
                   (jsonified (json-read-from-string payload))
                   (errored (smmry--erroredp jsonified)))
              (when errored
                (error (smmry--build-error-message jsonified)))
              (erase-buffer)
              (insert (gethash smmry-response-content jsonified))
              (goto-char (point-min))
              (rename-buffer (smmry--build-buffer-name jsonified))
              (display-buffer (current-buffer))
              (message "SMMRY response received"))))))))

;;;###autoload
(defun smmry-by-region ()
  (interactive)
  (let ((smmry-api-key (getenv smmry-env-api-key)))
    (unless smmry-api-key
      (error (format "No API key set in %s" smmry-env-api-key)))
    (let ((text (buffer-substring (mark) (point)))
          (smmry-url (smmry--build-url smmry-api-key)))
      (unless (> (length text) 0)
        (error "Error: no region selected"))
      (let ((url-request-method "POST")
            (url-request-extra-headers '(("Content-Type" . "application/x-www-form-urlencoded")))
            (url-request-data (format "%s=%s" smmry-request-input text)))
        (with-current-buffer (url-retrieve-synchronously smmry-url)
          ;; Remove headers
          (declare (special url-http-end-of-headers))
          (goto-char url-http-end-of-headers)
          (delete-region (point-min) (point))
          ;; Parse JSON response body
          (let ((json-object-type 'hash-table))
            (let* ((payload (string-trim (buffer-string)))
                   (jsonified (json-read-from-string payload))
                   (errored (smmry--erroredp jsonified)))
              (when errored
                (error (smmry--build-error-message jsonified)))
              (erase-buffer)
              (insert (gethash smmry-response-content jsonified))
              (goto-char (point-min))
              (rename-buffer (smmry--build-buffer-name jsonified))
              (display-buffer (current-buffer))
              (message "SMMRY response received"))))))))

(provide 'smmry)

;;; smmry.el ends here
