;;; semaphore.el --- Semaphore based on condition variables -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Herwig Hochleitner

;; Author: Herwig Hochleitner <herwig@bendlas.net>
;; Maintainer: Herwig Hochleitner <herwig@bendlas.net>
;; Version: 1.0.0
;; Package-Version: 20190607.1949
;; Package-Commit: ec4c485c8e4cff63805ecc25523a031a6c2ad7cd
;; Keywords: processes, unix
;; URL: http://github.com/webnf/semaphore.el
;; Package-Requires: ((emacs "26"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This requires the threading support of emacs26+

;;; Code:

(require 'eieio)
(require 'cl-lib)

(defclass semaphore ()
  ((-name :initarg :name)
   (-acquired :initform 0)
   (-released :initarg :available)
   (-mutex :type mutex)
   (-cvar :type condition-variable))
  "Semaphore based on two monotonically increasing counters and a condition variable")

(cl-defmethod initialize-instance :after ((inst semaphore) &rest _)
  (with-slots (-name) inst
    (let ((mutex (make-mutex -name)))
      (oset inst -mutex mutex)
      (oset inst -cvar (make-condition-variable mutex -name)))))

(defun semaphore-create (count &optional name)
  "Create a semaphore with COUNT initially available slots

   COUNT can be negative

   Use ‘semaphore-acquire’, to borrow a slot, and
   ‘semaphore-release’, to return it.

   Optional argument NAME for your convenience."
  (make-instance 'semaphore
                 :name name
                 :available count))

(cl-defmethod semaphore-acquire ((this semaphore))
  "Borrow a slot from the semaphore

   If there are no slots available, semaphore-acquire will block your thread, until there are.
   Don't do this on the main thread, or risk emacs freezing dead."
  (with-slots (-mutex -cvar) this
    (with-mutex -mutex
      (while (with-slots (-acquired -released) this
               (>= -acquired -released))
        (condition-wait -cvar))
      (with-slots (-acquired) this
        (oset this -acquired (+ 1 -acquired))))))

(cl-defmethod semaphore-release ((this semaphore))
  "Return a slot to the semaphore

   This will unblock one blocked acquirer, if any."
  (with-slots (-available -mutex -cvar) this
    (with-mutex -mutex
      (condition-notify -cvar)
      (with-slots (-released) this
        (oset this -released (+ 1 -released))))))

(cl-defmethod semaphore-name ((this semaphore))
  "Given name of the semaphore"
  (with-slots (-name) this -name))

(cl-defmethod semaphore-times-acquired ((this semaphore))
  "An absolute count of times acquired over lifetime of the semaphore"
  (with-slots (-acquired) this -acquired))

(cl-defmethod semaphore-mutex ((this semaphore))
  "Access to the semaphore's mutex. Be careful."
  (with-slots (-mutex) this -mutex))

(cl-defmethod semaphore-available ((this semaphore))
  "Get a current count of available slots

   Mostly for logging purposes.

   If you want to base any decision in the program on available
   count, you need to have the semaphore-available call and
   following action synchronized on the semaphore mutex.

   Not recommended, unless you have a pressing need and a
   convincing story about preventing deadlocks."
  (with-mutex (semaphore-mutex this)
    (with-slots (-acquired -released) this
      (- -released -acquired))))

(provide 'semaphore)

;;; semaphore.el ends here
