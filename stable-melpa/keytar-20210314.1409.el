;;; keytar.el --- Emacs Lisp interface for node-keytar  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Shen, Jen-Chieh
;; Created date 2021-03-09 11:52:53

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Emacs Lisp interface for node-keytar
;; Keyword: keytar password credential secret security
;; Version: 0.1.2
;; Package-Version: 20210314.1409
;; Package-Commit: 17972320ef140bd56e551842d89f5d8c2d979f83
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/emacs-grammarly/keytar

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
;; Emacs Lisp interface for node-keytar
;;
;; See,
;;   - https://www.npmjs.com/package/keytar
;;   - https://github.com/emacs-grammarly/keytar-cli
;;

;;; Code:

(defconst keytar-package-name "@emacs-grammarly/keytar-cli"
  "NPM package name for keytar to execute.")

;;
;; (@* "Util" )
;;

(defun keytar--execute (in-cmd)
  "Return non-nil if IN-CMD executed succesfully."
  (save-window-excursion
    (let ((inhibit-message t) (message-log-max nil))
      (= 0 (shell-command in-cmd)))))

(defun keytar--execute-string (in-cmd)
  "Return result in string after IN-CMD is executed."
  (save-window-excursion
    (let ((inhibit-message t) (message-log-max nil))
      (string-trim (shell-command-to-string in-cmd)))))

(defun keytar-installed-p ()
  "Return non-nil if `keytar-cli' installed succesfully."
  (keytar--execute "keytar --help"))

(defun keytar--ckeck ()
  "Key before using `keytar-cli'."
  (unless (keytar-installed-p)
    (user-error "[ERROR] Make sure you have installed `%s` through `npm`" keytar-package-name)))

(defun keytar--valid-return (result)
  "Return nil if RESULT is invalid output."
  (if (or (string= "null" result) (string-match-p "TypeError:" result)
          (string-match-p "Not enough arguments" result))
      nil result))

(defun keytar-install ()
  "Install keytar package through npm."
  (interactive)
  (if (keytar--execute (format "npm install -g %s" keytar-package-name))
      (message "Successfully install `%s` through `npm`!" keytar-package-name)
    (user-error "Failed to install` %s` through `npm`, make sure you have npm installed"
                keytar-package-name)))

;;
;; (@* "API" )
;;

(defun keytar-get-password (service account)
  "Get the stored password for the SERVICE and ACCOUNT."
  (keytar--ckeck)
  (keytar--valid-return
   (keytar--execute-string (format "keytar get-pass -s %s -a %s" service account))))

(defun keytar-set-password (service account password)
  "Save the PASSWORD for the SERVICE and ACCOUNT to the keychain.

Adds a new entry if necessary, or updates an existing entry if one exists."
  (keytar--ckeck)
  (keytar--execute (format "keytar set-pass -s %s -a %s -p %s"
                           service account password)))

(defun keytar-delete-password (service account)
  "Delete the stored password for the SERVICE and ACCOUNT."
  (keytar--ckeck)
  (keytar--execute (format "keytar delete-pass -s %s -a %s" service account)))

(defun keytar-find-credentials (service)
  "Find all accounts and password for the SERVICE in the keychain."
  (keytar--ckeck)
  (keytar--valid-return
   (keytar--execute-string (format "keytar find-creds -s %s" service))))

(defun keytar-find-password (service)
  "Find a password for the SERVICE in the keychain.

This is ideal for scenarios where an account is not required."
  (keytar--ckeck)
  (keytar--valid-return
   (keytar--execute-string (format "keytar find-pass -s %s" service))))

(provide 'keytar)
;;; keytar.el ends here
