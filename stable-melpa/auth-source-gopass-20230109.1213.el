;;; auth-source-gopass.el --- Gopass integration for auth-source -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Markus M. May
;; SPDX-License-Identifier: GPL-3.0-or-later

;; Author: Markus M. May <mmay@javafreedom.org>
;; Created: 31 December 2022
;; URL: https://github.com/
;; Package-Version: 20230109.1213
;; Package-Commit: 6f7f0cc0d682f66d11f7fac4fa5c1e79904232da

;; Package-Requires: ((emacs "24.4"))

;; Version: 0.0.3

;;; Commentary:
;; This package adds gopass support to auth-source by calling
;; gopass from the command line.
;; This is in large parts copied from the
;; auth-source-kwallet.el and auth-source-pass.el packages.

;;; Code:
(require 'auth-source)

(defgroup auth-source-gopass nil
  "Gopass auth source settings."
  :group 'external
  :tag "auth-source-gopass"
  :prefix "gopass-")

(defcustom auth-source-gopass-path-prefix "accounts"
  "Prefix of the entries in the gopass backend."
  :type 'string
  :group 'auth-source-gopass)

(defcustom auth-source-gopass-path-separator "/"
  "Separator of elements in the gopass backend structure."
  :type 'string
  :group 'auth-source-gopass)

(defcustom auth-source-gopass-executable "gopass"
  "Executable used for gopass."
  :type 'string
  :group 'auth-source-gopass)

(defcustom auth-source-gopass-construct-query-path 'auth-source-gopass--gopass-construct-query-path
  "Function to construct the query path in the gopass store."
  :type 'function
  :group 'auth-source-gopass)

(defun auth-source-gopass--gopass-construct-query-path (_backend _type host user _port)
  "Construct the full entry-path for the gopass entry grom HOST and USER.
Usually starting with the `auth-source-gopass-path-prefix', followed by host
and user, separated by the `auth-source-gopass-path-separator'."
  (mapconcat #'identity (list auth-source-gopass-path-prefix
                             host
                             user) auth-source-gopass-path-separator))

(cl-defun auth-source-gopass-search (&rest spec
                                           &key backend type host user port
                                           &allow-other-keys)
  "Searche gopass for the specified user and host.
SPEC, BACKEND, TYPE, HOST, USER and PORT are required by auth-source."
  (if (executable-find auth-source-gopass-executable)
      (let ((got-secret (string-trim
                         (shell-command-to-string
                          (format "%s show -o %s"
                                  auth-source-gopass-executable
                                  (shell-quote-argument (funcall auth-source-gopass-construct-query-path backend type host user port)))))))
        (list (list :user user
                    :secret got-secret)))
    ;; If not executable was found, return nil and show a warning
    (warn "`auth-source-gopass': Could not find executable '%s' to query gopass" auth-source-gopass-executable)))

;;;###autoload
(defun auth-source-gopass-enable ()
  "Enable the gopass auth source."
  (add-to-list 'auth-sources 'gopass)
  (auth-source-forget-all-cached))

(defvar auth-source-gopass-backend
  (auth-source-backend
   :source "."
   :type 'gopass
   :search-function #'auth-source-gopass-search))

(defun auth-source-gopass-backend-parse (entry)
  "Create a gopass auth-source backend from ENTRY."
  (when (eq entry 'gopass)
    (auth-source-backend-parse-parameters entry auth-source-gopass-backend)))

(if (boundp 'auth-source-backend-parser-functions)
    (add-hook 'auth-source-backend-parser-functions #'auth-source-gopass-backend-parse)
  (advice-add 'auth-source-backend-parse :before-until #'auth-source-gopass-backend-parse))

(provide 'auth-source-gopass)
;;; auth-source-gopass.el ends here
