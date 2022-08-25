;;; bencoding.el --- Bencoding decoding and encoding     -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Xu Chunyang

;; Author: Xu Chunyang
;; Homepage: https://github.com/xuchunyang/bencoding.el
;; Package-Requires: ((emacs "25.1"))
;; Package-Version: 20200331.1102
;; Package-Commit: 409836f2cf4883826600de42519ee9cffeb48a11
;; Version: 0
;; Keywords: tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; An Emacs Lisp library for reading and writing Bencoding
;; <https://en.wikipedia.org/wiki/Bencode>

;;; Code:

(require 'cl-lib)
(require 'map)                          ; `map-into'
(require 'json)                         ; `json-alist-p'

(defvar bencoding-list-type 'list
  "Type to convert Bencoding lists to.
Must be one of `vector' and `list'.  Consider let-binding this around
your call to `bencoding-read' instead of `setq'ing it.")

(defvar bencoding-dictionary-type 'alist
  "Type to convert Bencoding dictionaries to.
Must be one of `alist' or `hash-table'.  Consider let-binding
this around your call to `bencoding-read' instead of `setq'ing it.")

(define-error 'bencoding-error "Bencoding error" 'error)
(define-error 'bencoding-end-of-file "End of file while parsing Bencoding"
  '(end-of-file bencoding-error))

(defun bencoding-read-byte ()
  "Read one byte."
  (if (eobp)
      (signal 'bencoding-end-of-file nil)
    (prog1 (following-char)
      (forward-char 1))))

(defun bencoding-peek-byte ()
  "Peek one byte."
  (if (eobp)
      (signal 'bencoding-end-of-file nil)
    (following-char)))

(defun bencoding-read-bytes (amt)
  "Read AMT bytes."
  (cl-assert (>= amt 0))
  (if (> amt (- (point-max) (point)))
      (signal 'bencoding-end-of-file nil)
    (let ((op (point)))
      (forward-char amt)
      (buffer-substring-no-properties op (point)))))

(defun bencoding-read-integer ()
  "Read the Bencoding integer following point, return an integer."
  (cond
   ((looking-at
     (rx (or "0" (and (opt "-") (in "1-9") (* (in "0-9"))))))
    (goto-char (match-end 0))
    (string-to-number (match-string 0)))
   (t (signal 'bencoding-error (list "Not a Bencoding integer at point")))))

(defun bencoding-read-end ()
  "Read the end mark ('e')."
  (pcase (bencoding-read-byte)
    (?e)
    (not-e (signal 'bencoding-error
                   (list "Not a Bencoding end mark 'e'" not-e)))))

(defun bencoding-read-byte-string ()
  "Read the Bencoding byte string following point, return a unibyte string."
  (let ((len (bencoding-read-integer)))
    (pcase (bencoding-read-byte)
      (?:)
      (not-: (signal 'bencoding-error (list "Not string separator ':'" not-:))))
    (bencoding-read-bytes len)))

(defun bencoding-read-list ()
  "Read the Bencoding list following point."
  (cl-loop until (= (bencoding-peek-byte) ?e)
           collect (bencoding-read) into l
           finally return (pcase-exhaustive bencoding-list-type
                            ('list l)
                            ('vector (vconcat l)))))

(defun bencoding-read-dictionary ()
  "Read the Bencoding dictionary following point."
  (cl-loop until (= (bencoding-peek-byte) ?e)
           collect (cons (bencoding-read) (bencoding-read)) into alist
           ;; All keys must be byte strings and must appear in lexicographical order.
           finally do
           (let ((keys (mapcar #'car alist)))
             (dolist (k keys)
               (unless (stringp k)
                 (signal 'bencoding-error
                         (list "wrong type of dictionary key" #'stringp k))))
             (unless (equal keys (sort (copy-sequence keys) #'string<))
               (signal 'bencoding-error
                       (list "Dictionary keys are not sorted in lexicographical order"
                             keys))))
           finally return
           (pcase-exhaustive bencoding-dictionary-type
             ('alist alist)
             ('hash-table (map-into alist 'hash-table)))))

(defun bencoding-read ()
  "Read and return the Bencoding object at point.
Advances point just past Bencoding object.

Bencoding integer is mapped to Emacs Lisp integer.  Bencoding byte
string is mapped to Emacs Lisp unibyte string.  Bencoding list is
mapped to Emacs Lisp list (default) or vector according to
`bencoding-list-type'.  Bencoding dictionary is mapped to Emacs Lisp
alist (default) or plist or hash-table according to
`bencoding-dictionary-type'."
  (cl-assert (not enable-multibyte-characters))
  (let ((b (bencoding-read-byte)))
    (pcase b
      (?i
       (prog1 (bencoding-read-integer)
         (bencoding-read-end)))
      ((guard (<= ?0 b ?9))
       (forward-char -1)
       (bencoding-read-byte-string))
      (?l
       (prog1 (bencoding-read-list)
         (bencoding-read-end)))
      (?d
       (prog1 (bencoding-read-dictionary)
         (bencoding-read-end)))
      (unknown
       (signal 'bencoding-error (list "Unknown data type" unknown))))))

(defun bencoding-read-from-string (string)
  "Read the Bencoding object contained in STRING and return it."
  (cl-assert (not (multibyte-string-p string)))
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert string)
    (goto-char (point-min))
    (bencoding-read)))

(defun bencoding-read-file (file)
  "Read the Bencoding object contained in FILE and return it."
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert-file-contents-literally file)
    (goto-char (point-min))
    (bencoding-read)))

(defun bencoding-encode-integer (integer)
  "Encode INTEGER as a Bencoding integer, return a unibyte string."
  (cl-assert (integerp integer))
  (format "i%de" integer))

(defun bencoding-encode-byte-string (string)
  "Encode STRING as a Bencoding byte string, return a unibyte string."
  (cl-assert (not (multibyte-string-p string)))
  (format "%d:%s" (length string) string))

(defun bencoding-encode-list (list-or-vector)
  "Encode LIST-OR-VECTOR as a Bencoding list, return a unibyte string."
  (format "l%se"
          (mapconcat #'bencoding-encode list-or-vector "")))

(defun bencoding-encode-dictionary (alist-or-hash-table)
  "Encode ALIST-OR-HASH-TABLE as a Bencoding dictionary.
Return a unibyte string."
  (let ((alist (pcase alist-or-hash-table
                 ((and (pred hash-table-p) ht) (map-into ht 'list))
                 (alist
                  ;; Make sure we don't alter the list structure
                  (copy-sequence alist)))))
    (setq alist
          (sort alist (pcase-lambda (`(,k1 . ,_)
                                     `(,k2 . ,_))
                        (string< k1 k2))))
    (cl-loop for (k . v) in alist
             concat (concat (bencoding-encode k) (bencoding-encode v)) into s
             finally return (concat "d" s "e"))))

(defun bencoding-encode (object)
  "Return a JSON representation of OBJECT as a unibyte string."
  (pcase object
    ((pred integerp) (bencoding-encode-integer object))
    ((pred stringp) (bencoding-encode-byte-string object))
    ((pred vectorp) (bencoding-encode-list object))
    ((pred hash-table-p) (bencoding-encode-dictionary object))
    ((pred listp) (if (json-alist-p object)
                      ;; Note `json-alist-p' treats nil as alist, so to get a
                      ;; empty bencoding list, use []
                      (bencoding-encode-dictionary object)
                    (bencoding-encode-list object)))))

(provide 'bencoding)
;;; bencoding.el ends here
