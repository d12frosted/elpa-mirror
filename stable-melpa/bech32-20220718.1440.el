;;; bech32.el --- Bech32 library -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Óscar Nájera
;;
;; Author: Oscar Najera <https://oscarnajera.com>
;; Maintainer: Oscar Najera <hi@oscarnajera.com>
;; Version: 0.1.1
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
;; Bech32 encoder and decoder library.  It was heavily inspired on the
;; reference implementation by Pieter Wuille
;;
;; https://github.com/sipa/bech32/blob/master/ref/python/segwit_addr.py
;;
;;; Code:


(require 'dash)
(require 'cl-lib)
(require 'subr-x)

(defconst bech32-charset "qpzry9x8gf2tvdw0s3jn54khce6mua7l")
(defconst bech32-reverse-charset
  (-zip (string-to-list bech32-charset) (number-sequence 0 31)))

(defun bech32-polymod (values)
  "Internal function that computes the Bech32 checksum for VALUES (5-bit) list."
  (let ((generator '(#x3b6a57b2 #x26508e6d #x1ea119fa #x3d4233dd #x2a1462b3))
        (chk 1))
    (dolist (value values chk)
      (let ((top (ash chk -25)))
        (setq chk (logxor (ash (logand chk #x1ffffff) 5) value))
        (dolist (i (number-sequence 0 4))
          (when (= 1 (logand 1 (ash top (- i))))
            (setq chk (logxor chk (elt generator i)))))))))

(defun bech32-hrp-expand (hrp)
  "Expand the HRP into values for checksum computation."
  (append (--map (ash it -5) hrp)
          '(0)
          (--map (logand it 31) hrp)))

(defun bech32-create-checksum (hrp data)
  "Compute the checksum values given HRP and DATA (5-bit)."
  (let* ((values (append (bech32-hrp-expand hrp) data))
         (polymod
          (logxor 1 (bech32-polymod (append values '(0 0 0 0 0 0))))))
    (--map (logand 31 (ash polymod it))
           (number-sequence -25 0 5))))

(defun bech32-verify-checksum (hrp data)
  "Verify a checksum given HRP and converted DATA (5-bit) characters."
  (= 1 (bech32-polymod (append (bech32-hrp-expand hrp) data))))

(cl-defun bech32-convertbits (data frombits tobits padding)
  "General power-of-2 base conversion.
Take a DATA list with elements bounded by 2^FROMBITS to a new list
of elements bounded by 2^TOBITS.  PADDING is applied."
  (let ((acc 0)
        (bits 0)
        (maxv (- (ash 1 tobits) 1))
        result)
    (dolist (value data)
      (setq acc (logior value (ash acc frombits)))
      (cl-incf bits frombits)
      (while (>= bits tobits)
        (cl-decf bits tobits)
        (push (logand (ash acc (- bits)) maxv) result)))
    (when (and padding (> bits 0))
      (push (logand (ash acc (- tobits bits)) maxv) result))
    (reverse result)))

(defun bech32-tobase32 (data)
  "DATA is a list of 8 bit integers."
  (bech32-convertbits data 8 5 t))

(defun bech32-tobase256 (data)
  "DATA is a list of 5 bit integers."
  (bech32-convertbits data 5 8 nil))

(defun bech32-encode (hrp data)
  "Compute a Bech32 string given HRP and DATA (8-bit) values."
  (let ((data-5-bit (bech32-tobase32 data))
        (dc-hrp (downcase hrp)))
    (thread-last (append data-5-bit (bech32-create-checksum dc-hrp data-5-bit))
                 (mapcar (lambda (v) (elt bech32-charset v)))
                 concat
                 (concat dc-hrp "1"))))

(defun bech32-decode (bech32string)
  "Decode a BECH32STRING into HRP and data."
  (let* ((sections
          (split-string (downcase bech32string) "1"))
         (hrp (string-join (butlast sections) "1"))
         (values
          (--map (cdr (assoc it bech32-reverse-charset))
                 (car (last sections)))))
    (if (and (< 0 (length hrp))
             (-every #'numberp values)
             (< 5 (length values)) ;; At least checksum
             (bech32-verify-checksum hrp values))
        (cons hrp (bech32-tobase256 (nbutlast values 6)))
      (user-error "Invalid Bech32 string"))))

(provide 'bech32)
;;; bech32.el ends here
