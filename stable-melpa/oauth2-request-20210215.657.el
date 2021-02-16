;;; oauth2-request.el --- OAuth2 request package interface  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 1.0.0
;; Package-Version: 20210215.657
;; Package-Commit: 86ff048635e002b00e23d6bed2ec6f36c17bca8e
;; Keywords: convenience
;; Package-Requires: ((emacs "26.1") (oauth2 "0.14") (request "0.3"))
;; URL: https://github.com/conao3/oauth2-request.el

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

;; OAuth2 request package interface.

;; Sample usage:

;;   (setq token
;;         (let ((auth-url "https://accounts.google.com/o/oauth2/auth")
;;               (token-url "https://www.googleapis.com/oauth2/v3/token")
;;               (client-id "000000000000-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com")
;;               (client-secret "xxxxxxxxxxxxxxxxxxxxxxxx")
;;               (scope "https://www.googleapis.com/auth/calendar"))
;;           (oauth2-auth-and-store auth-url token-url scope client-id client-secret)))

;;   (oauth2-request token "https://www.googleapis.com/calendar/v3/users/me/calendarList"
;;     :complete (cl-function
;;                (lambda (&key response &allow-other-keys)
;;                  (with-current-buffer (generate-new-buffer "*oauth2-request*")
;;                    (insert (pp-to-string response))
;;                    (newline)
;;                    (insert (request-response-data response))
;;                    (display-buffer (current-buffer))))))


;;; Code:

(require 'gv)
(require 'oauth2)
(require 'request)

(defgroup oauth2-request nil
  "OAuth2 `request' package interface."
  :group 'convenience
  :link '(url-link :tag "Github" "https://github.com/conao3/oauth2-request.el"))

;; Included at Emacs-27.2
(defalias 'oauth2-request-plist-get #'plist-get)
(gv-define-expander oauth2-request-plist-get
  (lambda (do plist prop)
    (macroexp-let2 macroexp-copyable-p key prop
      (gv-letplace (getter setter) plist
        (macroexp-let2 nil p `(cdr (plist-member ,getter ,key))
          (funcall do
                   `(car ,p)
                   (lambda (val)
                     `(if ,p
                          (setcar ,p ,val)
                        ,(funcall setter `(cons ,key (cons ,val ,getter)))))))))))

(defvar oauth--token-data)

;;;###autoload
(defun oauth2-request (token url &rest args)
  "OAuth2 `request', enhanced `oauth2-url-retrieve'.

TOKEN is `oauth2-token'.  ARGS are `request' argument.
  (URL &rest settings
             &key
             (params nil)
             (data nil)
             (headers nil)
             (encoding 'utf-8)
             (error nil)
             (sync nil)
             (response (make-request-response))
             &allow-other-keys)."
  (declare (indent 2))
  (oauth2-refresh-access token)
  (let ((headers (oauth2-request-plist-get args :headers))
        (oauth--token-data (cons token url)))
    (when (alist-get "Authorization" headers)
      (error "Don't specify an Authorization slot"))
    (setf (oauth2-request-plist-get args :headers)
          (oauth2-extra-headers headers))
    (apply #'request url args)))

;;;###autoload
(defun oauth2-request-synchronously (token url &rest args)
  "OAuth2 `request', enhanced `oauth2-url-retrieve-synchronously'.
See `oauth2-request' for TOKEN, URL, ARGS documentation."
  (setf (oauth2-request-plist-get args :sync) t)
  (apply #'oauth2-request token url args))

(provide 'oauth2-request)

;;; oauth2-request.el ends here
