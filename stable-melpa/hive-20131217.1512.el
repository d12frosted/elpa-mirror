;;; hive.el --- Hive SQL mode extension

;; Copyright (C) 2013 Roman Scherer

;; Author: Roman Scherer <roman@burningswell.com>
;; Version: 0.1.1
;; Package-Version: 20131217.1512
;; Package-Commit: 131f2816a0cf4d1fee44198ca305e6e2d1cab750
;; Package-Requires: ((sql "3.0"))
;; Keywords: sql hive

;;; Commentary:

;; This package adds Hive to the sql-mode product list.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

(require 'sql)

(defcustom sql-hive-program "hive"
  "Command to start the Hive client."
  :type 'file
  :group 'SQL)

(defcustom sql-hive-options '()
  "List of additional options for `sql-hive-program'."
  :type '(repeat string)
  :group 'SQL)

(defcustom sql-hive-login-params '()
  "List of login parameters needed to connect to Hive."
  :type 'sql-login-params
  :group 'SQL)

(defun sql-comint-hive (product options)
  "Create comint buffer and connect to Hive."
  (let ((params options))
    (sql-comint product params)))

;;;###autoload
(defun sql-hive (&optional buffer)
  "Run hive as an inferior process."
  (interactive "P")
  (sql-product-interactive 'hive buffer))

(eval-after-load "sql"
  '(sql-add-product
    'hive "Hive"
    :sqli-program 'sql-hive-program
    :sqli-options 'sql-hive-options
    :sqli-login 'sql-hive-login-params
    :sqli-comint-func 'sql-comint-hive
    :prompt-regexp "^hive> "
    :prompt-length 5
    :prompt-cont-regexp "^    > "))

(provide 'hive)

;;; hive.el ends here
