;;; emacsql-libsqlite3.el --- EmacSQL back-end for SQLite using a module  -*- lexical-binding: t -*-

;; Copyright (C) 2021 Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/emacscollective/emacsql-libsqlite3
;; Keywords: mail
;; Package-Version: 20210927.2137
;; Package-Commit: ce95d8a373321bdeafa13e81dac18495c055fd95
;; Package-Requires: ((emacs "25.1") (emacsql "3.0.0") (emacsql-sqlite "3.0.0") (sqlite "0"))
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; An alternative EmacsSQL back-end for SQLite, which uses an Emacs
;; module that exposes parts of the SQLite C API to elisp, instead of
;; using subprocess as `emacsql-sqlite' does.  The module is provided
;; by the `sqlite3' package.

;; The goal is to provide a more performant and resilent drop-in
;; replacement for `emacsql-sqlite'.  Taking full advantage of the
;; granular module functions currently isn't a goal.

;;; Code:

(require 'sqlite3)
(require 'emacsql)
;; For `emacsql-sqlite-reserved' and `emacsql-sqlite-condition-alist'.
(require 'emacsql-sqlite)

(defclass emacsql-libsqlite3-connection (emacsql-connection)
  ((file :initarg :file
         :type (or null string)
         :documentation "Database file name.")
   (types :allocation :class
          :reader emacsql-types
          :initform '((integer "INTEGER")
                      (float "REAL")
                      (object "TEXT")
                      (nil nil)))
   (handle :documentation "Database handle.")
   (value :document "(internal) Value of last query."))
  (:documentation "A connection to a SQLite database using a module."))

(cl-defmethod initialize-instance :after
  ((connection emacsql-libsqlite3-connection) &rest _)
  (oset connection handle
        (sqlite3-open (or (slot-value connection 'file) ":memory:")
                      sqlite-open-readwrite
                      sqlite-open-create))
  (emacsql connection [:pragma (= busy-timeout $s1)]
           (/ (* emacsql-global-timeout 1000) 2))
  (emacsql-register connection))

(cl-defun emacsql-libsqlite3 (file &key debug)
  (let ((connection (make-instance 'emacsql-libsqlite3-connection :file file)))
    (when debug
      (emacsql-enable-debugging connection))
    connection))

(cl-defmethod emacsql-close ((connection emacsql-libsqlite3-connection))
  (sqlite3-close (oref connection handle)))

(cl-defmethod emacsql-send-message ((connection emacsql-libsqlite3-connection)
                                    message)
  (let (rows)
    (condition-case err
        (sqlite3-exec (oref connection handle)
                      message
                      (lambda (_ row _)
                        (push (mapcar (lambda (col)
                                        (cond ((null col) nil)
                                              ((equal col "") "")
                                              (t (read col))))
                                      row)
                              rows)))
      ((db-error sql-error)
       (pcase-let ((`(,sym ,msg ,code) err))
         (signal (or (cadr (cl-assoc code emacsql-sqlite-condition-alist
                                     :test #'memql))
                     'emacsql-error)
                 (list msg code sym))))
      (error
       (signal 'emacsql-error err)))
    ;; Pass value to `emacsql-parse'.
    (oset connection value (nreverse rows))))

;; Needed because `emacsql' isn't a generic function.
(cl-defmethod emacsql-parse ((connection emacsql-libsqlite3-connection))
  (oref connection value))
(cl-defmethod emacsql-clear ((_connection emacsql-libsqlite3-connection))) ;noop
(cl-defmethod emacsql-wait ((_connection emacsql-libsqlite3-connection))) ;noop

;;; _
(provide 'emacsql-libsqlite3)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; emacsql-libsqlite3.el ends here
