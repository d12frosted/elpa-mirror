;;; auth-source-keytar.el --- Integrate auth-source with keytar  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Shen, Jen-Chieh
;; Created date 2021-03-29 19:24:39

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Emacs Lisp interface for node-keytar
;; Keyword: keytar password credential secret security
;; Version: 0.1.3
;; Package-Version: 20210516.556
;; Package-Commit: a1e0a364a64900839b544d88347fa229b3aa91ab
;; Package-Requires: ((emacs "24.4") (keytar "0.1.2") (s "1.12.0"))
;; URL: https://github.com/emacs-grammarly/auth-source-keytar

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
;;
;; Integrates keytar (https://www.npmjs.com/package/keytar) within
;; auth-source.
;;

;;; Code:

(require 'auth-source)
(require 'keytar)
(require 's)

(defgroup auth-source-keytar nil
  "Keytar integration within auth-source."
  :prefix "auth-source-keytar-"
  :group 'auth-source)

;;;###autoload
(defun auth-source-keytar-enable ()
  "Enable auth-source-keytar."
  (add-to-list 'auth-sources 'keytar)
  (auth-source-forget-all-cached))

(cl-defun auth-source-keytar-search
    (&rest spec &key service account host user &allow-other-keys)
  "Given some search query, return matching credentials.

Common search keys: HOST, USER.

See `auth-source-search' for details on the parameters SPEC, SERVICE
and ACCOUNT."
  (cond ((and service account) (keytar-get-password service account))
        ((and host user) (keytar-get-password host user))
        (service (auth-source-keytar--build-result service))
        (host (auth-source-keytar--build-result host))
        (t (user-error "Missing key `service` in search query"))))

(defun auth-source-keytar--read-password (secret)
  "Read password from SECRET."
  (let* ((lst (split-string secret "password: '"))
         (pass (nth 1 lst)))
    (string-trim (s-replace "' }" "" pass))))

(defun auth-source-keytar--build-result (service)
  "Build auth-source-keytar entry matching SERVICE."
  (let ((creds '()) (result (keytar-find-credentials service)))
    (setq result (s-replace "[" "" result)
          result (s-replace "]" "" result)
          result (split-string result "\n" t))
    (dolist (secret result)
      (setq secret (string-trim secret)
            secret (s-replace-regexp ",$" "" secret)
            secret (auth-source-keytar--read-password secret))
      (push (list :secret secret) creds))
    creds))

(defun auth-source-keytar-backend-parse (entry)
  "Create a keytar auth-source backend from ENTRY."
  (when (eq entry 'keytar)
    (auth-source-backend-parse-parameters
     entry
     (auth-source-backend
      :source "Keytar"
      :type 'keytar
      :search-function #'auth-source-keytar-search))))

(if (boundp 'auth-source-backend-parser-functions)
    (add-hook 'auth-source-backend-parser-functions #'auth-source-keytar-backend-parse)
  (advice-add 'auth-source-backend-parse :before-until #'auth-source-keytar-backend-parse))

(provide 'auth-source-keytar)
;;; auth-source-keytar.el ends here
