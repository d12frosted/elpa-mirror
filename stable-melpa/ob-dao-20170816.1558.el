;;; ob-dao.el --- Org Babel Functions for Dao          -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Chunyang Xu

;; Author: Chunyang Xu <mail@xuchunyang.me>
;; Package-Requires: ((org "8"))
;; Package-Version: 20170816.1558
;; Package-Commit: 8c62bd800b1f572860e30be4b72c71fa415a2e31
;; Keywords: literate programming, reproducible research, org, babel, dao
;; URL: https://github.com/xuchunyang/ob-dao
;; Version: 0.1.0

;; This program is free software; you can redistribute it and/or modify
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

;; Org-Babel support for evaluating Dao[1] code
;;
;; [1] http://daoscript.org/

;;; Code:

(require 'ob)

(defvar org-babel-dao-command "dao"
  "Name of the dao executable command.")

(defun org-babel-execute:dao (body params)
  "Execute a block of Dao code with Babel.
This function is called by `org-babel-execute-src-block'."
  (message "executing Dao source code block")
  (let ((options (or (cdr (assq :options params)) "")))
    (org-babel-eval (format "%s %s --eval %s"
                            (shell-quote-argument org-babel-dao-command)
                            options
                            (shell-quote-argument body))
                    "")))

(defun org-babel-prep-session:dao (_session _params)
  "Prepare a session.
This function does nothing as Dao is a compiled language with no
support for sessions."
  (error "Dao is a compiled language -- no support for sessions"))

(provide 'ob-dao)
;;; ob-dao.el ends here
