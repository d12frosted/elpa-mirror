;;; cbor.el --- CBOR utilities -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Óscar Nájera
;;
;; Author: Oscar Najera <https://oscarnajera.com>
;; Maintainer: Oscar Najera <hi@oscarnajera.com>
;; Version: 0.2.5
;; Package-Version: 20230606.1150
;; Package-Commit: cf85424b305e8f89debb756dc67eebc84639f711
;; Homepage: https://github.com/Titan-C/cardano.el
;; Package-Requires: ((emacs "25.1"))
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

(require 'hex-util)
(require 'cl-lib)
(require 'json)
(require 'seq)

(cl-defstruct (cbor-tag (:constructor cbor-tag-create)
                        (:copier nil))
  number content)

(defun cbor--get-ints (string &optional little)
  "Convert byte STRING to integer.
Default to big-endian unless LITTLE is non-nil."
  (seq-reduce (lambda (acc n) (logior n (ash acc 8))) (if little (reverse string) string) 0))

(defun cbor--luint (value size &optional little)
  "Convert VALUE into list of SIZE bytes.
Default to big endian unless LITTLE is non-nil."
  (let ((bytes
         (cl-loop for num = value then (ash num -8)
                  repeat size
                  collect (logand num #xff))))
    (if little bytes (nreverse bytes))))

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
      (2 (encode-hex-string (cbor--consume! argument)))
      ;; Text strings
      (3 (decode-coding-string (cbor--consume! argument) 'utf-8))
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
         (22 :null) ;; NULL
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
                (decode-hex-string byte-or-hex-string)
              byte-or-hex-string))
    (goto-char (point-min))
    (cbor--get-data-item!)))

;; Encoding
(defun cbor<-elisp (object)
  "Convert Emacs Lisp OBJECT into cbor encoded hex-string."
  (with-temp-buffer
    (let ((standard-output (current-buffer)))
      (set-buffer-multibyte nil)
      (cbor--put-data-item! object))
    (buffer-string)))

(defun cbor--put-initial-byte! (major-type additional-information)
  "Encode and push the first byte giving MAJOR-TYPE and ADDITIONAL-INFORMATION."
  (write-char
   (logior (ash major-type 5) additional-information)))

(defun cbor-uint-needed-size (uint)
  "Return standard required sized to store UINT up to 8 bytes."
  (pcase (ceiling (log (1+ uint) 256))
    (1 1)
    (2 2)
    ((or 3 4) 4)
    ((or 5 6 7 8) 8)
    (_ (error "Interger to large to encode"))))

(defun cbor--put-ints! (major-type uint)
  "Push to the out stream the defined MAJOR-TYPE with quantity UINT."
  (if (< uint 24)
      (cbor--put-initial-byte! major-type uint)
    (let ((size (cbor-uint-needed-size uint)))
      (pcase size
        (1 (cbor--put-initial-byte! major-type 24))
        (2 (cbor--put-initial-byte! major-type 25))
        (4 (cbor--put-initial-byte! major-type 26))
        (8 (cbor--put-initial-byte! major-type 27)))
      (mapc #'write-char (cbor--luint uint size)))))

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
           (decode-hex-string value)))
      (cbor--put-ints! 2 (length rev-list))
      (mapc #'write-char (string-to-list rev-list))))

   ;; Text strings
   ((stringp value)
    (progn
      (cbor--put-ints! 3 (string-bytes value))
      (princ (encode-coding-string value 'utf-8))))
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
   ((eq :null value)
    (cbor--put-initial-byte! 7 22))))

(provide 'cbor)
;;; cbor.el ends here
