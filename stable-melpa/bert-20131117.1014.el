;;; bert.el --- BERT serialization library for Emacs

;; Copyright (C) 2013 Oleksandr Manzyuk <manzyuk@gmail.com>

;; Author: Oleksandr Manzyuk <manzyuk@gmail.com>
;; Version: 0.1
;; Package-Version: 20131117.1014
;; Package-Commit: a3eec6980a725aa4abd2019e4c00246450260490
;; Keywords: comm data

;; This file is NOT part of GNU Emacs.

;; This is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Translation to and from BERT (Binary ERlang Term) format.
;;
;; See the BERT specification at http://bert-rpc.org/.
;;
;; The library provides two functions, `bert-pack' and `bert-unpack',
;; and supports the following Elisp types:
;;  - integers
;;  - floats
;;  - lists
;;  - symbols
;;  - vectors
;;  - strings
;;
;; The Elisp NIL is encoded as an empty list rather than a BERT atom,
;; BERT nil, or BERT false.
;;
;; Elisp vectors and strings are encoded as BERT tuples resp. BERT
;; binaries.
;;
;; Complex types are not supported.  Encoding and decoding of complex
;; types can be implemented as a thin layer on top of this library.
;;
;; Because Elisp integers are 30-bit, only integers of this size can
;; be correctly translated.  In particular, BERT bignums are not
;; supported.

;;; Code:

(require 'bindat)
(require 'ert)

(defvar bert-bindat-spec
  '((tag u8)
    (union (tag)
           (97  (integer u8))
           (98  (integer u32))
           (99  (float-string str 31))
           (100 (length u16)
                (atom-name str (length)))
           (104 (arity u8)
                (elements repeat (arity)
                          (struct bert-bindat-spec)))
           (105 (arity u32)
                (elements repeat (arity)
                          (struct bert-bindat-spec)))
           (106)
           (107 (length u16)
                (characters str (length)))
           (108 (length u32)
                (elements repeat (length)
                          (struct bert-bindat-spec))
                (tail struct bert-bindat-spec))
           (109 (length u32)
                (data vec (length)))
           (110 (length u8)
                (sign u8)
                (digits vec (length)))
           (111 (length u32)
                (sign u8)
                (digits vec (length)))))
  "Structure specification of BERT (without the magic number).

See http://bert-rpc.org/ for more details.")

;;;###autoload
(defun bert-pack (obj)
  "Serialize OBJ as a BERT.

The following Elisp types are supported:
 - integers
 - floats
 - lists
 - symbols
 - vectors
 - strings

The Elisp NIL is encoded as an empty list rather than a symbol,
BERT nil, or BERT false.

Elisp vectors and strings are encoded as BERT tuples resp. BERT
binaries.

Complex types are not supported.  Encoding of complex types can
be implemented as a thin layer on top of this library."
  (bindat-pack `((magic u8) ,@bert-bindat-spec)
               `((magic . 131) ,@(bert-encode obj))))

(defadvice bert-pack (around bert-pack-around activate)
  "Dynamically rebind `lsh' to `ash' in the body of `bert-pack'.

This is really a hack allowing us to encode signed 30-bit Elisp
integers as unsigned 32-bit integers in network order using
`bindat--pack-u32' as prescribed by the BERT format."
  (letf (((symbol-function 'lsh) #'ash))
    ad-do-it))

(defun bert-encode (obj)
  "Encode OBJ as a structure conforming to the bindat
specification of BERT given by `bert-bindat-spec'."
  (cond ((integerp     obj) (bert-encode-integer    obj))
        ((floatp       obj) (bert-encode-float      obj))
        ((listp        obj) (bert-encode-list       obj))
        ;; The case of symbol must come after the case of list because
        ;; nil is a symbol but should be packed as an empty list.
        ((symbolp      obj) (bert-encode-symbol     obj))
        ((vectorp      obj) (bert-encode-vector     obj))
        ((stringp      obj) (bert-encode-string     obj))
        (t (error "cannot encode %S" obj))))

(defun bert-encode-integer (integer)
  `((tag . ,(if (and (>= integer 0) (< integer 256)) 97 98))
    (integer . ,integer)))

(defun bert-pad-right (string width char)
  (concat string
          (make-string (max 0 (- width (length string))) char)))

(defun bert-encode-float (float)
  (let ((float-string (bert-pad-right (format "%15.15e" float) 31 ?\000)))
    `((tag . 99)
      (float-string . ,float-string))))

(defun bert-encode-symbol (symbol)
  (let* ((name (symbol-name symbol))
         (len (length name)))
    (assert (< len 256) t "symbol name is too long (>= 256): %S" symbol)
    `((tag . 100)
      (length . ,len)
      (atom-name . ,name))))

(defun bert-encode-vector (data)
  `((tag . ,(if (< (length data) 256) 104 105))
    (arity . ,(length data))
    (elements . ,(mapcar #'bert-encode data))))

(defun bert-encode-list (list)
  (if (null list)
      `((tag . 106))
    `((tag . 108)
      (length . ,(length list))
      (elements . ,(mapcar #'bert-encode list))
      (tail . ((tag . 106))))))

(defun bert-encode-string (string)
  `((tag . 109)
    (length . ,(length string))
    (data . ,(string-to-vector string))))

;;;###autoload
(defun bert-unpack (string)
  "Deserialize a BERT from STRING.

See the description of `bert-pack' for a list of supported types.

Limitations:

 - Elisp integers are 30-bit, and only integers of this size are
   correctly decoded.

 - BERT bignums are not supported because they are not supported
   by the vanilla Emacs."
  (let* ((struct
          (bindat-unpack `((magic u8) ,@bert-bindat-spec) string))
         (magic (bindat-get-field struct 'magic)))
    (assert (= magic 131) t "bad magic: %d" magic)
    (bert-decode struct)))

(defadvice bert-unpack (around bert-unpack-around activate)
  "Dynamically rebind `lsh' to `ash' in the body of `bert-unpack'.

This is really a hack allowing us to decode signed 30-bit Elisp
integers from unsigned 32-bit integers in network order using
`bindat--unpack-u32' as prescribed by the BERT format."
  (letf (((symbol-function 'lsh) #'ash))
    ad-do-it))

(defun bert-decode (struct)
  "Decode STRUCT as an Elisp object.

STRUCT is assumed to conform to the bindat specification given by
`bert-bindat-spec'."
  (case (bindat-get-field struct 'tag)
    ((97 98)   (bert-decode-integer struct))
    (99        (bert-decode-float   struct))
    (100       (bert-decode-atom    struct))
    ((104 105) (bert-decode-tuple   struct))
    (106       nil)
    (107       (bert-decode-string  struct))
    (108       (bert-decode-list    struct))
    (109       (bert-decode-binary  struct))
    ((110 111) (error "cannot decode bignums"))))

(defun bert-decode-integer (struct)
  (bindat-get-field struct 'integer))

(defun bert-decode-float (struct)
  (read (bindat-get-field struct 'float-string)))

(defun bert-decode-atom (struct)
  (intern (bindat-get-field struct 'atom-name)))

(defun bert-decode-tuple (struct)
  (let ((elements (bindat-get-field struct 'elements)))
    (apply #'vector (mapcar #'bert-decode elements))))

(defun bert-decode-string (struct)
  (bindat-get-field struct 'characters))

(defun bert-decode-list (struct)
  (let* ((elements (bindat-get-field struct 'elements))
         (tail (bindat-get-field struct 'tail))
         (list (mapcar #'bert-decode elements)))
    (setcdr (last list) (bert-decode tail))
    list))

(defun bert-decode-binary (struct)
  (map 'string #'identity (bindat-get-field struct 'data)))

;;; Tests

;; All tests have been generated using Ruby BERT library:
;; https://github.com/mojombo/bert

(ert-deftest bert-pack-integer ()
  "Test packing of integers."
  (should (equal (bert-pack 0)
                 (unibyte-string 131 97 0)))
  (should (equal (bert-pack 42)
                 (unibyte-string 131 97 42)))
  (should (equal (bert-pack 255)
                 (unibyte-string 131 97 255)))
  (should (equal (bert-pack 256)
                 (unibyte-string 131 98 0 0 1 0)))
  (should (equal (bert-pack 12345)
                 (unibyte-string 131 98 0 0 48 57)))
  (should (equal (bert-pack -42)
                 (unibyte-string 131 98 255 255 255 214))))

(ert-deftest bert-pack-float ()
  "Test packing of floats."
  (should (equal (bert-pack 3.1415926)
                 (unibyte-string
                  131 99 51 46 49 52 49 53 57 50 54 48 48 48 48 48 48 48 48
                  101 43 48 48 0 0 0 0 0 0 0 0 0 0)))
  (should (equal (bert-pack 9.10938291e-31)
                 (unibyte-string
                  131 99 57 46 49 48 57 51 56 50 57 49 48 48 48 48 48 48 48
                  101 45 51 49 0 0 0 0 0 0 0 0 0 0)))
  (should (equal (bert-pack -6.62606957e-34)
                 (unibyte-string
                  131 99 45 54 46 54 50 54 48 54 57 53 55 48 48 48 48 48 48
                  48 101 45 51 52 0 0 0 0 0 0 0 0 0))))

(ert-deftest bert-pack-symbol ()
  "Test packing of symbols."
  (should (equal (bert-pack (intern ""))
                 (unibyte-string 131 100 0 0)))
  (should (equal (bert-pack (intern "foo"))
                 (unibyte-string 131 100 0 3 102 111 111)))
  (should (equal (bert-pack (intern "foo bar"))
                 (unibyte-string 131 100 0 7 102 111 111 32 98 97 114))))

(ert-deftest bert-pack-list ()
  "Test packing of lists."
  (should (equal (bert-pack nil)
                 (unibyte-string 131 106)))
  (should (equal (bert-pack (list 1 2 3))
                 (unibyte-string 131 108 0 0 0 3 97 1 97 2 97 3 106)))
  (should (equal (bert-pack (list 1 (list 2 3)))
                 (unibyte-string
                  131 108 0 0 0 2 97 1 108 0 0 0 2 97 2 97 3 106 106)))
  (should (equal (bert-pack (list 1 2.718 'foo))
                 (unibyte-string
                  131 108 0 0 0 3 97 1 99 50 46 55 49 56 48 48 48 48 48 48
                  48 48 48 48 48 48 101 43 48 48 0 0 0 0 0 0 0 0 0 0 100 0
                  3 102 111 111 106))))

(ert-deftest bert-pack-vector ()
  "Test packing of vectors."
  (should (equal (bert-pack (vector))
                 (unibyte-string 131 104 0)))
  (should (equal (bert-pack (vector 1 2 3))
                 (unibyte-string 131 104 3 97 1 97 2 97 3)))
  (should (equal (bert-pack (vector 1 (vector 2 3)))
                 (unibyte-string 131 104 2 97 1 104 2 97 2 97 3)))
  (should (equal (bert-pack (vector 1 2.718 'foo))
                 (unibyte-string
                  131 104 3 97 1 99 50 46 55 49 56 48 48 48 48 48 48 48 48
                  48 48 48 48 101 43 48 48 0 0 0 0 0 0 0 0 0 0 100 0 3 102
                  111 111))))

(ert-deftest bert-pack-string ()
  "Test packing of strings."
  (should (equal (bert-pack "")
                 (unibyte-string 131 109 0 0 0 0)))
  (should (equal (bert-pack "foo")
                 (unibyte-string 131 109 0 0 0 3 102 111 111))))

(ert-deftest bert-unpack-integer ()
  "Test unpacking of integers."
  (should (equal (bert-unpack (bert-pack     0))     0))
  (should (equal (bert-unpack (bert-pack    42))    42))
  (should (equal (bert-unpack (bert-pack   255))   255))
  (should (equal (bert-unpack (bert-pack   256))   256))
  (should (equal (bert-unpack (bert-pack 12345)) 12345))
  (should (equal (bert-unpack (bert-pack   -42))  -42)))

(ert-deftest bert-unpack-float ()
  "Test unpacking of floats."
  (should (equal (bert-unpack (bert-pack       3.1415926))       3.1415926))
  (should (equal (bert-unpack (bert-pack  9.10938291e-31))  9.10938291e-31))
  (should (equal (bert-unpack (bert-pack -6.62606957e-34)) -6.62606957e-34)))

(ert-deftest bert-unpack-symbol ()
  "Test unpacking of symbols."
  (should (equal (bert-unpack (bert-pack (intern ""))) (intern "")))
  (should (equal (bert-unpack (bert-pack (intern "foo"))) (intern "foo")))
  (should (equal (bert-unpack (bert-pack (intern "foo bar")))
                 (intern "foo bar"))))

(ert-deftest bert-unpack-list ()
  "Test unpacking of lists."
  (should (equal (bert-unpack (bert-pack nil)) nil))
  (should (equal (bert-unpack (bert-pack (list 1 2 3))) (list 1 2 3)))
  (should (equal (bert-unpack (bert-pack (list 1 (list 2 3))))
                 (list 1 (list 2 3))))
  (should (equal (bert-unpack (bert-pack (list 1 2.718 'foo)))
                 (list 1 2.718 'foo))))

(ert-deftest bert-unpack-vector ()
  "Test unpacking of vectors."
  (should (equal (bert-unpack (bert-pack (vector))) (vector)))
  (should (equal (bert-unpack (bert-pack (vector 1 2 3))) (vector 1 2 3)))
  (should (equal (bert-unpack (bert-pack (vector 1 (vector 2 3))))
                 (vector 1 (vector 2 3))))
  (should (equal (bert-unpack (bert-pack (vector 1 2.718 'foo)))
                 (vector 1 2.718 'foo))))

(ert-deftest bert-unpack-string ()
  "Test unpacking of strings."
  (should (equal (bert-unpack (bert-pack "")) ""))
  (should (equal (bert-unpack (bert-pack "foo")) "foo")))

(provide 'bert)

;;; bert.el ends here
