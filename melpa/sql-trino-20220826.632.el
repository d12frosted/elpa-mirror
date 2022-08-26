;;; sql-trino.el --- Adds Trino support to SQLi mode -*- lexical-binding: t -*-

;; Copyright (C) since 2022 Filipe Regadas
;; Author: Filipe Regadas <oss@regadas.email>
;; Version: 0.1.0
;; Package-Version: 20220826.632
;; Package-Commit: 624a879ec0d03cae8a92f26d21d88c831e15eb41
;; Keywords: tools
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/regadas/sql-trino
;; SPDX-License-Identifier: GPL-3.0-or-later


;;; Commentary:
;; * sql-trino.el

;;   + What is it?

;;     Emacs comes with a SQL interpreter which is able to open a
;;     connection to databases and present you with a prompt you are
;;     probably familiar with (e.g. `mysql>', `pgsql>', `trino>',
;;     etc.). This mode gives you the ability to do that for Trino.


;;   + How do I get it?

;;     The canonical repository for the source code is
;;     <https://github.com/regadas/sql-trino>.

;;     The recommended way to install the package is to utilize Emacs's
;;     `package.el' along with MELPA. To set this up, please follow MELPA's
;;     [getting started guide], and then run `M-x package-install
;;     sql-trino'.


;;     [getting started guide] <https://melpa.org/#/getting-started>


;;   + Requirements

;;     Download the [Trino CLI], rename it to `trino' and put it in your
;;     `$PATH'.


;;     [Trino CLI]
;;     <https://repo1.maven.org/maven2/io/trino/trino-cli/378/trino-cli-378-executable.jar>


;;   + How do I use it?

;;     Within Emacs, run `M-x sql-trino'. You will be prompted by a
;;     minibuffer for a server. Enter a server and you should be greeted by
;;     a SQLi buffer with a `trino>' prompt.

;;     From there you can either type queries in this buffer, or open a
;;     `sql-mode' buffer and send chunks of SQL over to the SQLi buffer
;;     with the requisite key-chords.


;;   + Contributing

;;     Please open GitHub issues and pull requests.

;;; Code:
(require 'sql)

(defgroup sql-trino nil
  "Use Trino with sql-interactive mode."
  :group 'SQL
  :prefix "sql-trino-")

(defcustom sql-trino-program "trino"
  "Command to start the Trino command interpreter."
  :type 'file
  :group 'sql-trino)

(defcustom sql-trino-login-params '(user server database)
  "Parameters needed to connect to Trino."
  :type 'sql-login-params
  :group 'sql-trino)

(defcustom sql-trino-options '("--output-format" "CSV_HEADER")
  "List of options for `sql-trino-program'."
  :type '(repeat string)
  :group 'sql-trino)

(defun sql-trino-comint (product options &optional buffer-name)
  "Connect to Trino in a comint buffer.

PRODUCT is the sql product (trino). OPTIONS are any additional
options to pass to trino-shell. BUFFER-NAME is what you'd like
the SQLi buffer to be named."
  (let ((params
         (append
          (if (not (string= "" sql-user))
              (list "--user" sql-user))
          (if (not (string= "" sql-database))
              (list "--catalog" sql-database))
          (if (not (string= "" sql-server))
              (list "--server" sql-server))
          options)))
    (setenv "TRINO_PAGER" "cat")
    (sql-comint product params buffer-name)))

;;;###autoload
(defun sql-trino (&optional buffer)
  "Run Trino as an inferior process.

The buffer with name BUFFER will be used or created."
  (interactive "P")
  (sql-product-interactive 'trino buffer))

(sql-add-product 'trino "Trino"
                 :free-software t
                 :list-all "SHOW TABLES;"
                 :list-table "DESCRIBE %s;"
                 :prompt-regexp "^[^>]*> "
                 :prompt-length 7
                 :prompt-cont-regexp "^[ ]+-> "
                 :sqli-comint-func 'sql-trino-comint
                 :font-lock 'sql-mode-ansi-font-lock-keywords
                 :sqli-login sql-trino-login-params
                 :sqli-program 'sql-trino-program
                 :sqli-options 'sql-trino-options)

(provide 'sql-trino)
;;; sql-trino.el ends here
