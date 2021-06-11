;;; c-eval.el --- Compile and run one-off C code snippets -*- lexical-binding: t -*-

;; Copyright 2021 Lassi Kortela
;; SPDX-License-Identifier: ISC

;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lassik/emacs-c-eval
;; Package-Version: 20210611.705
;; Package-Commit: fd129bfcb75475ac6820cc33862bd8efb8097fae
;; Package-Requires: ((emacs "24.5"))
;; Version: 0.1.0
;; Keywords: c languages

;; This file is not part of GNU Emacs.

;;; Commentary:

;; By analogy with the Lisp Interaction mode that comes with Emacs,
;; this package provides commands to instantly compile and run C code.

;; Use `c-eval-scratch' to get a buffer in which to write code. You
;; can also evaluate code from other buffers.

;; The following commands execute a C program from the current buffer:

;; * `c-eval-buffer'
;; * `c-eval-region'

;; The following commands evaluate C code from the minibuffer:

;; * `c-eval-expression'
;; * `c-eval-sizeof'

;;; Code:

(defvar c-eval-temp-directory nil)

(defvar c-eval-prelude
  '("#include <ctype.h>"
    "#include <inttypes.h>"
    "#include <limits.h>"
    "#include <stdbool.h>"
    "#include <stdint.h>"
    "#include <stdio.h>"
    "#include <stdlib.h>"
    "#include <string.h>"
    ""))

(defvar c-eval-expression-history nil)

(defvar c-eval-expression-template
  '("#define C_EVAL_EXP(exp) #exp" "\n"
    "int main(void) {" "\n"
    "  printf(\"%s == %" directive "\\n\","
    " C_EVAL_EXP(" expression "),"
    " (" expression "));" "\n"
    "  return EXIT_SUCCESS;" "\n"
    "}" "\n"))

(defvar c-eval-sizeof-template
  '("int main(void) {" "\n"
    "  printf(\"sizeof(%s) == %zu\\n\","
    " \"" type "\","
    " sizeof(" type "));" "\n"
    "  return EXIT_SUCCESS;" "\n"
    "}" "\n"))

(defvar c-eval-type-to-printf-alist
  '(("char *" . "s")
    ("int" . "d")
    ("intmax_t"  . "\" PRIdMAX \"")
    ("intptr_t"  . "\" PRIdPTR \"")
    ("long long" . "lld")
    ("long" . "ld")
    ("uintmax_t" . "\" PRIuMAX \"")
    ("uintptr_t" . "\" PRIuPTR \"")
    ("unsigned int" . "u")
    ("unsigned long long" . "llu")
    ("unsigned long" . "lu")))

;;;###autoload
(defun c-eval-scratch ()
  "Create or select the *c-eval-scratch* buffer."
  (interactive)
  (switch-to-buffer (get-buffer-create "*c-eval-scratch*"))
  (unless (eq 'c-mode major-mode)
    (c-mode))
  (when (= 0 (buffer-size))
    (dolist (line c-eval-prelude)
      (insert line "\n")))
  (current-buffer))

(defun c-eval--raw-string (string)
  "Internal function to evaluate the unadorned C program in STRING."
  (let* ((tmpdir
          (file-name-as-directory
           (or (and c-eval-temp-directory
                    (expand-file-name c-eval-temp-directory))
               (let ((tmp (getenv "TMPDIR")))
                 (and (not (equal "" tmp))
                      tmp))
               default-directory))))
    (with-temp-buffer
      (insert string)
      (write-region (point-min) (point-max) (concat tmpdir "c-eval.c")))
    (with-current-buffer (get-buffer-create "*c-eval-output*")
      (display-buffer (current-buffer))
      (let ((window (get-buffer-window (current-buffer))))
        ;; Scroll window to the end to ensure output is visible.
        (when window
          (with-selected-window window
            (goto-char (point-max)))))
      (setq default-directory tmpdir)
      (let ((p
             (start-process "c-eval"
                            (current-buffer)
                            "cc" "-o" "c-eval" "c-eval.c")))
        (set-process-sentinel p
                              (lambda (p what)
                                (when (and (equal "finished\n" what)
                                           (eq 'exit (process-status p))
                                           (= 0 (process-exit-status p)))
                                  (with-current-buffer
                                      (get-buffer-create "*c-eval-output*")
                                    (start-process "c-eval"
                                                   (current-buffer)
                                                   (concat default-directory
                                                           "c-eval"))))))))))

;;;###autoload
(defun c-eval-region (start end)
  "Compile and run text between START and END as C program."
  (interactive "r")
  (c-eval--raw-string (buffer-substring-no-properties start end)))

;;;###autoload
(defun c-eval-buffer ()
  "Compile and run accessible portion of buffer as C program."
  (interactive)
  (c-eval-region (point-min) (point-max)))

(defun c-eval--template (template &rest plist)
  "Internal function to expand TEMPLATE using PLIST and run the program."
  (with-temp-buffer
    (dolist (line c-eval-prelude)
      (insert line "\n"))
    (dolist (part template)
      (cond ((stringp part) (insert part))
            ((and (symbolp part) (not (null part)))
             (let ((value (plist-get plist part)))
               (if value (insert value)
                 (error "Template does not have %S" part))))
            (t (error "Bad template part: %S" part))))
    (c-eval-buffer)))

;;;###autoload
(defun c-eval-expression (type expression)
  "Compile and run C program that outputs the TYPE result of EXPRESSION."
  (interactive
   (let ((type (completing-read "C expression result type: "
                                c-eval-type-to-printf-alist nil t)))
     (if (equal "" type) (error "No type given")
         (list type
               (read-string "C expression: " nil
                            'c-eval-expression-history)))))
  (let ((directive
         (or (cdr (assoc type c-eval-type-to-printf-alist))
             (error "No known printf() directive for type %S" type))))
    (c-eval--template c-eval-expression-template
                      'directive directive
                      'expression expression)))

;;;###autoload
(defun c-eval-sizeof (type)
  "Compile and run C program that outputs sizeof(TYPE)."
  (interactive "sC eval sizeof: ")
  (c-eval--template c-eval-sizeof-template 'type type))

(provide 'c-eval)

;;; c-eval.el ends here
