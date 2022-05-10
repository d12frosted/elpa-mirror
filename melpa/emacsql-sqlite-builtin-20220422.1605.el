;;; emacsql-sqlite-builtin.el --- EmacSQL back-end for SQLite using builtin support  -*- lexical-binding:t -*-

;; Copyright (C) 2021-2022 Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/emacscollective/emacsql-sqlite-builtin
;; Keywords: data
;; Package-Version: 20220422.1605
;; Package-Commit: 3e820c66fdaa9937f9e612900954dcd6c7d01943

;; Package-Requires: (
;;     (emacs "29")
;;     (emacsql "3.0.0")
;;     (emacsql-sqlite "3.0.0"))

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

;; An alternative EmacsSQL back-end for SQLite, which uses the builtin
;; support added in Emacs 29.

;;; Code:

(require 'sqlite)
(require 'emacsql)
;; For `emacsql-sqlite-reserved' and `emacsql-sqlite-condition-alist'.
(require 'emacsql-sqlite)

(defclass emacsql-sqlite-builtin-connection (emacsql-connection)
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
  (:documentation "A connection to a SQLite database using builtin support."))

(cl-defmethod initialize-instance :after
  ((connection emacsql-sqlite-builtin-connection) &rest _)
  (setf (emacsql-process connection)
        (sqlite-open (slot-value connection 'file)))
  (when emacsql-global-timeout
    (emacsql connection [:pragma (= busy-timeout $s1)]
             (/ (* emacsql-global-timeout 1000) 2)))
  (emacsql-register connection))

(cl-defun emacsql-sqlite-builtin (file &key debug)
  "Open a connected to database stored in FILE.
If FILE is nil use an in-memory database.

:debug LOG -- When non-nil, log all SQLite commands to a log
buffer. This is for debugging purposes."
  (let ((connection (make-instance #'emacsql-sqlite-builtin-connection
                                   :file file)))
    (when debug
      (emacsql-enable-debugging connection))
    connection))

(cl-defmethod emacsql-live-p ((connection emacsql-sqlite-builtin-connection))
  (and (emacsql-process connection) t))

(cl-defmethod emacsql-close ((connection emacsql-sqlite-builtin-connection))
  (sqlite-close (emacsql-process connection))
  (setf (emacsql-process connection) nil))

(cl-defmethod emacsql-send-message
  ((connection emacsql-sqlite-builtin-connection) message)
  (condition-case err
      (mapcar (lambda (row)
                (mapcar (lambda (col)
                          (cond ((null col) nil)
                                ((equal col "") "")
                                ((numberp col) col)
                                (t (read col))))
                        row))
              (sqlite-select (emacsql-process connection) message nil nil))
    ((db-error sql-error)
     (pcase-let ((`(,sym ,msg ,code) err))
       (signal (or (cadr (cl-assoc code emacsql-sqlite-condition-alist
                                   :test #'memql))
                   'emacsql-error)
               (list msg code sym))))
    (error
     (signal 'emacsql-error err))))

(cl-defmethod emacsql ((connection emacsql-sqlite-builtin-connection) sql &rest args)
  (emacsql-send-message connection (apply #'emacsql-compile connection sql args)))

;;; _
(provide 'emacsql-sqlite-builtin)
;; Local Variables:
;; indent-tabs-mode: nil
;; byte-compile-warnings: (not docstrings)
;; End:
;;; emacsql-sqlite-builtin.el ends here
