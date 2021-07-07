;;; toml.el --- TOML (Tom's Obvious, Minimal Language) parser

;; Copyright (C) 2013 by Wataru MIYAGUNI

;; Author: Wataru MIYAGUNI <gonngo@gmail.com>
;; URL: https://github.com/gongo/emacs-toml
;; Package-Version: 20130903.1255
;; Package-Commit: 994644f9e68c383071eeee23389a7989b228c2d2
;; Keywords: toml parser
;; Version: 0.0.1

;; MIT License
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;; THE SOFTWARE.

;;; Commentary:

;; This is a library for parsing TOML (Tom's Obvious, Minimal
;; Language).

;; Learn all about TOML here: https://github.com/mojombo/toml

;; Inspired by json.el.  thanks!!

;;; Code:

(require 'parse-time)

(defconst toml->special-escape-characters
  '(?b ?t ?n ?f ?r ?\" ?\/ ?\\)
  "Characters which are escaped in TOML.

\\b     - backspace       (U+0008)
\\t     - tab             (U+0009)
\\n     - linefeed        (U+000A)
\\f     - form feed       (U+000C)
\\r     - carriage return (U+000D)
\\\"     - quote           (U+0022)
\\\/     - slash           (U+002F)
\\\\     - backslash       (U+005C)

notes:

 Excluded four hex (\\uXXXX).  Do check in `toml:read-escaped-char'")

(defconst toml->read-table
  (let ((table
         '((?t  . toml:read-boolean)
           (?f  . toml:read-boolean)
           (?\[ . toml:read-array)
           (?\" . toml:read-string))))
    (mapc (lambda (char)
            (push (cons char 'toml:read-start-with-number) table))
          '(?- ?0 ?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9))
    table))

(defconst toml->regexp-datetime
  "\\([0-9]\\{4\\}\\)-\\(0[1-9]\\|1[0-2]\\)-\\(0[1-9]\\|[1-2][0-9]\\|3[0-1]\\)T\\([0-1][0-9]\\|2[0-4]\\):\\([0-5][0-9]\\):\\([0-5][0-9]\\)Z"
  "Regular expression for a datetime (Zulu time format).")

(defconst toml->regexp-numeric
  "\\(-?[0-9]+[\\.0-9\\]*\\)"
  "Regular expression for a numeric.")

;; Error conditions

(put 'toml-error 'error-message "Unknown TOML error")
(put 'toml-error 'error-conditions '(toml-error error))

(put 'toml-string-error 'error-message "Bad string")
(put 'toml-string-error 'error-conditions
     '(toml-string-error toml-error error))

(put 'toml-string-escape-error 'error-message "Bad escaped string")
(put 'toml-string-escape-error 'error-conditions
     '(toml-string-escape-error toml-string-error toml-error error))

(put 'toml-string-unicode-escape-error 'error-message "Bad unicode escaped string")
(put 'toml-string-unicode-escape-error 'error-conditions
     '(toml-string-unicode-escape-error
       toml-string-escape-error
       toml-string-error toml-error error))

(put 'toml-boolean-error 'error-message "Bad boolean")
(put 'toml-boolean-error 'error-conditions
     '(toml-boolean-error toml-error error))

(put 'toml-datetime-error 'error-message "Bad datetime")
(put 'toml-datetime-error 'error-conditions
     '(toml-datetime-error toml-error error))

(put 'toml-numeric-error 'error-message "Bad numeric")
(put 'toml-numeric-error 'error-conditions
     '(toml-numeric-error toml-error error))

(put 'toml-start-with-number-error 'error-message "Bad start-with-number")
(put 'toml-start-with-number-error 'error-conditions
     '(toml-start-with-number-error toml-error error))

(put 'toml-array-error 'error-message "Bad array")
(put 'toml-array-error 'error-conditions
     '(toml-array-error toml-error error))

(put 'toml-key-error 'error-message "Bad key")
(put 'toml-key-error 'error-conditions
     '(toml-key-error toml-error error))

(put 'toml-keygroup-error 'error-message "Bad keygroup")
(put 'toml-keygroup-error 'error-conditions
     '(toml-keygroup-error toml-error error))

(put 'toml-value-error 'error-message "Bad readable value")
(put 'toml-value-error 'error-conditions
     '(toml-value-error toml-error error))

(put 'toml-redefine-keygroup-error 'error-message "Redefine keygroup error")
(put 'toml-redefine-keygroup-error 'error-conditions
     '(toml-redefine-keygroup-error toml-error error))

(put 'toml-redefine-key-error 'error-message "Redefine key error")
(put 'toml-redefine-key-error 'error-conditions
     '(toml-redefine-key-error toml-error error))

(defun toml:assoc (keys hash)
  "Example:

  (toml:assoc '(\"servers\" \"alpha\" \"ip\") hash)"
  (let (element)
    (catch 'break
      (dolist (k keys)
        (unless (toml:alistp hash) (throw 'break nil))
        (setq element (assoc k hash))
        (if element
            (setq hash (cdr element))
          (throw 'break nil)))
      element)))

(defun toml:alistp (alist)
  (if (listp alist)
      (catch 'break
        (dolist (al alist)
          (unless (consp al) (throw 'break nil)))
        t)
    nil))

(defun toml:end-of-line-p ()
  (looking-at "$"))

(defun toml:end-of-buffer-p ()
  (eq (point) (point-max)))

(defun toml:get-char-at-point ()
  (char-after (point)))

(defun toml:seek-beginning-of-next-line ()
  "Move point to beginning of next line."
  (forward-line)
  (beginning-of-line))

(defun toml:seek-readable-point ()
  "Move point forward, stopping readable point. (toml->read-table).

Skip target:

- whitespace (Tab or Space)
- comment line (start with hash symbol)"
  (toml:seek-non-whitespace)
  (while (and (not (toml:end-of-buffer-p))
              (char-equal (toml:get-char-at-point) ?#))
    (end-of-line)
    (unless (toml:end-of-buffer-p)
      (toml:seek-beginning-of-next-line)
      (toml:seek-non-whitespace))))

(defun toml:seek-non-whitespace ()
  "Move point forward, stopping before a char end-of-buffer or not in whitespace (tab and space)."
  (if (re-search-forward "[^ \t\n]" nil t)
      (backward-char)
    (re-search-forward "[ \t\n]+\\'" nil t)))

(defun toml:search-forward (regexp)
  "Search forward from point for regular expression REGEXP.
Move point to the end of the occurrence found, and return point."
  (when (looking-at regexp)
    (forward-char (length (match-string-no-properties 0)))
    t))

(defun toml:read-char (&optional char-p)
  "Read character at point.  Set point to next point.
If CHAR-P is nil, return character as string,
and not nil, return character as char.

Move point a character forward."
  (let ((char (toml:get-char-at-point)))
    (forward-char)
    (if char-p char
      (char-to-string char))))

(defun toml:read-escaped-char ()
  "Read escaped character at point.  Return character as string.
Move point to the end of read characters."
  (unless (eq ?\\ (toml:read-char t))
    (signal 'toml-string-escape-error (list (point))))
  (let* ((char (toml:read-char t))
         (special (memq char toml->special-escape-characters)))
    (cond
     (special (concat (list ?\\ char)))
     ((and (eq char ?u)
           (toml:search-forward "[0-9A-Fa-f]\\{4\\}"))
      (concat "\\u" (match-string 0)))
     (t (signal 'toml-string-unicode-escape-error (list (point)))))))

(defun toml:read-string ()
  "Read string at point that surrounded by double quotation mark.
Move point to the end of read strings."
  (unless (eq ?\" (toml:get-char-at-point))
    (signal 'toml-string-error (list (point))))
  (let ((characters '())
        (char (toml:read-char)))
    (while (not (eq char ?\"))
      (when (toml:end-of-line-p)
        (signal 'toml-string-error (list (point))))
      (push (if (eq char ?\\)
                (toml:read-escaped-char)
              (toml:read-char))
            characters)
      (setq char (toml:get-char-at-point)))
    (forward-char)
    (apply 'concat (nreverse characters))))

(defun toml:read-boolean ()
  "Read boolean at point.  Return t or nil.
Move point to the end of read boolean string."
  (cond
   ((toml:search-forward "true") t)
   ((toml:search-forward "false") nil)
   (t
    (signal 'toml-boolean-error (list (point))))))

(defun toml:read-datetime ()
  "Read datetime at point.
Return time list (seconds, minutes, hour, day, month and year).
Move point to the end of read datetime string."
  (unless (toml:search-forward toml->regexp-datetime)
    (signal 'toml-datetime-error (list (point))))
  (let ((seconds (string-to-number (match-string-no-properties 6)))
        (minutes (string-to-number (match-string-no-properties 5)))
        (hour    (string-to-number (match-string-no-properties 4)))
        (day     (string-to-number (match-string-no-properties 3)))
        (month   (string-to-number (match-string-no-properties 2)))
        (year    (string-to-number (match-string-no-properties 1))))
    (list seconds minutes hour day month year)))

(defun toml:read-numeric ()
  "Read numeric (integer or float) at point.  Return numeric.
Move point to the end of read numeric string."
  (unless (toml:search-forward toml->regexp-numeric)
    (signal 'toml-numeric-error (list (point))))
  (let ((numeric (match-string-no-properties 0)))
    (if (with-temp-buffer
          (insert numeric)
          (goto-char (point-min))
          (search-forward "." nil t 2)) ;; e.g. "0.21.1" is NG
        (signal 'toml-numeric-error (list (point)))
      (string-to-number numeric))))

(defun toml:read-start-with-number ()
  "Read string that start with number at point.
Move point to the end of read string."
  (cond
   ((looking-at toml->regexp-datetime) (toml:read-datetime))
   ((looking-at toml->regexp-numeric) (toml:read-numeric))
   (t
    (signal 'toml-start-with-number-error (list (point))))))

(defun toml:read-array ()
  (unless (eq ?\[ (toml:get-char-at-point))
    (signal 'toml-array-error (list (point))))
  (mark-sexp)
  (forward-char)
  (let (elements char-after-read)
    (while (not (char-equal (toml:get-char-at-point) ?\]))
      (push (toml:read-value) elements)
      (toml:seek-readable-point)
      (setq char-after-read (toml:get-char-at-point))
      (unless (char-equal char-after-read ?\])
        (if (char-equal char-after-read ?,)
            (progn
              (forward-char)
              (toml:seek-readable-point))
          (signal 'toml-array-error (list (point))))))
    (forward-char)
    (nreverse elements)))

(defun toml:read-value ()
  (toml:seek-readable-point)
  (if (toml:end-of-buffer-p) nil
    (let ((read-function (cdr (assq (toml:get-char-at-point) toml->read-table))))
      (if (functionp read-function)
          (funcall read-function)
        (signal 'toml-value-error (list (point)))))))

(defun toml:read-keygroup ()
  (toml:seek-readable-point)
  (let (keygroup)
    (while (and (not (toml:end-of-buffer-p))
                (char-equal (toml:get-char-at-point) ?\[))
      (if (toml:search-forward "\\[\\([a-zA-Z][a-zA-Z0-9_\\.]*\\)\\]")
          (let ((keygroup-string (match-string-no-properties 1)))
            (when (string-match "\\(_\\|\\.\\)\\'" keygroup-string)
              (signal 'toml-keygroup-error (list (point))))
            (setq keygroup (split-string (match-string-no-properties 1) "\\.")))
        (signal 'toml-keygroup-error (list (point))))
      (toml:seek-readable-point))
    keygroup))

(defun toml:read-key ()
  (toml:seek-readable-point)
  (if (toml:end-of-buffer-p) nil
    (if (toml:search-forward "\\([a-zA-Z][a-zA-Z0-9_]*\\) *= *")
        (let ((key (match-string-no-properties 1)))
          (when (string-match "_\\'" key)
            (signal 'toml-key-error (list (point))))
          key)
      (signal 'toml-key-error (list (point))))))

(defun toml:make-hashes (keygroup key value hashes)
  (let ((keys (append keygroup (list key))))
    (toml:make-hashes-of-alist hashes keys value)))

(defun toml:make-hashes-of-alist (hashes keys value)
  (let* ((key (car keys))
         (descendants (cdr keys))
         (element (assoc key hashes))
         (children (cdr element)))
    (setq hashes (delete element hashes))
    (if descendants
        (progn
          (setq element (toml:make-hashes-of-alist children descendants value))
          (add-to-list 'hashes (cons key element)))
      (progn
        (add-to-list 'hashes (cons key value))))))

(defun toml:read ()
  "Parse and return the TOML object following point."
  (let (current-keygroup
        current-key
        current-value
        hashes keygroup-history)
    (while (not (toml:end-of-buffer-p))
      (toml:seek-readable-point)

      ;; Check re-define keygroup
      (let ((keygroup (toml:read-keygroup)))
        (when keygroup
          (if (and (not (eq keygroup current-keygroup))
                   (member keygroup keygroup-history))
              (signal 'toml-redefine-keygroup-error (list (point)))
            (setq current-keygroup keygroup))))
      (add-to-list 'keygroup-history current-keygroup)

      (let ((elm (toml:assoc current-keygroup hashes)))
        (when (and elm (not (toml:alistp (cdr elm))))
          (signal 'toml-redefine-key-error (list (point)))))

      ;; Check re-define key (with keygroup)
      (setq current-key (toml:read-key))
      (when (toml:assoc (append current-keygroup (list current-key)) hashes)
        (signal 'toml-redefine-key-error (list (point))))

      (setq current-value (toml:read-value))
      (when current-value
        (setq hashes (toml:make-hashes current-keygroup
                                       current-key
                                       current-value
                                       hashes)))

      (toml:seek-readable-point))
    hashes))

(defun toml:read-from-string (string)
  "Read the TOML object contained in STRING and return it."
  (with-temp-buffer
    (insert string)
    (goto-char (point-min))
    (toml:read)))

(defun toml:read-from-file (file)
  "Read the TOML object contained in FILE and return it."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (toml:read)))

(provide 'toml)

;;; toml.el ends here
