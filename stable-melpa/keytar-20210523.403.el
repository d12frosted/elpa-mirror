;;; keytar.el --- Emacs Lisp interface for node-keytar  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Shen, Jen-Chieh
;; Created date 2021-03-09 11:52:53

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Emacs Lisp interface for node-keytar
;; Keyword: keytar password credential secret security
;; Version: 0.1.2
;; Package-Version: 20210523.403
;; Package-Commit: 584395339f85a95ffe3ade3f4e30898bad495ecd
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

(require 'subr-x)

(defconst keytar-package-name "@emacs-grammarly/keytar-cli"
  "NPM package name for keytar to execute.")

(defgroup keytar nil
  "Emacs Lisp interface for node-keytar."
  :group 'tools
  :tag "Keytar")

(defcustom keytar-install-dir (expand-file-name (locate-user-emacs-file
                                                 ".cache/keytar"))
  "Absolute path to installation directory of keytar."
  :risky t
  :type 'directory
  :group 'keytar)

;;
;; (@* "Util" )
;;

(defun keytar--execute (cmd &rest args)
  "Return non-nil if CMD executed succesfully with ARGS."
  (save-window-excursion
    (let ((inhibit-message t) (message-log-max nil))
      (= 0 (shell-command (concat cmd " "
                                  (mapconcat #'shell-quote-argument args " ")))))))

(defun keytar--execute-string (cmd &rest args)
  "Return result in string after CMD is executed with ARGS."
  (save-window-excursion
    (let ((inhibit-message t) (message-log-max nil))
      (string-trim (shell-command-to-string
                    (concat cmd " " (mapconcat #'shell-quote-argument args " ")))))))

(defun keytar--exe-path ()
  "Return path to keytar executable."
  (let ((path (executable-find
               (if keytar-install-dir
                   (concat keytar-install-dir "/"
                           (cond ((eq system-type 'windows-nt) "/")
                                 (t "bin/"))
                           "keytar")
                 "keytar"))))
    (when (and path (file-exists-p path))
      path)))

(defun keytar-installed-p ()
  "Return non-nil if `keytar-cli' installed succesfully."
  (keytar--exe-path))

(defun keytar--check ()
  "Key before using `keytar-cli'."
  (unless (keytar-installed-p)
    (user-error "[WARNING] Make sure you have installed `%s` through `npm` or hit `M-x keytar-install`"
                keytar-package-name)))

(defun keytar--valid-return (result)
  "Return nil if RESULT is invalid output."
  (if (or (string= "null" result) (string-match-p "TypeError:" result)
          (string-match-p "Not enough arguments" result))
      nil result))

;;;###autoload
(defun keytar-install ()
  "Install keytar package through npm."
  (interactive)
  (if (keytar-installed-p)
      (message "NPM package `%s` is already installed" keytar-package-name)
    (if (apply #'keytar--execute (append
                                  `("npm" "install" "-g" ,keytar-package-name)
                                  (when keytar-install-dir `("--prefix" ,keytar-install-dir))))
        (message "Successfully install `%s` through `npm`!" keytar-package-name)
      (user-error "Failed to install` %s` through `npm`, make sure you have npm installed"
                  keytar-package-name))))

;;
;; (@* "API" )
;;

(defun keytar-version ()
  "Return the version of Keytar."
  (keytar--check)
  (keytar--valid-return
   (keytar--execute-string (keytar--exe-path) "--version")))

(defun keytar-get-password (service account)
  "Get the stored password for the SERVICE and ACCOUNT."
  (keytar--check)
  (keytar--valid-return
   (keytar--execute-string (keytar--exe-path) "get-pass"
                           "-s" service "-a" account)))

(defun keytar-set-password (service account password)
  "Save the PASSWORD for the SERVICE and ACCOUNT to the keychain.

Adds a new entry if necessary, or updates an existing entry if one exists."
  (keytar--check)
  (keytar--execute (keytar--exe-path) "set-pass" "-s" service "-a"
                   account "-p" password))

(defun keytar-delete-password (service account)
  "Delete the stored password for the SERVICE and ACCOUNT."
  (keytar--check)
  (keytar--execute (keytar--exe-path) "delete-pass"
                   "-s" service "-a" account))

(defun keytar-find-credentials (service)
  "Find all accounts and password for the SERVICE in the keychain."
  (keytar--check)
  (keytar--valid-return
   (keytar--execute-string (keytar--exe-path) "find-creds" "-s" service)))

(defun keytar-find-password (service)
  "Find a password for the SERVICE in the keychain.

This is ideal for scenarios where an account is not required."
  (keytar--check)
  (keytar--valid-return
   (keytar--execute-string (keytar--exe-path) "find-pass" "-s" service)))

(provide 'keytar)
;;; keytar.el ends here
