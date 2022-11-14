;;; glue.el --- Emacs - Common Lisp interop using SLIME or SLY        -*- lexical-binding: t; -*-

;; Copyright (C) 2014  Gabor Poczkodi

;; Author: Gabor Poczkodi <hajovonta@gmail.com>
;; URL: https://git.sr.ht/~hajovonta/glue/
;; Package-Version: 20221114.1120
;; Package-Commit: abfad405f240d9a89f792aae36efb3c2af43021f
;; Keywords: lisp emacs common lisp cl
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.1"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package aims to allow Common Lisp code to be run from within
;; Emacs Lisp.  SLIME/SLY must be connected before invoking the
;; functions.  Configuration of SLIME/SLY and CL is up to the user.
;; The thread-creating functions can be used to augment Emacs with
;; threads that run in Common Lisp.  Since it is possible to update
;; the Emacs side from within the threads, one can use it to offload
;; long-running processes to CL and retain a responsive Emacs.

;; (eval-in-emacs) function is injected to CL side to allow calls to
;; Emacs side to be independent of interaction-mode (SLIME or SLY)

;;; Code:

(defgroup glue-group nil
  "Glue Group."
  :group 'tools)

(defcustom glue-interaction 'slime
  "Set Glue interaction: SLIME or SLY."
  :group 'glue-group
  :type '(choice (const slime) (const sly)))

(declare-function slime-connected-p "ext:slime.el" ())
(declare-function slime-eval "ext:slime.el" (sexp &optional package))
(declare-function slime-eval-async "ext:slime.el" (sexp &optional cont package))
(declare-function sly-connected-p "ext:sly.el" ())
(declare-function sly-eval "ext:sly.el" (sexp &optional package cancel-on-input cancel-on-input-retval))
(declare-function sly-eval-async "ext:sly.el" (sexp &optional cont package env))

(defun glue--precheck ()
  "Checking whether the selected interaction package is installed/connected."
  (cond ((eq 'slime glue-interaction)
         (if (locate-library "slime")
             (if (slime-connected-p)
                 'slime
               (message "Not connected.")
               nil)
           (message "SLIME is not installed.")
           nil))
        ((eq 'sly glue-interaction)
         (if (locate-library "sly")
             (if (sly-connected-p)
                 'sly
               (message "Not connected.")
               nil)
           (message "SLY is not connected.")
           nil))))

(defun glue--slime-send-sync (cl-form)
  "Internal function for SLIME sync request.
Pass valid CL form as CL-FORM."
  (slime-eval
   `(cl:eval
     (cl:read-from-string
      ,(prin1-to-string
        `(flet ((eval-in-emacs (form) (swank:eval-in-emacs form)))
           ,cl-form))))))

(defun glue--sly-send-sync (cl-form)
  "Internal function for SLY sync request.
Pass valid CL form as CL-FORM."
  (sly-eval
   `(cl:eval
     (cl:read-from-string
      ,(prin1-to-string
        `(flet ((eval-in-emacs (form) (slynk:eval-in-emacs form)))
           ,cl-form))))))

(defun glue-send-sync (cl-form)
  "Run CL form synchronously and return result.
Pass valid CL form as CL-FORM."
  (let ((interaction (glue--precheck)))
    (cond ((eq 'slime interaction) (glue--slime-send-sync cl-form))
          ((eq 'sly interaction) (glue--sly-send-sync cl-form)))))

(defun glue--slime-send-async (cl-form continuation)
  "Internal function for SLIME async request.
Pass valid CL form as CL-FORM.
Pass a continuation function as CONTINUATION."
  (slime-eval-async
      `(cl:eval
        (cl:read-from-string
         ,(prin1-to-string
           `(flet ((eval-in-emacs (form) (swank:eval-in-emacs form)))
              ,cl-form))))
    `,continuation))

(defun glue--sly-send-async (cl-form continuation)
  "Internal function for SLY async request.
Pass valid CL form as CL-FORM.
Pass a continuation function as CONTINUATION."
  (sly-eval-async
   `(cl:eval
     (cl:read-from-string
      ,(prin1-to-string
        `(flet ((eval-in-emacs (form) (slynk:eval-in-emacs form)))
           ,cl-form))))
    `,continuation))

(defun glue-send-async (cl-form continuation)
  "Run CL form asynchronously.
Pass valid CL form as CL-FORM.
Pass result of form as argument to CONTINUATION."
  (let ((interaction (glue--precheck)))
    (cond ((eq 'slime interaction) (glue--slime-send-async cl-form continuation))
          ((eq 'sly interaction) (glue--sly-send-async cl-form continuation)))))

;; Two thread functions are provided. (glue-sbcl-thread) can be used
;; with SBCL only.  It has the advantage of not needing to load any
;; external libraries.  This starts a thread on SBCL side and returns
;; the string representation of the thread
;; object. (swank:eval-in-emacs) can be used from the thread to update
;; Emacs side.
;; Example call for slime-send-thread:
;; (glue-sbcl-thread "thread-name"
;;  '(progn (sleep 3) (swank:eval-in-emacs '(incf temp 10))))

(defun glue--slime-sbcl-thread (name-of-thread cl-form)
  "Internal function for SLIME SBCL thread request.
Pass the name of the thread as NAME-OF-THREAD.
Pass a valid CL form as CL-FORM."
  (slime-eval
   `(cl:eval
     (cl:format nil "~a"
                (sb-thread:make-thread #'(cl:lambda (conn)
                                                    (cl:let ((conn conn))
                                                            (swank::with-connection (conn)
                                                                                    (cl:eval
                                                                                     (cl:read-from-string
                                                                                      ,(prin1-to-string
                                                                                        `(flet ((eval-in-emacs (form) (swank:eval-in-emacs form)))
                                                                                           ,cl-form)))))))
                                       :name ,name-of-thread
                                       :arguments swank::*emacs-connection*)))))

(defun glue--sly-sbcl-thread (name-of-thread cl-form)
  "Internal function for SLY SBCL thread request.
Pass the name of the thread as NAME-OF-THREAD.
Pass a valid CL form as CL-FORM."
  (let ((string-representation (prin1-to-string
                                `(flet ((eval-in-emacs (form) (slynk:eval-in-emacs form)))
                                   (sb-thread:make-thread #'(cl:lambda (conn)
                                                                       (slynk::with-connection (conn)
                                                                                               (cl:eval ,cl-form)))
                                                          :name ,name-of-thread
                                                          :arguments slynk::*emacs-connection*)))))
    (sly-eval `(cl:format nil "~a" (cl:eval
                                    (cl:read-from-string
                                     ,string-representation))))))

(defun glue-sbcl-thread (name-of-thread cl-form)
  "Run a thread in SBCL.
Pass name of thread as NAME-OF-THREAD.
Pass valid CL form as CL-FORM."
  (let ((interaction (glue--precheck)))
    (cond ((eq 'slime interaction) (glue--slime-sbcl-thread name-of-thread cl-form))
          ((eq 'sly interaction) (glue--sly-sbcl-thread name-of-thread cl-form)))))

;; (glue-bt-thread) uses bordeaux-threads library, but this must be
;; loaded into CL before usage.
(defun glue--slime-bt-thread (name-of-thread cl-form)
  "Internal function for SLIME bordeaux-thread request.
Pass name of thread as NAME-OF-THREAD.
Pass valid CL form as CL-FORM."
  (slime-eval
   `(cl:eval
     (cl:format nil "~a"
                (cl:let ((conn swank::*emacs-connection*))
                        (bt:make-thread #'(cl:lambda ()
                                                     (swank::with-connection (conn)
                                                                             (cl:eval
                                                                              (cl:read-from-string
                                                                               ,(prin1-to-string
                                                                                 `(flet ((eval-in-emacs (form) (swank:eval-in-emacs form)))
                                                                                    ,cl-form))))))
                                        :name ,name-of-thread))))))

(defun glue--sly-bt-thread (name-of-thread cl-form)
  "Internal function for SLY bordeaux-thread request.
Pass name of thread as NAME-OF-THREAD.
Pass valid CL form as CL-FORM."
  (let ((string-representation (prin1-to-string `(flet ((eval-in-emacs (form) (slynk:eval-in-emacs form)))
                                                   (let ((conn slynk::*emacs-connection*))
                                                   (bt:make-thread #'(cl:lambda ()
                                                                                (slynk::with-connection (conn)
                                                                                                        (cl:eval ,cl-form)))
                                                                   :name ,name-of-thread))))))
    (sly-eval `(cl:format nil "~a" (cl:eval
                                    (cl:read-from-string
                                     ,string-representation))))))

(defun glue-bt-thread (name-of-thread cl-form)
  "Run a thread in any CL implementation with bordeaux-threads.
The library bordeaux-threads must be loaded into the image before usage.
Pass name of thread as NAME-OF-THREAD.
Pass valid CL form as CL-FORM."
  (let ((interaction (glue--precheck)))
    (cond ((eq 'slime interaction) (glue--slime-bt-thread name-of-thread cl-form))
          ((eq 'sly interaction) (glue--sly-bt-thread name-of-thread cl-form)))))

(provide 'glue)
;;; glue.el ends here
