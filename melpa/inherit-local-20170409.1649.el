;;; inherit-local.el --- Inherited buffer-local variables

;; Copyright (C) 2016 Shea Levy

;; Author: Shea Levy
;; URL: https://github.com/shlevy/inherit-local/tree-master/
;; Package-Version: 20170409.1649
;; Package-Commit: b1f4ff9c41f9d64e4adaf5adcc280b82f084cdc7
;; Version : 1.1.1
;; Package-Requires: ((emacs "24.3"))

;;; Commentary:

;; This package provides the infrastructure for "inherited"
;; buffer-local variables: Those whose values are not reflected
;; globally but are initially shared by child buffers.

;; Because there is no clear-cut definition of "child" (if I start erc
;; from my notmuch buffer, is there a real relationship there?), this
;; package doesn't decide what you mean by child.  Instead, it
;; provides hooks for determining when inheritance might be relevant
;; and a function for performing the inheritance on a given buffer.

;; As an example, suppose you have version 1.2 of the foo compiler
;; installed in your PATH, but your current project depends on
;; features added in the experimental foo-2.0, which you have
;; installed in /opt/foo-2.0.  You're often working on multiple
;; foo-lang projects at once, and your Emacs startup time is 45
;; minutes, so you don't want to globally modify your PATH.  If you
;; just do

;;   (setq-local exec-path (cons "/opt/foo/bin" exec-path))
;;   (put 'exec-path 'permanent-local t)

;; then you'll run into a problem, because foo-mode calls fooc inside
;; a with-temp-buffer call to capture the output!  Instead, you can do

;;   (inherit-local-permanent exec-path
;;     (cons "/opt/foo/bin" exec-path))
;;   (defun around-generate (orig name)
;;     (if (eq (aref name 0) ?\s)
;;         (let ((buf (funcall orig name)))
;;           (inherit-local-inherit-child buf)
;;           buf)
;;       (funcall orig name)))
;;   (advice-add 'generate-new-buffer :around #'around-generate)

;; and your local exec-path will be inherited by internal buffers
;; without affecting any others.

;;; Code:

(defvar-local inherit-local--variables (make-hash-table))

(put 'inherit-local--variables 'permanent-local t)

;;;###autoload
(defun inherit-local (variable)
  "Make VARIABLE (a symbol) inherited."
  (puthash variable nil inherit-local--variables))

(defun inherit-local-uninherit (variable)
  "Uninherit VARIABLE (a symbol)."
  (remhash variable inherit-local--variables))

(defun inherit-local-inherit-child (buffer)
  "Inherit inherited variables in BUFFER.
Returns 't' if there were any variables to inherit, 'nil' otherwise."
  (maphash
   (lambda (key ignored)
     (when (boundp key)
       (let ((val (symbol-value key)))
	 (with-current-buffer buffer
	   (make-local-variable key)
	   (set key val)))))
   inherit-local--variables)
  (not (eq (hash-table-count inherit-local--variables) 0)))

;;;###autoload
(defmacro inherit-local-permanent (var value)
  "Set VAR locally to VALUE, declare VAR permanent, inherit VAR."
  `(progn
     (setq-local ,var ,value)
     (put (quote ,var) 'permanent-local t)
     (inherit-local (quote ,var))))

(provide 'inherit-local)

;;; inherit-local.el ends here
