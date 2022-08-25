;;; geoip.el --- Find out where an IP address is located via GeoIP2  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Xu Chunyang

;; Author: Xu Chunyang
;; Homepage: https://github.com/xuchunyang/geoip.el
;; Package-Requires: ((emacs "25.1"))
;; Package-Version: 20200310.911
;; Package-Commit: b4952890993642c7055f4bbbf05b0384740f8f51
;; Keywords: tools
;; Version: 0

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

;; An Emacs Lisp library for reading the MaxMind DB file
;; <https://maxmind.github.io/MaxMind-DB/>.  It lets you look up information
;; about where an IP address is located.

;;; Code:

(require 'cl-lib)
(require 'subr-x)                       ; `string-join'

(defvar geoip-node-count)
(defvar geoip-record-size)
(defvar geoip-tree-size)
(defvar geoip-metadata)

(defun geoip-read-byte ()
  "Read one byte."
  (prog1 (following-char)
    (forward-char 1)))

(defun geoip-read-bytes (amt)
  "Read AMT bytes."
  (prog1 (buffer-substring-no-properties (point) (+ (point) amt))
    (forward-char amt)))

(defun geoip-peek-bytes (amt)
  "Peek AMT bytes."
  (buffer-substring-no-properties (point) (+ (point) amt)))

(defun geoip-bytes-to-unsigned (bytes)
  "Convert BYTES to unsigned int."
  (cl-loop for i from 0
           for n across (nreverse bytes)
           sum (* n (expt (expt 2 8) i))))

(defun geoip-byte-to-bits (byte)
  "Convert 1 BYTE to a list of 8 bits."
  (cl-loop for i from 7 downto 0
           collect (if (= (logand byte (expt 2 i)) 0)
                       0
                     1)))

(defun geoip-bytes-to-bits (bytes)
  "Convert BYTES to bits."
  (cl-mapcan #'geoip-byte-to-bits bytes))

(defun geoip-bytes-to-signed (bytes)
  "Convert BYTES to signed int."
  (let ((nbits (* 8 (length bytes)))
        (num (geoip-bytes-to-unsigned bytes)))
    (pcase (lsh num (- (1- nbits)))     ; sign
      (0 num)
      (1 (- num (expt 2 nbits))))))

(defun geoip-bits-to-unsigned (bits)
  "Convert BITS to unsigned."
  (cl-loop for i from (1- (length bits)) downto 0
           for b in bits
           sum (* b (expt 2 i))))

(defun geoip-bytes-to-float (bytes)
  "Convert BYTES to IEEE 754 float."
  (cl-assert (= (length bytes) 4))
  (let* ((bits (geoip-bytes-to-bits bytes))
         (sign (car bits))
         (e (geoip-bits-to-unsigned (cl-subseq bits 1 9)))
         (fraction (1+ (cl-loop for b in (cl-subseq bits 9)
                                for i from 1 to 23
                                sum (* b (expt 2 (- i)))))))
    (* (expt -1 sign) (expt 2 (- e 127)) fraction)))

(defun geoip-bytes-to-double (bytes)
  "Convert BYTES to IEEE 754 double."
  (cl-assert (= (length bytes) 8))
  (let* ((bits (geoip-bytes-to-bits bytes))
         (sign (car bits))
         (e (geoip-bits-to-unsigned (cl-subseq bits 1 12)))
         (fraction (1+ (cl-loop for b in (cl-subseq bits 12)
                                for i from 1 to 52
                                sum (* b (expt 2 (- i)))))))
    (* (expt -1 sign) (expt 2 (- e 1023)) fraction)))

(defun geoip-payload-size (initial-size)
  "Return the size of payload according to INITIAL-SIZE."
  (pcase initial-size
    (31 (+ 65821 (geoip-bytes-to-unsigned (geoip-read-bytes 3))))
    (30 (+ 285   (geoip-bytes-to-unsigned (geoip-read-bytes 2))))
    (29 (+ 29    (geoip-bytes-to-unsigned (geoip-read-bytes 1))))
    (_  initial-size)))

(defun geoip-read ()
  "Parse a data field at point and return the value."
  (let* ((c (geoip-read-byte))
         (type (lsh c -5))
         (initial-size (logand c #b00011111))
         size)
    (cond
     ((= type 0)
      (let ((type (+ 7 (geoip-read-byte))))
        (setq size (geoip-payload-size initial-size))
        (pcase type
          (8 (geoip-bytes-to-signed (geoip-read-bytes size)))
          (9 (geoip-bytes-to-unsigned (geoip-read-bytes size)))
          (10 (geoip-bytes-to-unsigned (geoip-read-bytes size)))
          (11 (vconcat
               (cl-loop repeat size
                        collect (geoip-read))))
          (12 'data-cache-container)
          (13 'end-marker)
          (14 (= size 1))
          (15 (geoip-bytes-to-float (geoip-read-bytes size))))))
     (t
      (unless (= type 1)
        (setq size (geoip-payload-size initial-size)))
      (pcase type
        (1 (geoip-read-data (geoip-read-pointer initial-size)))
        (2 (decode-coding-string (geoip-read-bytes size) 'utf-8))
        (3 (geoip-bytes-to-double (geoip-read-bytes size)))
        (4 (geoip-read-bytes size))
        (5 (geoip-bytes-to-unsigned (geoip-read-bytes size)))
        (6 (geoip-bytes-to-unsigned (geoip-read-bytes size)))
        (7 (cl-loop repeat size
                    collect (cons (intern (geoip-read)) (geoip-read)))))))))

(defun geoip-read-pointer (initial-size)
  "Read a pointer and return pointer value (that is, offset to data section).
INITIAL-SIZE is last 5 bits of the control byte."
  (let ((SS (lsh initial-size -3))
        (VVV (logand initial-size #b00111)))
    (pcase SS
      (0 (geoip-bytes-to-unsigned (unibyte-string VVV (geoip-read-byte))))
      (1 (+ 2048
            (geoip-bytes-to-unsigned
             (concat (unibyte-string VVV) (geoip-read-bytes 2)))))
      (2 (+ 526336
            (geoip-bytes-to-unsigned
             (concat (unibyte-string VVV) (geoip-read-bytes 3)))))
      (3 (geoip-bytes-to-unsigned (geoip-read-bytes 4))))))

(defun geoip-read-data (offset)
  "Read a data field at data section with OFFSET."
  (save-excursion
    ;; The 16 is the size of the data section separator
    (goto-char (1+ (+ geoip-tree-size 16 offset)))
    (geoip-read)))

(defun geoip-new-buffer (path)
  "Read PATH (a MaxMind DB file) and return a geoip buffer."
  (let ((buffer (generate-new-buffer
                 (format " *geoip: %s*" (expand-file-name path)))))
    (with-current-buffer buffer
      (set-buffer-multibyte nil)
      (insert-file-contents-literally path)
      (read-only-mode)
      (goto-char (point-max))
      (search-backward "\xab\xcd\xefMaxMind.com")
      (goto-char (match-end 0))
      (setq-local geoip-metadata (geoip-read))
      (setq-local geoip-node-count (alist-get 'node_count geoip-metadata))
      (setq-local geoip-record-size (alist-get 'record_size geoip-metadata))
      (setq-local geoip-tree-size (* (/ (* geoip-record-size 2) 8) geoip-node-count)))
    buffer))

(defun geoip-read-node (nbytes index)
  "Read a NBYTES length node at INDEX, return two record values."
  (goto-char (1+ (* index nbytes)))
  (let ((bits (geoip-bytes-to-bits (geoip-read-bytes nbytes))))
    (mapcar #'geoip-bits-to-unsigned
            (pcase nbytes
              (6
               (list (cl-subseq bits 0 24) (cl-subseq bits 24)))
              (7
               (list (append (cl-subseq bits 24 28) (cl-subseq bits 0 24))
                     (cl-subseq bits 28)))
              (8
               (list (cl-subseq bits 0 32)
                     (cl-subseq bits 32)))))))

(defun geoip-ipv4-to-bytes (ipv4)
  "Convert IPV4 to bytes."
  (apply #'unibyte-string
         (mapcar #'string-to-number (split-string ipv4 (rx ".")))))

(defun geoip-ipv4-bytes-to-ipv6-bytes (bytes)
  "Convert ipv4 BYTES to ipv6 bytes."
  (concat (make-string 10 0) (unibyte-string #xFF #xFF) bytes))

(defun geoip-string-pad-left (s len padding)
  "If S is shorter than LEN, pad it with PADDING on the left."
  (pcase (- len (length s))
    ((and (pred (< 0)) diff) (concat (make-string diff padding) s))
    (_ s)))

(defun geoip-ipv6-to-bytes (ipv6)
  "Convert IPV6 to bytes."
  ;; Expand :: as :0:0:0: to make sure `ipv6' has 8 numbers
  (let ((short (- 8 (length (split-string ipv6 "::?" t)))))
    (when (> short 0)
      (setq ipv6 (replace-regexp-in-string
                  "::"
                  (format ":%s:" (string-join (make-list short "0") ":"))
                  ipv6))))
  (apply #'unibyte-string
         (cl-mapcan (lambda (s)
                      (let ((s (geoip-string-pad-left s 4 ?0)))
                        (list (string-to-number (substring s 0 2) 16)
                              (string-to-number (substring s 2) 16))))
                    (split-string ipv6 ":" t))))

(defun geoip-parse-ip (ip version)
  "Parse IP then convert to VERSION."
  (let (this-version bytes)
    (cond
     ((string-match-p (rx (+ num) "." (+ num) "." (+ num) "." (+ num)) ip)
      (setq this-version 4
            bytes (geoip-ipv4-to-bytes ip)))
     ((string-match-p (rx ":") ip)
      (setq this-version 6
            bytes (geoip-ipv6-to-bytes ip)))
     (t (user-error "%s is either IPv4 nor IPv6 address" ip)))
    (pcase (list version this-version)
      ('(4 4) bytes)
      ('(6 6) bytes)
      (`(6 4) (geoip-ipv4-bytes-to-ipv6-bytes bytes))
      (`(4 6) (user-error "Can't convert IPv6 into IPv4 address")))))

(defun geoip-lookup (geoip-buffer ip)
  "Lookup IP with GEOIP-BUFFER."
  (with-current-buffer geoip-buffer
    (catch 'finish
      (let ((node-size (/ (* 2 geoip-record-size) 8))
            (node-index 0))
        (dolist (b (geoip-bytes-to-bits
                    (geoip-parse-ip ip (alist-get 'ip_version geoip-metadata))))
          (pcase (pcase b
                   (0 (car  (geoip-read-node node-size node-index)))
                   (1 (cadr (geoip-read-node node-size node-index))))
            ((pred (= geoip-node-count)) (throw 'finish nil))
            ((and (pred (< geoip-node-count)) data-index)
             (goto-char (1+ (+ (- data-index geoip-node-count) geoip-tree-size)))
             (throw 'finish (geoip-read)))
            (next-node (setq node-index next-node))))))))

(provide 'geoip)
;;; geoip.el ends here
