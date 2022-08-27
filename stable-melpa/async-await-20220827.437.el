;;; async-await.el --- Async/Await                   -*- lexical-binding: t; -*-

;; Copyright (C) 2017  chuntaro

;; Author: chuntaro <chuntaro@sakura-games.jp>
;; URL: https://github.com/chuntaro/emacs-async-await
;; Package-Version: 20220827.437
;; Package-Commit: e0d15e8057ed7520100bc50c5552278292ebcb07
;; Package-Requires: ((emacs "25.1") (promise "1.1") (iter2 "0.9.10"))
;; Version: 1.1
;; Keywords: async await convenience

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

;; This is a simple implementation of Async/Await.
;; Inspired by the Async/Await implementation of TypeScript.
;;
;; Usage:
;; See `async-await-examples.el' for details.
;;  https://raw.githubusercontent.com/chuntaro/emacs-async-await/master/examples/async-await-examples.el
;;  You can check the operation while downloading and running it interactively.
;;
;; (require 'async-await)
;;
;; ;; Please be sure to enable it when developing.
;; (promise-rejection-tracking-enable '((all-rejections . t)))
;;
;; (defun wait-async (n)
;;   (promise-new (lambda (resolve _reject)
;;                  (run-at-time n
;;                               nil
;;                               (lambda ()
;;                                 (funcall resolve n))))))
;;
;; (async-defun example2 ()
;;   (print (await (wait-async 0.5)))
;;   (message "---")
;;
;;   (print (await (wait-async 1.0)))
;;   (message "---")
;;
;;   (print (await (wait-async 1.5)))
;;   (message "---")
;;
;;   (message "await done"))
;;
;; (example2) =>
;;
;; 0.5
;;
;; ---
;;
;; 1.0
;;
;; ---
;;
;; 1.5
;;
;; ---
;; await done
;;
;; The result of the execution is outputted from the top to the bottom
;; like the order written in the code.  However, asynchronously!

;;; Code:

(require 'promise)
(require 'iter2)

(defconst async-await--is-error (cl-gensym "async/await--error"))

(defsubst async-await--iter-throw (iterator value)
  (iter-next iterator (list async-await--is-error iterator value)))

(defun async-await--awaiter (iterator)
  (promise-new
   (lambda (resolve reject)
     (cl-labels ((fulfilled (value)
                            (condition-case reason
                                (step (iter-next iterator value))
                              (iter-end-of-sequence (funcall resolve (cdr reason)))
                              (error (funcall reject reason))))
                 (rejected (value)
                           ;; Please implement `iter-throw'!
                           ;; Even if you raise an exception here, Promise will be swallowed.
                           ;; Therefore, it is included in the return value and propagated.
                           (condition-case reason
                               (step (async-await--iter-throw iterator value))
                             (iter-end-of-sequence (funcall resolve (cdr reason)))
                             (error (funcall reject reason))))
                 (step (result)
                       (promise-chain (promise-resolve result)
                         (then #'fulfilled #'rejected))))
       (condition-case nil
           (step (iter-next iterator))
         (iter-end-of-sequence nil))))))

(defsubst async-await--check-return-value (value)
  (when (and (consp value)
             (eq (car value) async-await--is-error))
    (iter-close (cl-second value))
    (signal 'error (list (cl-third value))))
  value)

;; (defmacro await (value)
;;   "When called internally in Async Function, wait until Promise is resolved.
;; VALUE can be any object other than Promise.
;;
;;  (async-defun foo-async ()
;;    (print (await (wait-async 0.5)))
;;    (print (await 3)))"
;;   (identity value)
;;   (error "`await' expression is only allowed within an async function"))

;;;###autoload
(defmacro async-defun (name arglist &rest body)
  "Define NAME as a Async Function which return Promise.
ARGLIST should take the same form as an argument list for a `defun'.
BODY should be a list of Lisp expressions.

 (defun wait-async (n)
   (promise-new (lambda (resolve _reject)
                  (run-at-time n
                               nil
                               (lambda ()
                                 (funcall resolve n))))))

 (async-defun foo-async ()
   (print (await (wait-async 0.5)))
   (message \"---\")

   (print (await (wait-async 1.0)))
   (message \"---\")

   (print (await (wait-async 1.5)))
   (message \"---\")

   (message \"await done\"))

 (foo-async)"
  (declare (doc-string 3) (indent 2))
  (cl-assert lexical-binding)
  (let* ((parsed-body (macroexp-parse-body body))
         (declarations (car parsed-body))
         (exps (macroexpand-all
                `(cl-macrolet
                     ((await (value)
                             `(async-await--check-return-value (iter-yield ,value))))
                   ,@(cdr parsed-body))
                macroexpand-all-environment)))
    `(defun ,name ,arglist
       ,@declarations
       (async-await--awaiter
        (funcall (iter2-lambda () ,exps))))))

;;;###autoload
(defmacro async-lambda (arglist &rest body)
  "Return a lambda Async Function which return Promise.
ARGLIST should take the same form as an argument list for a `defun'.
BODY should be a list of Lisp expressions.

 (defun wait-async (n)
   (promise-new (lambda (resolve _reject)
                  (run-at-time n
                               nil
                               (lambda ()
                                 (funcall resolve n))))))

 (setq foo-async (async-lambda ()
                   (print (await (wait-async 0.5)))
                   (message \"---\")

                   (print (await (wait-async 1.0)))
                   (message \"---\")

                   (print (await (wait-async 1.5)))
                   (message \"---\")

                   (message \"await done\")))

 (funcall foo-async)"
  (declare (doc-string 2) (indent defun))
  (cl-assert lexical-binding)
  (let ((exps (macroexpand-all
               `(cl-macrolet
                    ((await (value)
                            `(async-await--check-return-value (iter-yield ,value))))
                  ,@body)
               macroexpand-all-environment)))
    `(lambda ,arglist
       (async-await--awaiter
        (funcall (iter2-lambda () ,exps))))))

(defconst async-await-font-lock-keywords
  '(("(\\(async-defun\\)\\_>[ \t']*\\(\\(?:\\sw\\|\\s_\\)+\\)?"
     (1 font-lock-keyword-face)
     (2 font-lock-function-name-face nil t))))

(font-lock-add-keywords 'emacs-lisp-mode async-await-font-lock-keywords)

(declare-function make-autoload "autoload")

;;;###autoload
(defun async-await-advice-make-autoload (fn &rest args)
  "Advice function for `make-autoload'.
FN is original function and ARGS is list of arguments.
See \"For complex cases\" section in `make-autoload'."
  (seq-let (form file _expansion) args
    (let ((car (car-safe form)) expand)
      (cond
       ;; For complex cases, try again on the macro-expansion.
       ((and (eq car 'async-defun)
             (macrop car)
             (setq expand (let ((load-file-name file)) (macroexpand form)))
             (memq (car expand) '(progn prog1 defalias)))
        ;; Recurse on the expansion.
        (make-autoload expand file 'expansion))
       (t
        (apply fn args))))))

;;;###autoload
(advice-add 'make-autoload :around #'async-await-advice-make-autoload)

(add-to-list 'lisp-imenu-generic-expression
             (list nil (concat "^\\s-*(async-defun\\s-+\\(" lisp-mode-symbol-regexp "\\)") 1))

(provide 'async-await)
;;; async-await.el ends here
