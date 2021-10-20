;;; cort.el --- Simplify extended unit test framework  -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2019 Naoya Yamashita <conao3@gmail.com>

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Maintainer: Naoya Yamashita <conao3@gmail.com>
;; Keywords: test lisp
;; Package-Version: 20211020.18
;; Package-Commit: 3f64a7b03a4c5b768ec21fd5987acd0d62d16c7b
;; Version: 7.2.0
;; URL: https://github.com/conao3/cort.el
;; Package-Requires: ((emacs "24.1") (ansi "0.4") (cl-lib "0.6"))

;; This program is free software: you can redistribute it and/or modify
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

;; Simplify extended unit test framework.

;;; Code:

(require 'cl-lib)
(require 'ansi)

(defgroup cort nil
  "Simplify elisp test framework."
  :group 'lisp)

(defcustom cort-silence nil
  "Do test with silence.
Output just dot when success test."
  :group 'cort
  :type 'boolean)

(defvar cort-test-cases nil
  "Test list such as ((TEST-NAME VALUE)...).")


;;; functions

(defun cort--alist-get (key alist &optional default)
  "Find the first element of ALIST whose `car' equals KEY and return its `cdr'.
If KEY is not found in ALIST, return DEFAULT.
For backward compatibility, TESTFN is always `eq'.

This function is `alist-get' polifill for Emacs < 25.1."
  (declare (indent 1))
  (let ((x (assq key alist)))
    (if x (cdr x) default)))

(defun cort--string-trim (str)
  "Trim STR of leading and trailing space like strings.

TRIM-LEFT and TRIM-RIGHT default to \"[ \\t\\n\\r]+\".
Original function is `string-trim'.
This function is polyfill for Emacs<24.4."
  (replace-regexp-in-string "\\`[ \t\n\r]*\\|[ \t\n\r]*\\'" "" str))

(defsubst cort-pp (sexp)
  "Return pretty printed SEXP string."
  (if (stringp sexp)
      sexp
    (replace-regexp-in-string "\n+$" "" (pp-to-string sexp))))


;;; Polifill

(defun cort--autoload-do-load (fundef &optional funname macro-only)
  "Polifill function for `autoload-do-load'.
Please see original function for FUNDEF, FUNNAME, MACRO-ONLY usage."
  (if (or (not (consp fundef)) (not (eq 'autoload (car fundef))))
      fundef
    (when (eq macro-only 'macro)
      (let ((kind (nth 4 fundef)))
        (when (not (or (eq kind t) (eq kind 'macro)))
          fundef)))
    (when purify-flag
      (error "Attempt to autoload %s while preparing to dump" (symbol-name funname)))
    (let ((kind (nth 4 fundef)))
      (unwind-protect
          (let ((ignore-errors (if (or (eq kind t) (eq kind 'macro)) nil macro-only)))
            (load (cadr fundef) ignore-errors t nil t))
        ;; FIXME: revert partially performed defuns
        ))
    (if (null funname)
        nil
      (let ((fun (indirect-function funname)))
        (if (equal fun fundef)
            (error "Autoloading file %s failed to define function %s"
                   (caar load-history)
                   (symbol-name funname))
          fun)))))

(defun cort--autoloadp (object)
  "Non-nil if OBJECT is an autoload.
see `autoloadp'."
  (eq 'autoload (car-safe object)))

(defun cort--macrop (object)
  "Non-nil if and only if OBJECT is a macro.
see `macrop'."
  (let ((def (indirect-function object)))
    (when (consp def)
      (or (eq 'macro (car def))
          (and (cort--autoloadp def) (memq (nth 4 def) '(macro t)))))))

(defun cort---macroexpand-1 (form &optional environment)
  "Polifill function for `macroexpand-1'.
Please see original function for FORM, ENVIRONMENT usage."
  (cond
   ((consp form)
    (let* ((head (car form))
           (env-expander (assq head environment)))
      (if env-expander
          (if (cdr env-expander)
              (apply (cdr env-expander) (cdr form))
            form)
        (if (not (and (symbolp head) (fboundp head)))
            form
          (let ((def (cort--autoload-do-load (symbol-function head) head 'macro)))
            (cond
             ;; Follow alias, but only for macros, otherwise we may end up
             ;; skipping an important compiler-macro (e.g. cl--block-wrapper).
             ((and (symbolp def) (cort--macrop def)) (cons def (cdr form)))
             ((not (consp def)) form)
             (t
              (if (eq 'macro (car def))
                  (apply (cdr def) (cdr form))
                form))))))))
   (t form)))

(defalias 'cort--macroexpand-1
  (if (fboundp 'macroexpand-1) 'macroexpand-1 'cort---macroexpand-1))


;;; deftest

(defmacro cort-deftest (name testlst)
  "Define a test case with the NAME.
TESTLST is list of forms as below.

basic         : (:COMPFUN GIVEN EXPECT BEFOREFN AFTERFN)
error testcase: (:cort-error EXPECTED-ERROR FORM)"
  (declare (indent 1))
  (let* ((count 0)
         (testlst* (eval testlst))
         (suffixp (< 1 (length testlst*))))
    `(progn
       ,@(mapcar (lambda (test)
                   (setq count (1+ count))
                   `(add-to-list 'cort-test-cases
                                 '(,(if suffixp
                                        (make-symbol
                                         (format "%s-%s" (symbol-name name) count))
                                      name)
                                   ,@test)))
                 testlst*))))


;;; generate

(defvar cort-generate-fn
  '((:macroexpand . (lambda (elm)
                      `(:equal
                        (cort--macroexpand-1 ',(car elm))
                        ',(cadr elm))))
    (:shell-command . (lambda (elm)
                        `(:string=
                          (cort--string-trim
                           (shell-command-to-string ,(car elm)))
                          ',(cadr elm))))
    (:string-match . (lambda (elm)
                         `(:string-match ,(cadr elm) ,(car elm))))
    (:string-match-p . (lambda (elm)
                         `(:string-match-p ,(cadr elm) ,(car elm))))))

(defmacro cort-generate (op form)
  "Return `cort-deftest' compare by OP for FORM."
  (declare (indent 1))
  (let ((fn (or (cort--alist-get op cort-generate-fn)
                (lambda (elm)
                  `(,op ,(car elm) ,(cadr elm))))))
    `',(mapcar fn (eval form))))

(defmacro cort-generate-with-hook (op beforefn afterfn form)
  "Return `cort-deftest' compare by OP for FORM.
Eval BEFOREFN and AFTERFN."
  (declare (indent 1))
  (let ((fn (or (cort--alist-get op cort-generate-fn)
                (lambda (elm)
                  `(,op ,(car elm) ,(cadr elm))))))
    `'((:eq nil nil ,beforefn)
       ,@(mapcar fn (eval form))
       (:eq nil nil ,afterfn))))

(defmacro cort-generate--macroexpand-let (letform form)
  "Return `cort-deftest' compare by `equal' for NAME, LETFORM FORM.

Example:
  (cort-deftest-with-macroexpand-let leaf/leaf
      ((leaf-expand-leaf-protect t))
    '(((prog1 'leaf
         (leaf-handler-leaf-protect leaf
           (leaf-init)))
       (leaf leaf
         :config (leaf-init)))))

   => (cort-deftest leaf/leaf
        '((:equal
           '(let ((leaf-expand-leaf-protect t))
             (macroexpand-1
              '(leaf leaf
                 :config (leaf-init))))
           (prog1 'leaf
              (leaf-handler-leaf-protect leaf
                (leaf-init))))))"
  `',(mapcar (lambda (elm)
               `(:equal
                 (let ,letform (macroexpand-1 ',(car elm)))
                 ',(cadr elm)))
             (cadr form)))

(defmacro cort-deftest-generate (name op form)
  "Define test named as NAME for FORM compare with OP."
  (declare (indent 2))
  `(cort-deftest ,name
     (cort-generate ,op
       ,form)))

(defmacro cort-deftest-generate-with-hook (name op beforefn afterfn form)
  "Define test named as NAME for FORM compare with OP.
Eval BEFOREFN and AFTERFN."
  (declare (indent 2))
  `(cort-deftest ,name
     (cort-generate-with-hook ,op
       ,beforefn
       ,afterfn
       ,form)))


;;; main

(defun cort-test-prune ()
  "Prune all test."
  (interactive)
  (setq cort-test-cases nil)
  (message "prune tests completed."))

(defun cort-test-run-1 ()
  "Actually execute test of `cort-test-cases'.
TEST expect (METHOD EXPECT GIVEN).
Evaluate GIVEN to check it match EXPECT.
Return list of (testc failc errorc)"
  (let ((testc  (length cort-test-cases))
        (failc  0)
        (errorc 0)
        (dots 0))
    (dolist (test (reverse cort-test-cases)
                  (list testc failc errorc))
      (let* ((name   (nth 0 test))
             (method (nth 1 test))
             (given  (nth 2 test))
             (expect (nth 3 test))
             (beforefn (nth 4 test))
             (afterfn  (nth 5 test))
             (method-errorp (eq method :cort-error))
             err-before err-after
             err res ret exp)
        (when beforefn
          (condition-case e (funcall beforefn) (error (setq err-before e))))

        (setq res
              (condition-case e
                  (cond
                   (method-errorp
                    (eval
                     `(condition-case err
                          ,(nth 3 test)
                        (,(nth 2 test) t))))
                   (t
                    (setq ret (eval given))
                    (setq exp (eval expect))
                    (funcall (intern (substring (symbol-name method) 1)) ret exp)))
                (error
                 (setq err e) nil)))

        (when afterfn
          (condition-case e (funcall afterfn res err ret exp) (error (setq err-after e))))

        (cond
         (err (cl-incf errorc))
         ((not res) (cl-incf failc)))

        (if res
            (if (not cort-silence)
                (with-ansi-princ
                 (format "%s %s\n" (cyan "[PASSED]") name))
              (princ ".")
              (cl-incf dots)
              (when (<= 60 dots) (princ "\n") (setq dots 0)))
          (unless (= -1 dots) (princ "\n") (setq dots -1))

          (with-ansi-princ
           (if err
               (format "%s %s\n" (magenta "<<ERROR>>") name)
             (format "%s %s\n" (red "[FAILED]") name)))

          (if method-errorp
              (with-ansi-princ
               (format "%s\n%s\n" (yellow "Given:") (cort-pp expect))
               (format "%s   %s\n" (yellow "Expected-error:") (cort-pp given))
               (format "%s %s\n" (yellow "Unexpected-error:") (cort-pp err)))
            (with-ansi-princ
             (format "< Tested with %s >\n" (yellow (prin1-to-string method)))
             (format "%s\n%s\n" (yellow "Given:") (cort-pp given))
             (if err
                 (format "%s %s\n" (yellow "Unexpected-error:") (cort-pp err))
               (format "%s\n%s\n" (yellow "Returned:") (cort-pp ret)))
             (format "%s\n%s\n" (yellow "Expected:") (cort-pp expect))
             (when (and (not err) (executable-find "diff"))
               (let ((retfile (make-temp-file
                               "cort-returned-" nil nil))
                     (expfile (make-temp-file
                               "cort-expected-" nil nil)))
                 (with-temp-file retfile
                   (insert (format "%s\n" (cort-pp ret))))
                 (with-temp-file expfile
                   (insert (format "%s\n" (cort-pp exp))))
                 (unwind-protect
                     (format "%s\n%s"
                             (yellow "Diff:")
                             (with-output-to-string
                               (call-process "diff" nil standard-output nil
                                             "-u" retfile expfile)))
                   (delete-file retfile)
                   (delete-file expfile))))
             (when err-before
               (format "%s %s\n" (yellow "Error-before-hook:") (cort-pp err-before)))
             (when err-after
               (format "%s %s\n" (yellow "Error-after-hook:") (cort-pp err-after)))))

          (princ "\n"))))))

(defun cort-test-run ()
  "Run all test."
  (with-ansi-princ
   "\n"
   (yellow (format "Running %d tests..." (length cort-test-cases))) "\n"
   (format "%s\n" (emacs-version)))

  (let* ((res    (cort-test-run-1))
         (testc  (nth 0 res))
         (failc  (nth 1 res))
         (errorc (nth 2 res)))

    (princ "\n\n")
    (if (or (< 0 failc) (< 0 errorc))
        (error
         (with-ansi
          (red (format "===== Run %2d Tests, %2d Expected, %2d Failed, %2d Errored on Emacs-%s ====="
                       testc (- testc failc errorc) failc errorc emacs-version))
          "\n\n"))
      (with-ansi-princ
       (blue (format "===== Run %2d Tests, %2d Expected, %2d Failed, %2d Errored on Emacs-%s ====="
                     testc (- testc failc errorc) failc errorc emacs-version))
       "\n\n"))))

(defun cort-test-run-silence ()
  "Run all test with silence."
  (let ((cort-silence t))
    (cort-test-run)))

(provide 'cort)
;;; cort.el ends here
