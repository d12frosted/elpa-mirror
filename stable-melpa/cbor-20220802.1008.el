;;; cbor.el --- CBOR utilities -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Óscar Nájera
;;
;; Author: Oscar Najera <https://oscarnajera.com>
;; Maintainer: Oscar Najera <hi@oscarnajera.com>
;; Version: 0.2.1
;; Package-Version: 20220802.1008
;; Package-Commit: c12d602284642206af5dbd36b2eec35763c0e46c
;; Homepage: https://github.com/Titan-C/cardano.el
;; Package-Requires: ((emacs "25.1") (dash "2.19.0"))
;;
;; This file is not part of GNU Emacs.
;;
;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Utility to decode and encode CBOR
;;
;; Heavily inspired by the work in
;;
;; https://inqlab.net/git/guile-cbor.git/
;;
;;; Code:

(require 'cl-lib)
(require 'dash)
(require 'json)
(require 'seq)

(defun cbor-hexstring->ascii (hex-string)
  "Convert HEX-STRING into ASCII string."
  (->> (string-to-list hex-string)
       (-partition 2)
       (--map (string-to-number (concat it) 16))
       (apply #'unibyte-string)))

(defun cbor-string->hexstring (s)
  "Encode the string S into a hex string."
  (mapconcat
   (lambda (it) (format "%02x" it))
   s
   ""))

(cl-defstruct (cbor-tag (:constructor cbor-tag-create)
                        (:copier nil))
  number content)

(defun cbor--get-ints (string &optional little)
  "Convert byte STRING to integer.
Default to big-endian unless LITTLE is non-nil."
  (seq-reduce (lambda (acc n) (logior n (ash acc 8))) (if little (nreverse string) string) 0))

(defun cbor--consume! (bytes)
  "Consume N BYTES from the source string."
  (prog1 (buffer-substring (point) (+ (point) bytes))
    (forward-char bytes)))

(defun cbor--get-argument! (info)
  "Get argument meaning given INFO."
  (cond
   ((< info 24) info)
   ((= info 24) (cbor--get-ints (cbor--consume! 1)))
   ((= info 25) (cbor--get-ints (cbor--consume! 2)))
   ((= info 26) (cbor--get-ints (cbor--consume! 4)))
   ((= info 27) (cbor--get-ints (cbor--consume! 8)))
   ((= info 31) 'indefinite-length)
   (t 'malformed-input)))

(defun cbor--get-data-array! (item-count)
  "Get ITEM-COUNT number of array elements."
  (let (result)
    (if (eq 'indefinite-length item-count)
        (let ((value (cbor--get-data-item!)))
          (while (not (eq value 'break))
            (push value result)
            (setq value (cbor--get-data-item!))))
      (dotimes (_ item-count)
        (push (cbor--get-data-item!) result)))
    (vconcat (nreverse result))))

(defun cbor--get-data-map! (pair-count)
  "Get PAIR-COUNT number of map elements."
  (let (result)
    (if (eq 'indefinite-length pair-count)
        (let ((key (cbor--get-data-item!)))
          (while (not (eq key 'break))
            (push (cons key (cbor--get-data-item!)) result)
            (setq key (cbor--get-data-item!))))
      (dotimes (_ pair-count)
        (push (cons (cbor--get-data-item!) (cbor--get-data-item!)) result)))
    (nreverse result)))

(defun cbor--get-data-item! ()
  "Read a single CBOR data item."
  (let* ((initial-byte (string-to-char (cbor--consume! 1)))
         ;; major type is in the higher-order 3 bits
         (major-type (ash initial-byte -5))
         ;; additional information is in the lower-order 5 bits (string-to-number "00011111" 2) =>31
         (additional-information (logand initial-byte 31))
         (argument (cbor--get-argument! additional-information)))
    (pcase major-type
      ;; unsigned integer
      (0 argument)
      ;; negative integer
      (1 (- -1 argument))
      ;; bytestring are hex encoded
      (2 (cbor-string->hexstring (cbor--consume! argument)))
      ;; Text strings
      (3 (cbor--consume! argument))
      ;; array of data
      (4 (cbor--get-data-array! argument))
      ;; map of pairs of data items
      (5 (cbor--get-data-map! argument))
      ;; cbor tag
      (6 (cbor-tag-create :number argument :content (cbor--get-data-item!)))
      ;; simple values
      (7
       (pcase additional-information
         (20 :false) ;; False
         (21 t)
         (22 nil) ;; NULL
         (31 'break))))))

(defun cbor-hex-p (str)
  "Test if STR is a hex only."
  (string-match-p (rx line-start (+ hex) line-end) str))

(defun cbor->elisp (byte-or-hex-string)
  "Convert BYTE-OR-HEX-STRING into an Emacs Lisp object."
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert (if (and (zerop (mod (length byte-or-hex-string) 2))
                     (cbor-hex-p byte-or-hex-string))
                (cbor-hexstring->ascii byte-or-hex-string)
              byte-or-hex-string))
    (goto-char (point-min))
    (cbor--get-data-item!)))

;; Encoding
(defun cbor<-elisp (object)
  "Convert Emacs Lisp OBJECT into cbor encoded hex-string."
  (with-output-to-string (cbor--put-data-item! object)))

(defun cbor--put-initial-byte! (major-type additional-information)
  "Encode and push the first byte giving MAJOR-TYPE and ADDITIONAL-INFORMATION."
  (write-char
   (logior (ash major-type 5) additional-information)))

(defun cbor--ints->bytelist (uint)
  "Encode UINT into a list of bytes."
  (let (stream)
    (while (> uint 0)
      (push (logand uint 255) stream)
      (setq uint (ash uint -8)))
    (cl-case (length stream)
      ((1 2 4 8) stream)
      ((3 7) (cons 0 stream))
      (6 (append '(0 0) stream))
      (5 (append '(0 0 0) stream))
      (t (error "Interger to large to encode")))))

(defun cbor--put-ints! (major-type uint)
  "Push to the out stream the defined MAJOR-TYPE with quantity UINT."
  (if (< uint 24)
      (cbor--put-initial-byte! major-type uint)
    (let ((bytes (cbor--ints->bytelist uint)))
      (pcase (length bytes)
        (1 (cbor--put-initial-byte! major-type 24))
        (2 (cbor--put-initial-byte! major-type 25))
        (4 (cbor--put-initial-byte! major-type 26))
        (8 (cbor--put-initial-byte! major-type 27)))
      (mapc #'write-char bytes))))

(defun cbor--put-data-item! (value)
  "Encode Lisp VALUE into cbor list."
  (cond
   ((and (integerp value) (<= 0 value))
    (cbor--put-ints! 0 value))
   ((and (integerp value) (> 0 value))
    (cbor--put-ints! 1 (- -1 value)))
   ;; bytestring are hex encoded
   ((and (stringp value) (zerop (mod (length value) 2)) (cbor-hex-p value))
    (let ((rev-list
           (cbor-hexstring->ascii value)))
      (cbor--put-ints! 2 (length rev-list))
      (mapc #'write-char (string-to-list rev-list))))

   ;; Text strings
   ((stringp value)
    (progn
      (cbor--put-ints! 3 (length value))
      (princ value)))
   ;; array of data
   ((vectorp value)
    (progn
      (cbor--put-ints! 4 (length value))
      (mapc #'cbor--put-data-item! value)))
   ;; map of pairs of data items
   ((json-alist-p value)
    (progn
      (cbor--put-ints! 5 (length value))
      (mapc (lambda (key-value)
              (cbor--put-data-item! (car key-value))
              (cbor--put-data-item! (cdr key-value)))
            value)))
   ;; Cbor Tags
   ((cbor-tag-p value)
    (progn
      (cbor--put-ints! 6 (cbor-tag-number value))
      (cbor--put-data-item! (cbor-tag-content value))))
   ;; simple values
   ((eq :false value)
    (cbor--put-initial-byte! 7 20))
   ((eq t value)
    (cbor--put-initial-byte! 7 21))
   ((null value)
    (cbor--put-initial-byte! 7 22))))

(provide 'cbor)
;;; cbor.el ends here
