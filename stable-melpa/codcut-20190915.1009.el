;;; codcut.el --- Share pieces of code to Codcut
     
;; Copyright (C) 2010-2019 Diego Pasquali

;; Author: Diego Pasquali <hello@dgopsq.space>
;; Keywords: comm, tools, codcut, share
;; Package-Version: 20190915.1009
;; Package-Commit: bf07c3db3900e36b0b87423f3b715d6378f86393
;; Homepage: https://github.com/codcut/codcut-emacs
;; Version: 0.0.1

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Usage:
;; Highlight the code you want to
;; share and execute either `share-to-codcut`
;; or `share-to-codcut-redirect`.

;;; Code:

(require 'json)

(defvar url-http-response-status)

(defgroup codcut nil
  "Codcut settings."
  :group 'external)

(defcustom codcut-token nil
  "Codcut access token."
  :type '(string)
  :group 'codcut)

(defconst codcut-post-endpoint
  "https://resource.codcut.com/api/posts")

(defconst codcut-post-format-string
  "https://codcut.com/posts/%d")

(defun codcut-get-selected-text ()
  "Retrieve the current selected text or nil."
  (if (use-region-p)
      (buffer-substring (region-beginning) (region-end)) nil))

(defun codcut-get-file-extension ()
  "Retrieve the file extension or nil."
  (if (buffer-file-name)
      (file-name-extension (buffer-file-name)) nil))

(defun codcut-get-major-mode ()
  "Retrieve the current major mode."
  (symbol-name major-mode))

(defun codcut-get-language ()
  "Retrieve the code language for Codcut."
  (or (codcut-get-file-extension) (codcut-get-major-mode)))

(defun codcut-get-id-from-post (json-string)
  "Get the id from a post JSON string.
- JSON-STRING: A json string representing a Post"
  (cdr (assoc 'id
              (json-read-from-string json-string))))

(defun codcut-generate-url (post-id)
  "Generate a post URL.
- POST-ID: The post's id"
  (format codcut-post-format-string post-id))

(defun codcut-make-post-request (code description language)
  "Make a new post request to Codcut getting the resulting post id.
- CODE: The code to share.
- DESCRIPTION: The code description (optional).
- LANGUAGE: The language used by the code."
  (if (not codcut-token)
      (throw 'request-error (error "You must set codcut-token first")))
  (let ((url-request-method "POST")
        (url-request-extra-headers
         `(("Authorization" . ,(format "Bearer %s" codcut-token))
           ("Content-Type" . "application/json")))
        (url-request-data
         (json-encode-alist
          `(("code" . ,code)
            ("body" . ,description)
            ("language" . ,language)))))
    (let (data)
      (with-current-buffer
          (url-retrieve-synchronously codcut-post-endpoint)
        (goto-char (point-min))
        (if (and (eq url-http-response-status 200) (re-search-forward "^$" nil t))
            (setq data (buffer-substring (1+ (point)) (point-max)))
          (throw 'request-error (error "Something went wrong")))
        (codcut-get-id-from-post data)))))

;;;###autoload
(defun codcut-share ()
  "Share the selected code to Codcut."
  (interactive)
  (let ((code (codcut-get-selected-text))
        (description (read-string "Enter a description (optional): "))
        (language (codcut-get-language)))
    (catch 'request-error
      (let ((post-id (codcut-make-post-request code description language)))
        (message "New shared code at %s"
                 (codcut-generate-url post-id))))))
;;;###autoload
(defun codcut-share-redirect ()
  "Share the selected code to Codcut and open the browser to the new code."
  (interactive)
  (let ((code (codcut-get-selected-text))
        (description (read-string "Enter a description (optional): "))
        (language (codcut-get-language)))
    (catch 'request-error
      (let ((post-id (codcut-make-post-request code description language)))
        (browse-url (codcut-generate-url post-id))))))

(provide 'codcut)
;;; codcut.el ends here
