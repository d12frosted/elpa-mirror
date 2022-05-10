;;; emacsql-sqlite-module.el --- EmacSQL back-end for SQLite using a module  -*- lexical-binding:t -*-

;; Copyright (C) 2021-2022 Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/emacscollective/emacsql-sqlite-builtin
;; Keywords: data
;; Package-Version: 20220422.1605
;; Package-Commit: 3e820c66fdaa9937f9e612900954dcd6c7d01943

;; Package-Requires: (
;;     (emacs "25")
;;     (emacsql "3.0.0")
;;     (emacsql-sqlite "3.0.0")
;;     (sqlite3 "0.15"))

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

;; The goal is to provide a more performant and resilient drop-in
;; replacement for `emacsql-sqlite'.  Taking full advantage of the
;; granular module functions currently isn't a goal.

;;; Code:

(require 'sqlite3)
(require 'emacsql)
;; For `emacsql-sqlite-reserved' and `emacsql-sqlite-condition-alist'.
(require 'emacsql-sqlite)

(defclass emacsql-sqlite-module-connection (emacsql-connection)
  ((file :initarg :file
         :type (or null string)
         :documentation "Database file name.")
   (types :allocation :class
          :reader emacsql-types
          :initform '((integer "INTEGER")
                      (float "REAL")
                      (object "TEXT")
                      (nil nil)))
   ;; Cannot use `process' slot because we cannot completely
   ;; change the type of a slot, just make it more specific.
   (handle :documentation "Database handle."
           :accessor emacsql-process))
  (:documentation "A connection to a SQLite database using a module."))

(cl-defmethod initialize-instance :after
  ((connection emacsql-sqlite-module-connection) &rest _)
  (setf (emacsql-process connection)
        (sqlite3-open (or (slot-value connection 'file) ":memory:")
                      sqlite-open-readwrite
                      sqlite-open-create))
  (when emacsql-global-timeout
    (emacsql connection [:pragma (= busy-timeout $s1)]
             (/ (* emacsql-global-timeout 1000) 2)))
  (emacsql-register connection))

(cl-defun emacsql-sqlite-module (file &key debug)
  "Open a connected to database stored in FILE.
If FILE is nil use an in-memory database.

:debug LOG -- When non-nil, log all SQLite commands to a log
buffer. This is for debugging purposes."
  (let ((connection (make-instance #'emacsql-sqlite-module-connection
                                   :file file)))
    (when debug
      (emacsql-enable-debugging connection))
    connection))

(cl-defmethod emacsql-live-p ((connection emacsql-sqlite-module-connection))
  (and (emacsql-process connection) t))

(cl-defmethod emacsql-close ((connection emacsql-sqlite-module-connection))
  (sqlite3-close (emacsql-process connection))
  (setf (emacsql-process connection) nil))

(cl-defmethod emacsql-send-message
  ((connection emacsql-sqlite-module-connection) message)
  (let (rows)
    (condition-case err
        (sqlite3-exec (emacsql-process connection)
                      message
                      (lambda (_ row __)
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
    (nreverse rows)))

(cl-defmethod emacsql ((connection emacsql-sqlite-module-connection) sql &rest args)
  (emacsql-send-message connection (apply #'emacsql-compile connection sql args)))

;;; _
(provide 'emacsql-sqlite-module)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; emacsql-sqlite-module.el ends here
