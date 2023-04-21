;;; bech32.el --- Bech32 library -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Óscar Nájera
;;
;; Author: Oscar Najera <https://oscarnajera.com>
;; Maintainer: Oscar Najera <hi@oscarnajera.com>
;; Version: 0.2.1
;; Homepage: https://github.com/Titan-C/cardano.el
;; Package-Requires: ((emacs "26.1"))
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
;; Bech32 encoder and decoder library.  It was heavily inspired on the
;; reference implementation by Pieter Wuille
;;
;; https://github.com/sipa/bech32/blob/master/ref/python/segwit_addr.py
;;
;;; Code:

(require 'seq)
(require 'cl-lib)
(require 'subr-x)

(defconst bech32-charset "qpzry9x8gf2tvdw0s3jn54khce6mua7l")
(defconst bech32-reverse-charset (seq-map-indexed #'cons bech32-charset))

(defconst bech32-encodings '((bech32 . 1)
                             (bech32m . #x2bc830a3)))

(defsubst bech32-test-bit (int n)
  "Test if N bit is set in INT."
  (= 1 (logand 1 (ash int (- n)))))

(defun bech32-valid-hrp (str)
  "Check if STR is a valid string for human readable part."
  (cl-flet ((char-out-bounds (char) (not (<= 33 char 126))))
    (cond
     ((string-empty-p str) (user-error "Bech32: No human readable part"))
     ((> (length str) 83) (user-error "Bech32: Human readable part too long" ))
     ((cl-some #'char-out-bounds str)
      (user-error "Bech32: Invalid char '%c'" (cl-find-if #'char-out-bounds str)))
     (t t))))

(defun bech32-polymod (values)
  "Internal function that computes the Bech32 checksum for VALUES (5-bit) list."
  (let ((generator [#x3b6a57b2 #x26508e6d #x1ea119fa #x3d4233dd #x2a1462b3]))
    (seq-reduce
     (lambda (chk value)
       (apply #'logxor
              (logxor (ash (logand chk #x1ffffff) 5) value)
              (seq-map-indexed (lambda (v i) (if (bech32-test-bit chk (+ 25 i)) v 0)) generator)))
     values 1)))

(defun bech32-hrp-expand (hrp)
  "Expand the HRP into values for checksum computation."
  (append (mapcar (lambda (it) (ash it -5)) hrp)
          '(0)
          (mapcar (lambda (it) (logand it 31)) hrp)))

(defun bech32-create-checksum (encoding hrp data)
  "Compute the checksum values with ENCODING given HRP and DATA (5-bit)."
  (let ((polymod
         (logxor (cdr (assoc encoding bech32-encodings))
                 (bech32-polymod
                  (append (bech32-hrp-expand hrp) data '(0 0 0 0 0 0))))))
    (mapcar (lambda (it) (logand 31 (ash polymod it)))
            (number-sequence -25 0 5))))

(defun bech32-verify-checksum (hrp data)
  "Verify a checksum given HRP and converted DATA (5-bit) characters."
  (car
   (rassoc
    (bech32-polymod (append (bech32-hrp-expand hrp) data))
    bech32-encodings)))

(defun bech32-convertbits (data frombits tobits padding)
  "General power-of-2 base conversion.
Take a DATA list with elements bounded by 2^FROMBITS to a new list
of elements bounded by 2^TOBITS.  PADDING is applied."
  (let ((acc 0)
        (bits 0)
        (maxv (- (ash 1 tobits) 1))
        result)
    (seq-doseq (value data)
      (setq acc (logior value (ash acc frombits)))
      (cl-incf bits frombits)
      (while (>= bits tobits)
        (cl-decf bits tobits)
        (push (logand (ash acc (- bits)) maxv) result)))
    (when (and padding (> bits 0))
      (push (logand (ash acc (- tobits bits)) maxv) result))
    (nreverse result)))

(defun bech32-tobase32 (data)
  "DATA is a list of 8 bit integers."
  (bech32-convertbits data 8 5 t))

(defun bech32-tobase256 (data)
  "DATA is a list of 5 bit integers."
  (bech32-convertbits data 5 8 nil))

(defun bech32--encode (encoding hrp data-5-bit)
  "Compute a Bech32 string with ENCODING given HRP and DATA-5-BIT values."
  (cl-assert (cl-every (lambda (x) (< x 32)) data-5-bit))
  (cl-assert (assoc encoding bech32-encodings))
  (cl-assert (bech32-valid-hrp hrp))
  (let ((dc-hrp (downcase hrp)))
    (thread-last (append data-5-bit (bech32-create-checksum encoding dc-hrp data-5-bit))
                 (mapcar (lambda (v) (elt bech32-charset v)))
                 concat
                 (concat dc-hrp "1"))))

(defun bech32-encode (hrp data &optional encoding)
  "Compute a Bech32 string with ENCODING given HRP and DATA 8-bit values."
  (bech32--encode (or encoding 'bech32) hrp (bech32-tobase32 data)))

(defun bech32--decode (bech32string)
  "Decode a BECH32STRING into HRP and data."
  (pcase (cl-position ?1 bech32string :from-end t)
    ('nil (user-error "Bech32: no separating char"))
    (0 (user-error "Bech32: no human readable part"))
    ((and pos (guard (> pos (- (length bech32string) 7))))
     (user-error "Bech32: Checksum missing"))
    (pos (let ((hrp (downcase (substring bech32string 0 pos)))
               (data
                (mapcar (lambda (it) (cdr (assoc it bech32-reverse-charset)))
                        (downcase (substring bech32string (1+ pos))))))
           (bech32-valid-hrp hrp)
           (unless (cl-every #'numberp data)
             (user-error "Bech32: invalid data character"))
           (if-let ((encoding (bech32-verify-checksum hrp data)))
               (cons encoding (cons hrp (nbutlast data 6)))
             (user-error "Invalid Checksum"))))))

(defun bech32-decode (bech32string)
  "Decode a BECH32STRING into HRP and data."
  (cl-destructuring-bind (_encoding hrp . data) (bech32--decode bech32string)
    (cons hrp (bech32-tobase256 data))))

(provide 'bech32)
;;; bech32.el ends here
