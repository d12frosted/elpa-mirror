;;; insert-random.el --- Insert random characters from various character sets -*- lexical-binding: t -*-

;; Copyright 2022 Lassi Kortela
;; SPDX-License-Identifier: ISC

;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lassik/emacs-insert-random
;; Package-Version: 20220622.1653
;; Package-Commit: 049567eeca639017ac2db786cefaf38af7273654
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.5"))
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Provides the following commands:

;; * `insert-random-lowercase'
;; * `insert-random-uppercase'
;; * `insert-random-alphabetic'
;; * `insert-random-alphanumeric'
;; * `insert-random-digits'
;; * `insert-random-hex-uppercase'
;; * `insert-random-hex-lowercase'

;; As well as a general-purpose `insert-random' command.

;; Use a prefix argument to say how many random characters to insert.

;; The main use cases are to generate:

;; - test input when writing code

;; - examples of hashes, numbers, etc. when writing documentation and
;;   specifications

;; For example:

;; - C-u 40 M-x insert-random-hex-lowercase gives a random git commit
;;   hash

;; - C-u 10 insert-random-alphanumeric can generate a random
;;   10-character password

;;; Code:

(defvar insert-random-last-count 10
  "How many random characters were inserted last time.

When `insert-random' and its kin are called as interactive
commands, the prefix argument says how many random characters to
insert.  If no prefix argument is given, the same count is used
as for the last command in the family.

This variable does not affect non-interactive use.")

(defvar insert-random-charset-history nil
  "History of previously used `insert-random' character sets.")

(defun insert-random--count (arg)
  "Internal function to get count from raw prefix argument ARG."
  (let ((count
         (cond ((integerp arg)
                arg)
               ((and (consp arg)
                     (integerp (car arg))
                     (null (cdr arg)))
                ;; C-u creates the list (4).
                ;; C-u C-u creates the list (16).
                ;; etc.
                (car arg))
               (t
                (let ((arg insert-random-last-count))
                  (if (integerp arg) arg 1))))))
    (setq insert-random-last-count count)
    count))

;;;###autoload
(defun insert-random (charset count)
  "Insert COUNT random characters from the string CHARSET."
  (interactive
   (list (read-from-minibuffer "Insert random characters from charset: "
                               (car insert-random-charset-history)
                               nil
                               nil
                               'insert-random-charset-history
                               (car insert-random-charset-history))
         (insert-random--count current-prefix-arg)))
  (when (zerop (length charset))
    (user-error "Empty character set"))
  (dotimes (_ count nil)
    (insert (elt charset (random (length charset))))))

(defmacro insert-random--define (symbol ranges)
  "Internal macro to define `insert-random-' SYMBOL command for RANGES."
  (let* ((docstring "Insert COUNT random characters from the set")
         (charset
          (with-temp-buffer
            (let ((i 0))
              (while (< i (length ranges))
                (let ((first-char (elt ranges i))
                      (last-char (elt ranges (1+ i))))
                  (setq docstring
                        (concat docstring
                                (format " %c-%c" first-char last-char)))
                  (dotimes (i (1+ (- last-char first-char)))
                    (insert (+ first-char i))))
                (setq i (+ i 2))))
            (setq docstring
                  (concat
                   docstring
                   ".\n\n"
                   "Interactively, the prefix argument gives the count.\n"
                   "With no prefix argument, use same as last time."))
            (buffer-string))))
    `(progn
       (defconst ,symbol ,charset
         "A character set from which to insert random characters.")
       (defun ,symbol (count)
         ,docstring
         (interactive (list (insert-random--count current-prefix-arg)))
         (insert-random ,symbol count)))))

(insert-random--define insert-random-lowercase "az")
(insert-random--define insert-random-uppercase "AZ")
(insert-random--define insert-random-alphabetic "azAZ")
(insert-random--define insert-random-alphanumeric "azAZ09")
(insert-random--define insert-random-digits "09")
(insert-random--define insert-random-hex-uppercase "09AF")
(insert-random--define insert-random-hex-lowercase "09af")

(provide 'insert-random)

;;; insert-random.el ends here
