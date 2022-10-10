;;; php-runtime.el --- Language binding bridge to PHP -*- lexical-binding: t -*-

;; Copyright (C) 2018 Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 28 Aug 2017
;; Version: 0.2.0
;; Package-Version: 20221009.1955
;; Package-Commit: 36e6ae862cb02104b5782a563f0a5846c00e0082
;; Keywords: processes php
;; URL: https://github.com/emacs-php/php-runtime.el
;; Package-Requires: ((emacs "25.1") (s "1.7"))

;; This file is NOT part of GNU Emacs.

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

;; Execute PHP code.  This package requires `php' command in runtime.
;;
;;     (string-to-number (php-runtime-eval "echo PHP_INT_MAX;"))
;;     ;; => 9.223372036854776e+18
;;
;;     (string-to-number (php-runtime-expr "PHP_INT_MAX")) ; short hand
;;

;;; Code:
(eval-when-compile
  (require 'cl-lib))
(require 'eieio)
(require 's)

(defgroup php-runtime nil
  "Language binding bridge to PHP."
  :tag "PHP Runtime"
  :group 'processes
  :group 'php)

(defcustom php-runtime-php-executable (or (executable-find "php") "php")
  "A command name or path to PHP executable."
  :group 'php-runtime
  :type 'string)

(defconst php-runtime-php-open-tag "<?php ")
(defconst php-runtime-error-buffer-name "*PHP Error Messages*")
(defconst php-runtime--null (eval-when-compile (char-to-string 0)))

(defvar php-runtime--kill-temp-output-buffer t)
(defvar php-runtime--eval-temp-script-name nil)

;; Utility functions
(defun php-runtime--temp-buffer ()
  "Return new temp buffer."
  (generate-new-buffer "*PHP temp*"))

(defun php-runtime--stdin-satisfied-p (obj)
  "Return t if the object `OBJ' is satisfied to stdin format.

for example, (get-buffer \"foo-buffer\"), '(:file . \"/path/to/file\")."
  (cond
   ((null obj) t)
   ((and (bufferp obj) (buffer-live-p obj) t))
   ((and (consp obj)
         (eq :file (car obj)) (stringp (cdr obj))) t)))

(defun php-runtime--code-satisfied-p (obj)
  "Return t if the object `OBJ' is satisfied to code format."
  (and (consp obj)
       (member (car obj) (list :file :string))
       (stringp (cdr obj))))

(defun php-runtime--save-temp-script (code)
  "Save `CODE' to temporary PHP script and return file path of it."
  (let ((file-path (or php-runtime--eval-temp-script-name
                       (expand-file-name "php-runtime-eval.php" temporary-file-directory))))
    (with-temp-file file-path
      (erase-buffer)
      (insert php-runtime-php-open-tag)
      (insert code))
    file-path))

(defun php-runtime-default-handler (status output)
  "Return OUTPUT, and raise error when STATUS is not 0."
  (if (eq 0 status)
      output
    (error output)))

(defun php-runtime-string-has-null-byte (string)
  "Return T when STRING has null bytes."
  (s-contains-p php-runtime--null string))

(defun php-runtime-quote-string (string)
  "Quote STRING for PHP's single quote literal."
  (concat "'" (s-replace "'" "\\'" (s-replace "\\" "\\\\" string)) "'"))

(defalias 'php-runtime-\' #'php-runtime-quote-string)


;; PHP Execute class

;;;###autoload
(defclass php-runtime-execute nil
  ((executable :initarg :executable :type string)
   (code   :initarg :code   :type (satisfies php-runtime--code-satisfied-p))
   (handler :initarg :handler :type function :initform #'php-runtime-default-handler)
   (stdin  :initarg :stdin  :type (satisfies php-runtime--stdin-satisfied-p) :initform nil)
   (stdout :initarg :stdout :type (or null buffer-live list) :initform nil)
   (stderr :initarg :stderr :type (or null buffer-live list) :initform nil)))

(cl-defmethod php-runtime-run ((php php-runtime-execute))
  "Execute PHP process using `php -r' with code and return status code.

This execution method is affected by the number of character limit of OS command
arguments.  You can check the limitation by command, for example
\(shell-command-to-string \"getconf ARG_MAX\") ."
  (let ((args (list (php-runtime--get-command-line-arg php))))
    (if (and (oref php stdin) (not (php-runtime--stdin-by-file-p php)))
        (php-runtime--call-php-process-with-input-buffer php args)
      (php-runtime--call-php-process php args))))

(cl-defmethod php-runtime-process ((php php-runtime-execute))
  "Execute PHP process using `php -r' with code and return output."
  (let ((status (php-runtime-run php))
        (output (with-current-buffer (php-runtime-stdout-buffer php)
                  (buffer-substring-no-properties (point-min) (point-max)))))
    (funcall (oref php handler) status output)))

(cl-defmethod php-runtime--call-php-process ((php php-runtime-execute) args)
  "Execute PHP Process by php-execute PHP and ARGS."
  (apply #'call-process (oref php executable)
         (php-runtime--get-input php) ;input
         (cons (php-runtime-stdout-buffer php)
               (oref php stderr))
         nil ; suppress display
         args))

(cl-defmethod php-runtime--call-php-process-with-input-buffer ((php php-runtime-execute) args)
  "Execute PHP Process with STDIN by php-execute PHP and ARGS."
  (unless (buffer-live-p (oref php stdin))
    (error "STDIN buffer is not available"))
  (with-current-buffer (oref php stdin)
    (apply #'call-process-region (point-min) (point-max)
           (oref php executable)
           nil ;delete
           (cons (php-runtime-stdout-buffer php)
                 (oref php stderr))
           nil ; suppress display
           args)))

(cl-defmethod php-runtime--get-command-line-arg ((php php-runtime-execute))
  "Return PHP command line string."
  (let ((code (oref php code)))
    (cl-case (car code)
      (:file (cdr code))
      (:string (concat "-r" (cdr code))))))

(cl-defmethod php-runtime--stdin-by-file-p ((php php-runtime-execute))
  "Return T if \(oref php stdin) is PHP file."
  (let ((stdin (oref php stdin)))
    (and (consp stdin)
         (eq :file (car stdin)))))

(cl-defmethod php-runtime--get-input ((php php-runtime-execute))
  "Return PHP input buffer or NIL."
  (if (php-runtime--stdin-by-file-p php)
      (cdr (oref php stdin))
    nil))

(cl-defmethod php-runtime-stdout-buffer ((php php-runtime-execute))
  "Return PHP output buffer."
  (let ((buf (oref php stdout)))
    (if (and buf (buffer-live-p buf))
        buf
      (oset php stdout (generate-new-buffer "*PHP output*")))))

;; PHP Execute wrapper function

;;;###autoload
(defun php-runtime-expr (php-expr &optional input-buffer)
  "Evalute and echo PHP expression PHP-EXPR.

Pass INPUT-BUFFER to PHP executable as STDIN."
  (php-runtime-eval (format "echo %s;" php-expr) input-buffer))

;;;###autoload
(defun php-runtime-eval (code &optional input-buffer)
  "Evalute PHP code CODE without open tag, and return buffer.

Pass INPUT-BUFFER to PHP executable as STDIN."
  (let ((executor (php-runtime-execute :code (if (php-runtime-string-has-null-byte code)
                                      (cons :file (php-runtime--save-temp-script code))
                                    (cons :string code))
                            :executable php-runtime-php-executable
                            :stderr (get-buffer-create php-runtime-error-buffer-name)))
        (temp-input-buffer (when (and input-buffer (not (bufferp input-buffer)))
                             (php-runtime--temp-buffer))))
    (when input-buffer
      (oset executor stdin
            (if (or (bufferp input-buffer)
                    (and (consp input-buffer) (eq :file (car input-buffer))))
                input-buffer
              (prog1 temp-input-buffer
                (with-current-buffer temp-input-buffer
                  (insert input-buffer))))))
    (unwind-protect
        (php-runtime-process executor)
      (when (and temp-input-buffer (buffer-live-p temp-input-buffer))
        (kill-buffer temp-input-buffer))
      (when php-runtime--kill-temp-output-buffer
        (kill-buffer (php-runtime-stdout-buffer executor))))))

(provide 'php-runtime)
;;; php-runtime.el ends here
