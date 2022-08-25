;;; msgpack.el --- Read and write MessagePack object    -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Xu Chunyang

;; Author: Xu Chunyang
;; Homepage: https://github.com/xuchunyang/msgpack.el
;; Package-Requires: ((emacs "25.1"))
;; Package-Version: 20200323.515
;; Package-Commit: e2a0d76d1087bc8178c9f27222cb9b93e2e815ec
;; Keywords: lisp
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

;; Emacs Lisp library for MessagePack <https://msgpack.org/index.html>

;;; Code:

(require 'json)                         ; `json-alist-p'
(require 'cl-lib)
(require 'seq)                          ; `seq-partition'
(require 'map)                          ; `map-into'

(defvar msgpack-false :msgpack-false
  "Value to use when reading and writing MessagePack `false'.")

(defvar msgpack-null nil
  "Value to use when reading and writing MessagePack `null'.")

(defvar msgpack-array-type 'list
  "Type to convert MessagePack arrays to.
Must be one of `vector' or `list'.  Consider let-binding this around
your call to `msgpack-read' instead of `setq'ing it.")

(defvar msgpack-map-type 'alist
  "Type to convert MessagePack maps to.
Must be one of `alist', `plist', or `hash-table'.  Consider let-binding
this around your call to `msgpack-read' instead of `setq'ing it.  Ordering
is maintained for `alist' and `plist', but not for `hash-table'.")

(defvar msgpack-key-type nil
  "Type to convert MessagePack keys to, only for key that is string.
If the map's key is not string, this variable is ignored.

Must be one of `string', `symbol', `keyword', or nil.

If nil, `msgpack-read' will guess the type based on the value of
`msgpack-map-type':

    If `msgpack-map-type' is:   nil will be interpreted as:
      `hash-table'                `string'
      `alist'                     `symbol'
      `plist'                     `keyword'

Consider let-binding this around your call to `msgpack-read' instead of `setq'ing it.")

(defun msgpack-read-byte ()
  "Read one byte."
  (prog1 (following-char)
    (forward-char 1)))

(defun msgpack-read-bytes (amt)
  "Read AMT bytes."
  (let ((op (point)))
    (forward-char amt)
    (buffer-substring-no-properties op (point))))

(defun msgpack-byte-to-bits (byte)
  "Convert 1 BYTE to a list of 8 bits."
  (cl-loop for i from 7 downto 0
           collect (if (= (logand byte (expt 2 i)) 0)
                       0
                     1)))

(defun msgpack-bits-to-unsigned (bits)
  "Convert BITS to unsigned."
  (cl-loop for i from (1- (length bits)) downto 0
           for b in bits
           sum (* b (expt 2 i))))

(defun msgpack-bytes-to-unsigned (bytes)
  "Convert BYTES to unsigned int."
  (cl-loop for i from 0
           for n across (nreverse bytes)
           sum (* n (expt (expt 2 8) i))))

(defun msgpack-bytes-to-signed (bytes)
  "Convert BYTES to signed int."
  (let ((nbits (* 8 (length bytes)))
        (num (msgpack-bytes-to-unsigned bytes)))
    (pcase (lsh num (- (1- nbits)))     ; sign
      (0 num)
      (1 (- num (expt 2 nbits))))))

(defun msgpack-byte-to-signed (byte)
  "Convert BYTE to signed int."
  (msgpack-bytes-to-signed (unibyte-string byte)))

(defun msgpack-bytes-to-bits (bytes)
  "Convert BYTES to bits."
  (cl-mapcan #'msgpack-byte-to-bits bytes))

(defun msgpack-bytes-to-float (bytes)
  "Convert BYTES to IEEE 754 float."
  (let* ((bits (msgpack-bytes-to-bits bytes))
         (sign (car bits))
         (e (msgpack-bits-to-unsigned (cl-subseq bits 1 9)))
         (fraction (1+ (cl-loop for b in (cl-subseq bits 9)
                                for i from 1 to 23
                                sum (* b (expt 2 (- i)))))))
    (* (expt -1 sign) (expt 2 (- e 127)) fraction)))

(defun msgpack-bytes-to-double (bytes)
  "Convert BYTES to IEEE 754 double."
  (let* ((bits (msgpack-bytes-to-bits bytes))
         (sign (car bits))
         (e (msgpack-bits-to-unsigned (cl-subseq bits 1 12)))
         (fraction (1+ (cl-loop for b in (cl-subseq bits 12)
                                for i from 1 to 52
                                sum (* b (expt 2 (- i)))))))
    (* (expt -1 sign) (expt 2 (- e 1023)) fraction)))

(defun msgpack-concat (&rest args)
  "Concatenate all the arguments ARGS and make the result a unibyte string."
  (mapconcat
   (lambda (x)
     (pcase-exhaustive x
       ((and (pred stringp) s)
        (cl-assert (not (multibyte-string-p s)))
        s)
       ((and (pred integerp) n)
        (cl-assert (<= -128 n 255))
        (cond
         ((<= 0 n 255) (unibyte-string n))
         ((<= -128 n 127) (msgpack-signed-to-bytes n 1))))))
   args
   ""))

(cl-defstruct (msgpack-ext (:constructor nil)
                           (:constructor msgpack-ext--make (type data))
                           (:copier nil))
  "Represent MessagePack ext."
  type data)

(defun msgpack-ext-make (type data)
  "Make a msgpack-ext object.
TYPE must be an integer within [-128, 127].
DATA must be a unibyte string."
  (cl-assert (<= -128 type 127))
  (cl-assert (not (multibyte-string-p data)))
  (msgpack-ext--make type data))

(defun msgpack-read-array (len)
  "Read a MessagePack array with LEN elements."
  (cl-loop repeat len
           collect (msgpack-read) into l
           finally return (pcase-exhaustive msgpack-array-type
                            ('vector (vconcat l))
                            ('list l))))

(defun msgpack-read-map-key ()
  "Read a MessagePack map key."
  (pcase (msgpack-read)
    ((and (pred stringp) s)
     (pcase-exhaustive (or msgpack-key-type
                           (alist-get msgpack-map-type '((hash-table . string)
                                                         (alist . symbol)
                                                         (plist . keyword))))
       ('string s)
       ('symbol (intern s))
       ('keyword (intern (concat ":" s)))))
    (key key)))

(defun msgpack-read-map (size)
  "Read a MessagePack map with SIZE pairs."
  (pcase-exhaustive msgpack-map-type
    ('alist
     (cl-loop repeat size
              collect (cons (msgpack-read-map-key) (msgpack-read))))
    ('plist
     (cl-loop repeat size
              nconc (list (msgpack-read-map-key) (msgpack-read))))
    ('hash-table
     (let ((table (make-hash-table :test 'equal)))
       (cl-loop repeat size
                do (puthash (msgpack-read-map-key) (msgpack-read) table))
       table))))

(defun msgpack-seconds-to-time (seconds nanoseconds)
  "Convert SECONDS and NANOSECONDS to Emacs time.
Return (SEC-HIGH SEC-LOW MICROSEC PICOSEC),
using the formula: HIGH * 2**16 + LOW + MICRO * 10**-6 + PICO * 10**-12."
  (let (high low micro pico)
    (setq low (% seconds (expt 2 16))
          high (/ seconds (expt 2 16)))
    ;; microsecond 1e-6
    ;; nanosecond 1e-9
    ;; picosecond 1e-12
    (setq micro (/ nanoseconds 1000)
          pico (* 1000 (% nanoseconds 1000)))
    (list high low micro pico)))

(defun msgpack-read-ext (data-len)
  "Read ext, the data part is DATA-LEN bytes."
  (let ((type (msgpack-byte-to-signed (msgpack-read-byte)))
        (data (msgpack-read-bytes data-len)))
    (pcase (list type data-len)
      ('(-1 4) (seconds-to-time (msgpack-bytes-to-unsigned data)))
      ('(-1 8) (let* ((bits (msgpack-bytes-to-bits data))
                      (nanoseconds (msgpack-bits-to-unsigned (cl-subseq bits 0 30)))
                      (seconds (msgpack-bits-to-unsigned (cl-subseq bits 30))))
                 (msgpack-seconds-to-time seconds nanoseconds)))
      ('(-1 12) (let ((nanoseconds (msgpack-bytes-to-unsigned (substring data 0 4)))
                      (seconds (msgpack-bytes-to-unsigned (substring data 4))))
                  (msgpack-seconds-to-time seconds nanoseconds)))
      (_ (msgpack-ext-make type data)))))

(defun msgpack-read ()
  "Parse and return the MessagePack object following point.
Advances point just past MessagePack object.

NOTE MessagePack is raw bytes, hence current buffer should be a
single-byte buffer, but Emacs buffers are multibyte buffers by
default, you should make this buffer single-byte buffer before
calling this function, e.g., (set-buffer-multibyte nil)."
  ;; (cl-assert (not enable-multibyte-characters))
  (let ((b (msgpack-read-byte)))
    (pcase b
      ;; nil
      (#xc0 nil)
      (#xc1 (error "Never used: #xc1"))
      ;; bool
      (#xc2 nil)
      (#xc3 t)
      ;; int
      (#xcc (msgpack-read-byte))
      (#xcd (msgpack-bytes-to-unsigned (msgpack-read-bytes 2)))
      (#xce (msgpack-bytes-to-unsigned (msgpack-read-bytes 4)))
      (#xcf (msgpack-bytes-to-unsigned (msgpack-read-bytes 8)))
      (#xd0 (msgpack-bytes-to-signed (msgpack-read-bytes 1)))
      (#xd1 (msgpack-bytes-to-signed (msgpack-read-bytes 2)))
      (#xd2 (msgpack-bytes-to-signed (msgpack-read-bytes 4)))
      (#xd3 (msgpack-bytes-to-signed (msgpack-read-bytes 8)))
      ;; float
      (#xca (msgpack-bytes-to-float (msgpack-read-bytes 4)))
      (#xcb (msgpack-bytes-to-double (msgpack-read-bytes 8)))
      ;; string
      (#xd9 (decode-coding-string (msgpack-read-bytes (msgpack-read-byte)) 'utf-8))
      (#xda (decode-coding-string (msgpack-read-bytes (msgpack-bytes-to-unsigned (msgpack-read-bytes 2))) 'utf-8))
      (#xdb (decode-coding-string (msgpack-read-bytes (msgpack-bytes-to-unsigned (msgpack-read-bytes 4))) 'utf-8))
      ;; bin
      (#xc4 (msgpack-read-bytes (msgpack-read-byte)))
      (#xc5 (msgpack-read-bytes (msgpack-bytes-to-unsigned (msgpack-read-bytes 2))))
      (#xc6 (msgpack-read-bytes (msgpack-bytes-to-unsigned (msgpack-read-bytes 4))))
      ;; array
      (#xdc (msgpack-read-array (msgpack-bytes-to-unsigned (msgpack-read-bytes 2))))
      (#xdd (msgpack-read-array (msgpack-bytes-to-unsigned (msgpack-read-bytes 4))))
      ;; map
      (#xde (msgpack-read-map (msgpack-bytes-to-unsigned (msgpack-read-bytes 2))))
      (#xdf (msgpack-read-map (msgpack-bytes-to-unsigned (msgpack-read-bytes 4))))
      ;; ext
      (#xd4 (msgpack-read-ext 1))
      (#xd5 (msgpack-read-ext 2))
      (#xd6 (msgpack-read-ext 4))
      (#xd7 (msgpack-read-ext 8))
      (#xd8 (msgpack-read-ext 16))
      (#xc7 (msgpack-read-ext (msgpack-read-byte)))
      (#xc8 (msgpack-read-ext (msgpack-bytes-to-unsigned (msgpack-read-bytes 2))))
      (#xc9 (msgpack-read-ext (msgpack-bytes-to-unsigned (msgpack-read-bytes 4))))
      (_ (pcase (msgpack-byte-to-bits b)
           (`(0 . ,_) b)
           ;; negative fixint
           (`(1 1 1 . ,bits) (- (msgpack-bits-to-unsigned bits) (expt 2 5)))
           ;; string
           (`(1 0 1 . ,bits) (decode-coding-string (msgpack-read-bytes (msgpack-bits-to-unsigned bits)) 'utf-8))
           ;; array
           (`(1 0 0 1 . ,bits) (msgpack-read-array (msgpack-bits-to-unsigned bits)))
           ;; map
           (`(1 0 0 0 . ,bits) (msgpack-read-map (msgpack-bits-to-unsigned bits))))))))

(defun msgpack-read-from-string (string)
  "Read the MessagePack object in unibyte STRING and return it."
  (cl-assert (not (multibyte-string-p string)))
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert string)
    (goto-char (point-min))
    (msgpack-read)))

(defun msgpack-read-file (file)
  "Read the first MessagePack object contained in FILE and return it."
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert-file-contents-literally file)
    (goto-char (point-min))
    (msgpack-read)))

(defun msgpack-unsigned-to-bytes (integer size)
  "Convert unsigned INTEGER to SIZE bytes."
  (apply
   #'unibyte-string
   (nreverse
    (cl-loop repeat size
             for i from 0 by 8
             collect (logand #xff (lsh integer (- i)))))))

(defvar msgpack-emacs-integer-length
  (cl-loop for i from 1
           when (zerop (lsh most-negative-fixnum (- i)))
           return i)
  "The number of bits this Emacs's integer is in.
Usually this is 62, for 32-bit Emacs, it might be 30.")

(defun msgpack-bits-plus-one (bits)
  "Add BITS by 1, assuming BITS contain at least one zero."
  (let (done result)
    (dolist (b (nreverse bits) result)
      (cond
       (done (push b result))
       ((and (not done) (zerop b))
        (push 1 result)
        (setq done t))
       (t (push 0 result))))))

(defun msgpack-signed-to-bytes-fallback (integer size)
  "Convert negative INTEGER to SIZE bytes."
  (let* ((bits (msgpack-unsigned-to-bits (- integer)))
         (bits (msgpack-list-pad-left bits (* size 8) 0))
         (bits (cl-loop for b in bits
                        collect (if (zerop b) 1 0)))
         (bits (msgpack-bits-plus-one bits)))
    (msgpack-bits-to-bytes bits)))

(defun msgpack-signed-to-bytes (integer size)
  "Convert signed INTEGER to SIZE bytes."
  (if (and (< integer 0)
           (> (* 8 size) msgpack-emacs-integer-length))
      ;; Emacs can't help
      (msgpack-signed-to-bytes-fallback integer size)
    (msgpack-unsigned-to-bytes integer size)))

(defun msgpack-encode-integer (n)
  "Return a MessagePack representation of integer N."
  (cond
   ((<= 0 n 127)
    (unibyte-string n))
   ((<= -32 n -1)
    (unibyte-string (logior #b11100000 (+ 32 n))))
   ((<= 0 n 255)
    (unibyte-string #xcc n))
   ((<= 0 n #xffff)
    (concat (unibyte-string #xcd) (msgpack-unsigned-to-bytes n 2)))
   ;; NOTE #xffffffff or 2^32 overflow for 32-bit platform
   ((<= 0 n #xffffffff)
    (concat (unibyte-string #xce) (msgpack-unsigned-to-bytes n 4)))
   ((or (and (> (expt 2 64) 0)          ; need Emacs 27.1's bignum
             (<= 0 n (1- (expt 2 64))))
        (<= 0 n (max (1- (expt 2 64)) most-positive-fixnum)))
    (concat (unibyte-string #xcf) (msgpack-unsigned-to-bytes n 8)))
   ((<= -128 n 127)
    (concat (unibyte-string #xd0) (msgpack-signed-to-bytes n 1)))
   ((<= (- (expt 2 15)) n (1- (expt 2 15)))
    (concat (unibyte-string #xd1) (msgpack-signed-to-bytes n 2)))
   ((<= (- (expt 2 31)) n (1- (expt 2 31)))
    (concat (unibyte-string #xd2) (msgpack-signed-to-bytes n 4)))
   ((or (and (> (expt 2 63) 0)          ; need Emacs 27.1's bignum
             (<= (- (expt 2 63)) n (1- (expt 2 63))))
        (<= (min most-negative-fixnum (- (expt 2 63)))
            n
            (max most-positive-fixnum (1- (expt 2 63)))))
    (concat (unibyte-string #xd3) (msgpack-signed-to-bytes n 8)))
   (t (error "Should be impossible to reach here: %s" n))))

(defun msgpack-encode-string (string)
  "Return a MessagePack representation of UTF-8 STRING."
  (let ((n (string-bytes string))
        (s (encode-coding-string string 'utf-8)))
    (cond
     ((<= n 31)
      (concat (unibyte-string (logior #b10100000 n)) s))
     ((<= n #xff)
      (concat (unibyte-string #xd9) (msgpack-unsigned-to-bytes n 1) s))
     ((<= n (1- (expt 2 16)))
      (concat (unibyte-string #xda) (msgpack-unsigned-to-bytes n 2) s))
     ((<= n (1- (expt 2 32)))
      (concat (unibyte-string #xdb) (msgpack-unsigned-to-bytes n 4) s)))))

(defun msgpack-encode-unibyte-string (string)
  "Return a MessagePack representation of unibyte STRING."
  (cl-assert (not (multibyte-string-p string)))
  (let ((n (length string))
        (s string))
    (cond
     ((<= n 255)
      (concat (unibyte-string #xc4) (msgpack-unsigned-to-bytes n 1) s))
     ((<= n #xffff)
      (concat (unibyte-string #xc5) (msgpack-unsigned-to-bytes n 2) s))
     ((<= n (1- (expt 2 32)))
      (concat (unibyte-string #xc6) (msgpack-unsigned-to-bytes n 4) s)))))

(defun msgpack-unsigned-to-bits (n)
  "Convert unsigned integer N to bits."
  (if (zerop n)
      (list 0)
    (let (next bits)
      (while (> n 0)
        (setq next (/ n 2))
        (push (- n (* 2 next)) bits)
        (setq n next))
      bits)))

(defun msgpack-split-float (f)
  "Split float F into integral and fractional parts."
  (let ((integral (truncate f)))
    (list integral
          ;; (- 1.1 1)
          ;; => 0.10000000000000009
          ;; https://0.30000000000000004.com/
          (- f integral))))

(defun msgpack-split-float-the-hard-way (f)
  "Split float F into integral and fractional parts."
  (let* ((s (prin1-to-string f))
         (pos (cl-position ?. s)))
    (list (car (read-from-string s 0 pos))
          (car (read-from-string s pos)))))

(defun msgpack-float-to-bits (f limit)
  "Convert float F to at most LIMIT bits."
  (let (bits double (n 0))
    (while (and (not (zerop f)) (< n limit))
      (setq double (* f 2))
      (cond
       ((>= double 1)
        (push 1 bits)
        (setq f (1- double)))
       (t
        (push 0 bits)
        (setq f double)))
      (cl-incf n))
    (nreverse bits)))

(defun msgpack-float-to-bits-normalize (ibits fbits)
  "Normalize IBITS and FBITS and return a list of bits."
  (let* ((index (length ibits))
         (bits (append ibits fbits))
         (e (1- (- (length ibits) (cl-position 1 bits)))))
    (setq index (- index e))
    (list (cl-subseq bits index) e)))

(defun msgpack-list-pad-right (list len padding)
  "If LIST is shorter than LEN, pad it with PADDING on the right."
  (pcase (- len (length list))
    ((and (pred (< 0)) diff) (append list (make-list diff padding)))
    (_ list)))

(defun msgpack-list-pad-left (list len padding)
  "If LIST is shorter than LEN, pad it with PADDING on the left."
  (pcase (- len (length list))
    ((and (pred (< 0)) diff) (append (make-list diff padding) list))
    (_ list)))

(defun msgpack-8bits-to-byte (8bits)
  "Convert 8BITS to a byte."
  (cl-loop for i in 8bits
           for j from 7 downto 0
           sum (* i (expt 2 j))))

(defun msgpack-bits-to-bytes (bits)
  "Convert BITS to bytes."
  ;; (cl-assert (zerop (% (length bits) 8)))
  (cl-loop for i from 0 to (1- (length bits)) by 8
           concat (unibyte-string (msgpack-8bits-to-byte (cl-subseq bits i (+ i 8))))))

;; Emacs float uses IEEE 64-bit but we can't access it from Emacs Lisp
;; XXX File a feature request
(defun msgpack-float-to-bytes (f)
  "Convert float F to IEEE 32-bit."
  ;; http://sandbox.mc.edu/~bennet/cs110/flt/dtof.html
  (pcase-let* ((sign (if (< f 0) 1 0))
               (f (abs f))
               (`(,int ,frac) (msgpack-split-float-the-hard-way f))
               (ibits (msgpack-unsigned-to-bits int))
               (fbits (msgpack-float-to-bits frac 32)) ; XXX why 32?
               (`(,bits ,e) (msgpack-float-to-bits-normalize ibits fbits))
               (too-many (> (length bits) 23))
               (mantissa (if too-many
                             (cl-subseq bits 0 23)
                           (msgpack-list-pad-right bits 23 0)))
               (exponent (msgpack-list-pad-left (msgpack-unsigned-to-bits (+ e 127)) 8 0)))
    (let ((bytes (msgpack-bits-to-bytes (append (list sign) exponent mantissa))))
      (if (and too-many (= 1 (nth 23 bits)))
          (msgpack-unsigned-to-bytes (1+ (msgpack-bytes-to-unsigned bytes)) 4)
        bytes))))

(defun msgpack-bytes-to-hex-string (bytes)
  "Convert BYTES to a string representation.
Each byte in BYTES is converted to its two-digit hexadecimal
representation in the resulting string."
  (mapconcat (lambda (b) (format "%x" b)) bytes ""))

(defun msgpack-hex-string-to-bytes (string)
  "Convert STRING to BYTES.
Each pair of characters in STRING is converted to a single byte
in the result."
  (mapconcat
   (lambda (s) (unibyte-string (string-to-number s 16)))
   (seq-partition string 2)
   ""))

(defun msgpack-encode-float (f)
  "Encode float F as MessagePack float."
  (concat (unibyte-string #xca) (msgpack-float-to-bytes f)))

(defun msgpack-encode-array (array)
  "Return a MessagePack representation of ARRAY."
  (let ((n (length array)))
    (cond
     ((<= n 15)
      (concat (unibyte-string (logior #b10010000 n))
              (mapconcat #'msgpack-encode array "")))
     ((<= n #xffff)
      (concat (unibyte-string #xdc)
              (msgpack-unsigned-to-bytes n 2)
              (mapconcat #'msgpack-encode array "")))
     ((<= n (1- (expt 2 32)))
      (concat (unibyte-string #xdd)
              (msgpack-unsigned-to-bytes n 4)
              (mapconcat #'msgpack-encode array ""))))))

(defun msgpack-encode-list (list)
  "Encode LIST as MessagePack array or map accordingly."
  (pcase-exhaustive list
    ((pred json-alist-p) (msgpack-encode-alist list))
    ((pred json-plist-p) (msgpack-encode-plist list))
    ((pred listp) (msgpack-encode-array list))))

(defun msgpack-encode-alist (alist)
  "Encode ALIST as MessagePack map."
  (let ((n (length alist)))
    (concat
     (cond
      ((<= n 15)
       (unibyte-string (logior #b10000000 n)))
      ((<= n #xffff)
       (unibyte-string #xde (msgpack-unsigned-to-bytes n 2)))
      ((<= n (1- (expt 2 32)))
       (unibyte-string #xdf (msgpack-unsigned-to-bytes n 4))))
     (cl-loop for (k . v) in alist
              concat (concat
                      (msgpack-encode k)
                      (msgpack-encode v))))))

;; `json--plist-to-alist'
(defun msgpack-plist-to-alist (plist)
  "Return an alist of the property-value pairs in PLIST."
  (let (res)
    (while plist
      (let ((prop (pop plist))
            (val (pop plist)))
        (push (cons prop val) res)))
    (nreverse res)))

(defun msgpack-encode-plist (plist)
  "Encode PLIST as MessagePack map."
  (msgpack-encode-alist (msgpack-plist-to-alist plist)))

(cl-defstruct (msgpack-bin (:constructor nil)
                           (:constructor msgpack-bin-make (string))
                           (:copier nil))
  "Wrapper of unibyte string to represent MessagePack byte array.
Use it if you need to write MessagePack byte array."
  string)

(defun msgpack-string-pad-right (s len padding)
  "If S is shorter than LEN, pad it with PADDING on the right."
  (if (< (length s) len)
      (concat s (make-string (- len (length s)) padding))
    s))

(defun msgpack-encode-ext (ext)
  "Encode EXT as MessagePack ext."
  (pcase-exhaustive ext
    ((cl-struct msgpack-ext type data)
     (let ((len (length data)))
       (concat
        (pcase-exhaustive len
          (1 (unibyte-string #xd4))
          (2 (unibyte-string #xd5))
          (4 (unibyte-string #xd6))
          (8 (unibyte-string #xd7))
          (16 (unibyte-string #xd8))
          ((guard (<= len #xff))
           (concat (unibyte-string #xc7) (msgpack-unsigned-to-bytes len 1)))
          ((guard (<= len #xffff))
           (concat (unibyte-string #xc8) (msgpack-unsigned-to-bytes len 2)))
          ((guard (<= len #xffffffff))
           (concat (unibyte-string #xc9) (msgpack-unsigned-to-bytes len 4))))
        (msgpack-signed-to-bytes type 1)
        data)))))

(defun msgpack-encode (obj)
  "Return MessagePack representation of OBJ."
  (pcase-exhaustive obj
    ;; null, false, true
    ((pred (eq msgpack-null)) (unibyte-string #xc0))
    ((pred (eq msgpack-false)) (unibyte-string #xc2))
    ('t (unibyte-string #xc3))
    ;; integer, float
    ((pred integerp) (msgpack-encode-integer obj))
    ((and (pred floatp) (pred zerop)) (msgpack-encode-integer 0))
    ((pred floatp) (msgpack-encode-float obj))
    ;; string, byte array
    ((pred stringp) (msgpack-encode-string obj))
    ((cl-struct msgpack-bin string) (msgpack-encode-unibyte-string string))
    ;; NOTE cl-struct is also vector for Emacs 25, so it's important to put any cl-struct before vector
    ;; ext
    ((cl-struct msgpack-ext) (msgpack-encode-ext obj))
    ;; array
    ((pred vectorp) (msgpack-encode-array obj))
    ;; map
    ((pred hash-table-p) (msgpack-encode-alist (map-into obj 'list)))
    ;; encode symbols and keywords as string
    ((pred keywordp) (msgpack-encode-string (substring (symbol-name obj) 1)))
    ((pred symbolp) (msgpack-encode-string (symbol-name obj)))
    ;; encode list as array or map according to its content
    ((pred listp) (msgpack-encode-list obj))))

(defun msgpack-try-read ()
  "Detect if there is a MessagePack object following point.
Signal an `end-of-buffer' error if it ends too early.

Unlike `msgpack-read', the return value is meaningless, it is
faster than `msgpack-read' and should be used to detect if the
MessagePack object is completed."
  (let ((b (msgpack-read-byte)))
    (pcase b
      (#xc0)
      (#xc1)
      (#xc2)
      (#xc3)
      (#xcc (msgpack-read-bytes 1))
      (#xcd (msgpack-read-bytes 2))
      (#xce (msgpack-read-bytes 4))
      (#xcf (msgpack-read-bytes 8))
      (#xd0 (msgpack-read-bytes 1))
      (#xd1 (msgpack-read-bytes 2))
      (#xd2 (msgpack-read-bytes 4))
      (#xd3 (msgpack-read-bytes 8))
      (#xca (msgpack-read-bytes 4))
      (#xcb (msgpack-read-bytes 8))
      (#xd9 (msgpack-read-bytes (msgpack-read-byte)))
      (#xda (msgpack-read-bytes (msgpack-bytes-to-unsigned (msgpack-read-bytes 2))))
      (#xdb (msgpack-read-bytes (msgpack-bytes-to-unsigned (msgpack-read-bytes 4))))
      (#xc4 (msgpack-read-bytes (msgpack-read-byte)))
      (#xc5 (msgpack-read-bytes (msgpack-bytes-to-unsigned (msgpack-read-bytes 2))))
      (#xc6 (msgpack-read-bytes (msgpack-bytes-to-unsigned (msgpack-read-bytes 4))))
      (#xdc (cl-loop repeat (msgpack-bytes-to-unsigned (msgpack-read-bytes 2))
                     do (msgpack-try-read)))
      (#xdd (cl-loop repeat (msgpack-bytes-to-unsigned (msgpack-read-bytes 4))
                     do (msgpack-try-read)))
      (#xde (cl-loop repeat (msgpack-bytes-to-unsigned (msgpack-read-bytes 2))
                     do (msgpack-try-read) (msgpack-try-read)))
      (#xdf (cl-loop repeat (msgpack-bytes-to-unsigned (msgpack-read-bytes 4))
                     do (msgpack-try-read) (msgpack-try-read)))
      (#xd4 (msgpack-read-bytes 2))
      (#xd5 (msgpack-read-bytes 3))
      (#xd6 (msgpack-read-bytes 5))
      (#xd7 (msgpack-read-bytes 9))
      (#xd8 (msgpack-read-bytes 17))
      (#xc7 (msgpack-read-bytes (1+ (msgpack-read-byte))))
      (#xc8 (msgpack-read-bytes
             (1+ (msgpack-bytes-to-unsigned (msgpack-read-bytes 2)))))
      (#xc9 (msgpack-read-bytes
             (1+ (msgpack-bytes-to-unsigned (msgpack-read-bytes 4)))))
      (_ (pcase (msgpack-byte-to-bits b)
           (`(0 . ,_))
           (`(1 1 1 . ,_))
           (`(1 0 1 . ,bits)
            (msgpack-read-bytes (msgpack-bits-to-unsigned bits)))
           (`(1 0 0 1 . ,bits)
            (cl-loop repeat (msgpack-bits-to-unsigned bits)
                     do (msgpack-try-read)))
           (`(1 0 0 0 . ,bits)
            (cl-loop repeat (msgpack-bits-to-unsigned bits)
                     do (msgpack-try-read) (msgpack-try-read))))))))

(defun msgpack-try-read-from-string (string)
  "Signal `end-of-buffer' if STRING is not a MessagePack object."
  (cl-assert (not (multibyte-string-p string)))
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert string)
    (goto-char (point-min))
    (msgpack-try-read)
    nil))

(provide 'msgpack)
;;; msgpack.el ends here
