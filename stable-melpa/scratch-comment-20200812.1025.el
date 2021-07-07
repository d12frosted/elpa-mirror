;;; scratch-comment.el --- Insert Elisp result as comment in scratch buffer  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 1.0.1
;; Package-Version: 20200812.1025
;; Package-Commit: cf3e967b4def1308b6ef1cfeedd2cf15ee6e226c
;; Keywords: convenience
;; Package-Requires: ((emacs "26.1"))
;; URL: https://github.com/conao3/scratch-comment.el

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

;; Insert Elisp result as comment in scratch buffer.

;; To use this package, just bind `scratch-comment-eval-sexp'

;;   (define-key lisp-interaction-mode-map "\C-j" 'scratch-comment-eval-sexp)

;; To restore,

;;   (define-key lisp-interaction-mode-map "\C-j" 'eval-print-last-sexp)


;;; Code:

(defgroup scratch-comment nil
  "Insert Elisp result as comment in scratch buffer."
  :prefix "scratch-comment-"
  :group 'tools
  :link '(url-link :tag "Github" "https://github.com/conao3/scratch-comment.el"))


;;; Functions

(defvar scratch-comment-buffer nil)

(defun scratch-comment--elisp--eval-last-sexp-print-value
    (value output &optional no-truncate char-print-limit)
  "Print VALUE to OUTPUT.
For NO-TRUNCATE and CHAR-PRINT-LIMIT see `eval-expression-get-print-arguments'.
see `elisp--eval-last-sexp-print-value'."
  (let* ((unabbreviated (let ((print-length nil) (print-level nil))
                          (prin1-to-string value)))
         (eval-expression-print-maximum-character char-print-limit)
         (print-length (unless no-truncate eval-expression-print-length))
         (print-level  (unless no-truncate eval-expression-print-level))
         (beg (point))
         end)
    (prog1 (prin1 value output)
      (let ((str (and char-print-limit (eval-expression-print-format value))))
	(if str (princ str output)))
      (setq end (point))
      (when (and (bufferp output)
		 (or (not (null print-length))
		     (not (null print-level)))
		 (not (string= unabbreviated
			       (buffer-substring-no-properties beg end))))
	(last-sexp-setup-props beg end value
			       unabbreviated
			       (buffer-substring-no-properties beg end))))))

(defun scratch-comment--elisp--eval-last-sexp (eval-last-sexp-arg-internal)
  "Evaluate sexp before point; print value in the echo area.
If EVAL-LAST-SEXP-ARG-INTERNAL is non-nil, print output into
current buffer.  If EVAL-LAST-SEXP-ARG-INTERNAL is `0', print
output with no limit on the length and level of lists, and
include additional formats for integers \(octal, hexadecimal, and
character).
see `elisp--eval-last-sexp'."
  (pcase-let*
      ((`(,_insert-value ,no-truncate ,char-print-limit)
        (eval-expression-get-print-arguments eval-last-sexp-arg-internal)))
    ;; Setup the lexical environment if lexical-binding is enabled.
    (scratch-comment--elisp--eval-last-sexp-print-value
     (let ((standard-output scratch-comment-buffer))
       (eval (eval-sexp-add-defvars (elisp--preceding-sexp)) lexical-binding))
     scratch-comment-buffer no-truncate char-print-limit)))

(defun scratch-comment--eval-last-sexp (eval-last-sexp-arg-internal)
  "Evaluate sexp before point; print value in the echo area.
Interactively, with a non `-' prefix argument, print output into
current buffer.

Normally, this function truncates long output according to the
value of the variables `eval-expression-print-length' and
`eval-expression-print-level'.  With a prefix argument of zero,
however, there is no such truncation.
Integer values are printed in several formats (decimal, octal,
and hexadecimal).  When the prefix argument is -1 or the value
doesn't exceed `eval-expression-print-maximum-character', an
integer value is also printed as a character of that codepoint.

If `eval-expression-debug-on-error' is non-nil, which is the default,
this command arranges for all errors to enter the debugger.

EVAL-LAST-SEXP-ARG-INTERNAL is interactive argument.

see `eval-last-sexp'."
  (interactive "P")
  (if (null eval-expression-debug-on-error)
      (scratch-comment--elisp--eval-last-sexp eval-last-sexp-arg-internal)
    (let ((value
	   (let ((debug-on-error elisp--eval-last-sexp-fake-value))
	     (cons (scratch-comment--elisp--eval-last-sexp eval-last-sexp-arg-internal)
		   debug-on-error))))
      (unless (eq (cdr value) elisp--eval-last-sexp-fake-value)
	(setq debug-on-error (cdr value)))
      (car value))))


;;; Main

;;;###autoload
(defun scratch-comment-eval-sexp ()
  "Eval sexp before point and print result as comment.
see `eval-print-last-sexp'."
  (interactive)
  (let ((orig-buf (current-buffer)))
    (with-temp-buffer
      (let ((scratch-comment-buffer (current-buffer)))
        (with-current-buffer orig-buf (scratch-comment--eval-last-sexp t))
        (string-rectangle (point-min) (point-min) ";;=> ")
        (when (< (line-end-position) (point-max))
          (string-rectangle (progn (goto-char (point-min)) (line-beginning-position 2))
                            (progn (goto-char (point-max)) (line-beginning-position))
                            ";;   "))
        (let ((str (buffer-substring (point-min) (point-max))))
          (with-current-buffer orig-buf
            (insert "\n")
            (insert str)
            (insert "\n")))))))

(provide 'scratch-comment)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; scratch-comment.el ends here
