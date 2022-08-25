;;; haste.el --- Emacs client for hastebin (http://hastebin.com/about.md)

;; 
;; Copyright (C) 2012 by Ric Lister
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of the
;; License, or any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.
;;

;; Author: Ric Lister
;; URL: http://github.com/rlister/emacs-haste-client
;; Package-Version: 20141030.2034
;; Package-Commit: f1099c6296fc9575675e281402b89854739114bb
;; Version: 1.1
;; Package-Requires: ((json "1.2"))

;; 
;; Get the code from MELPA:
;;
;;   M-x package-install haste
;;
;; or the latest from github:
;;
;;   git clone https://github.com/rlister/emacs-haste-client
;;
;; and add the following to your emacs config:
;;
;;   (add-to-list 'load-path "~/path/to/emacs-haste-client")
;;   (require 'haste nil 'noerror)
;;
;; Server defaults to hastebin.com, but you can override to a local
;; server installation by setting environment variable:
;;
;;   export HASTE_SERVER=http://hastebin.mydomain.com
;;
;; or in emacs, with:
;;
;;   (setq haste-server "http://hastebin.mydomain.com")
;;
;; If your hastebin server is protected with http basic auth,
;; you can set credentials from the environment:
;;
;;   export HASTE_USERNAME=myuser
;;   export HASTE_PASSWORD=mypass
;;
;; or in emacs, with:
;;
;;   (setq haste_username "myuser")
;;   (setq haste_password "mypass")
;;
;; Paste code to hastebin:
;;
;;   M-x haste
;;
;; If the mark is set, the contents of the region will be posted,
;; otherwise the whole buffer. Your new hastebin url will be echoed
;; to the minibuffer and pushed onto the kill-ring ready for use.
;; You can also retrieve it from the buffer *Messages*.

(require 'json)

(defvar haste-server   (or (getenv "HASTE_SERVER") "http://hastebin.com"))
(defvar haste-path     (or (getenv "HASTE_PATH") "/documents"))
(defvar haste-username (or (getenv "HASTE_USERNAME") nil))
(defvar haste-password (or (getenv "HASTE_PASSWORD") nil))

(defun haste-post (data)
  "Send haste a POST request."
  (let ((haste-url (concat haste-server haste-path))
        (url-request-method "POST")
        (url-request-extra-headers (haste-request-headers))
        (url-request-data data))
    (url-retrieve haste-url 'get-haste-key-from-buffer)))

(defun haste-request-headers ()
  "Return http request headers with basic auth if username and password set."
  (if (and haste-username haste-password)
      `(("Authorization" . ,(concat "Basic "
                                    (base64-encode-string
                                     (concat haste-username ":" haste-password)))))
    `()))

(defun get-haste-key-from-buffer (status)
  "Callback to extract hastebin key from buffer returned by url-retrieve and push onto kill-ring."
  (with-current-buffer (current-buffer)
    (goto-char (point-min))
    (re-search-forward "^\n")           ;first blank line
    (beginning-of-line)
    (let (json-alist key document-url)
      (setq json-alist (json-read-from-string
                        (buffer-substring-no-properties (point) (point-max))))
      (setq key (cdr (assoc 'key json-alist)))
      (setq document-url (concat haste-server "/" key))
      (message "posted to: %s" document-url)
      (kill-new document-url))))

(defun haste ()
  "Post to haste with region, if active, otherwise contents of whole buffer."
  (interactive)
  (let (bounds data)
    (setq bounds
          (if (and transient-mark-mode mark-active)
              (cons (region-beginning) (region-end))
            (cons (point) (point-max))))
    (setq data (buffer-substring-no-properties (car bounds) (cdr bounds)))
    (haste-post data)))

(provide 'haste)

;;; haste.el ends here
