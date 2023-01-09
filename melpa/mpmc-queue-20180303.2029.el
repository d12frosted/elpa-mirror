;;; mpmc-queue.el --- a multiple-producer-multiple-consumer queue -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Sho Mizoe

;; Author:  Sho Mizoe <sho.mizoe@gmail.com>
;; URL: https://github.com/smizoe/mpmc-queue
;; Version: 0.1.1
;; Keywords: lisp, async
;; Package-Requires: ((emacs "26.0") (queue "0.2.0"))

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

;; a wrapper for queue.el, which makes it a mpmc queue

;;; Code:

(require 'queue)
(cl-defstruct
    (mpmc-queue
     (:constructor nil)
     (:constructor mpmc-queue--create (&key
                                       (internal-queue (make-queue))
                                       (mutex (make-mutex))
                                       &aux
                                       (non-empty-condition (make-condition-variable mutex))
                                       )
                   )
     (:copier nil)
     )
  internal-queue
  mutex
  non-empty-condition
  )

(defmacro mpmc-queue--with-mutex (mpmcq &rest body)
  "While taking the mutex of mpmc-queue MPMCQ, evaluate BODY."
  `(with-mutex (mpmc-queue-mutex ,mpmcq) ,@body)
  )


(defun mpmc-queue-get (mpmcq &optional non-blocking)
  "Get the first element from mpmc-queue MPMCQ.
If NON-BLOCKING is t, return nil immediately if the queue is empty.
Otherwise block until an element is available."
  (mpmc-queue--with-mutex mpmcq
                    (unless (and non-blocking (queue-empty (mpmc-queue-internal-queue mpmcq)))
                        (while (queue-empty (mpmc-queue-internal-queue mpmcq))
                          (condition-wait (mpmc-queue-non-empty-condition mpmcq))
			  )
                        (cl-assert (not (queue-empty (mpmc-queue-internal-queue mpmcq)))
                                   nil
                                   "the queue was empty but mpmc-queue-get exited stopped waiting for an element addition.")
                        (queue-dequeue (mpmc-queue-internal-queue mpmcq))
                        )
                      )
  )


(defun mpmc-queue-peek (mpmcq &optional non-blocking)
  "Return the value at the head of MPMCQ.
If NON-BLOCKING is t and the queue is empty, return nil immediately.
Otherwise block until an element is available."
  (mpmc-queue--with-mutex mpmcq
                    (unless (and non-blocking (queue-empty (mpmc-queue-internal-queue mpmcq)))
                        (while (queue-empty (mpmc-queue-internal-queue mpmcq))
                          (condition-wait (mpmc-queue-non-empty-condition mpmcq))
                          )
                        (cl-assert (not (queue-empty (mpmc-queue-internal-queue mpmcq)))
                                   nil
                                   "the queue was empty but mpmc-queue-peek exited stopped waiting for an element addition.")
                        (queue-first (mpmc-queue-internal-queue mpmcq))
                      )
                    )
  )

(defun mpmc-queue-put (mpmcq elem)
  "Given MPMCQ, append ELEM to it."
  (mpmc-queue--with-mutex mpmcq
                    (queue-enqueue
                      (mpmc-queue-internal-queue mpmcq)
                      elem
                      )
		    (condition-notify (mpmc-queue-non-empty-condition mpmcq))
                    )
  )

(defun mpmc-queue-empty-p (mpmcq)
  "Check if MPMCQ is empty and return t if it's empty."
  (mpmc-queue--with-mutex mpmcq
              (let ((internal-queue (mpmc-queue-internal-queue mpmcq)))
                (queue-empty internal-queue)
                )
              )
  )

(provide 'mpmc-queue)
;;; mpmc-queue.el ends here
