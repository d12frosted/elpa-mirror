;;; bitpack.el --- Bit packing functions -*- lexical-binding: t; -*-

;; This is free and unencumbered software released into the public domain.

;; Author: Christopher Wellons <wellons@nullprogram.com>
;; Version: 1.0.0
;; Package-Version: 20230417.2032
;; Package-Commit: 38d000646b81ce52fcb90a0747059a15264e112b
;; Created: 6 Apr 2019
;; Keywords: c, comm
;; Homepage: https://github.com/skeeto/bitpack
;; Package-Requires: ((emacs "24.3"))

;;; Commentary:

;; bitdat is similar to the built-in bindat package.  However, this
;; package can encode IEEE 754 floating point values, both single
;; (32-bit) and double precision (64-bit).  Requires a 64-bit build of
;; Emacs.

;; IEEE 754 NaN have a sign, and this library is careful to store that
;; sign when packing NaN values.  So be mindful of negative NaN:

;; http://lists.gnu.org/archive/html/emacs-devel/2018-07/msg00816.html

;; NaNs are always stored in quiet form (i.e. non-signaling).

;; Ref: https://stackoverflow.com/a/14955046

;;; Code:

(require 'cl-lib)

;; Store functions

(defsubst bitpack--store-f32> (negp biased-exp mantissa)
  "Store a single precision float in buffer at point as big-endian.

NEGP, BIASED-EXP and MANTISSA are the float components."
  (insert (if negp
              (logior #x80 (ash biased-exp -1))
            (ash biased-exp -1))
          (logior (% (ash mantissa -16) 128)
                  (% (ash biased-exp 7) 256))
          (% (ash mantissa -8) 256)
          (% mantissa 256)))

(defsubst bitpack--store-f32< (negp biased-exp mantissa)
  "Store a single precision float in buffer at point as little-endian.

NEGP, BIASED-EXP and MANTISSA are the float components."
  (insert (% mantissa 256)
          (% (ash mantissa -8) 256)
          (logior (% (ash mantissa -16) 128)
                  (% (ash biased-exp 7) 256))
          (if negp
              (logior #x80 (ash biased-exp -1))
            (ash biased-exp -1))))

(defsubst bitpack--store-f64> (negp biased-exp mantissa)
  "Store a double precision float in buffer at point as big-endian.

NEGP, BIASED-EXP and MANTISSA are the float components."
  (insert (if negp
              (logior #x80 (ash biased-exp -4))
            (ash biased-exp -4))
          (logior (% (ash mantissa -48) 16)
                  (% (ash biased-exp 4) 256))
          (% (ash mantissa -40) 256)
          (% (ash mantissa -32) 256)
          (% (ash mantissa -24) 256)
          (% (ash mantissa -16) 256)
          (% (ash mantissa  -8) 256)
          (% mantissa 256)))

(defsubst bitpack--store-f64< (negp biased-exp mantissa)
  "Store a double precision float in buffer at point as little-endian.

NEGP, BIASED-EXP and MANTISSA are the float components."
  (insert (% mantissa 256)
          (% (ash mantissa  -8) 256)
          (% (ash mantissa -16) 256)
          (% (ash mantissa -24) 256)
          (% (ash mantissa -32) 256)
          (% (ash mantissa -40) 256)
          (logior (% (ash mantissa -48) 16)
                  (% (ash biased-exp 4) 256))
          (if negp
              (logior #x80 (ash biased-exp -4))
            (ash biased-exp -4))))

(defun bitpack-store-f32 (byte-order x)
  "Store single precision float X in buffer at point per BYTE-ORDER.

BYTE-ORDER may be :> (big endian) or :< (little endian).  The
buffer should *not* be multibyte (`set-buffer-multibyte')."
  (let* ((frexp (frexp (abs x)))
         (fract (car frexp))
         (exp (cdr frexp))
         (negp (< (copysign 1.0 x) 0.0))
         (biased-exp nil)
         (mantissa nil))
    (cond ((isnan x)     ; NaN
           (setf biased-exp #xff
                 mantissa #xc00000))
          ((> fract 1.0) ; infinity
           (setf biased-exp #xff
                 mantissa 0))
          ((= fract 0.0) ; zero
           (setf biased-exp 0
                 mantissa 0))
          ((setf biased-exp (+ exp 126)
                 mantissa (round (ldexp fract 24)))))
    (cl-case byte-order
      (:> (bitpack--store-f32> negp biased-exp mantissa))
      (:< (bitpack--store-f32< negp biased-exp mantissa)))))

(defun bitpack-store-f64 (byte-order x)
  "Store double precision float X in buffer at point per BYTE-ORDER.

BYTE-ORDER may be :> (big endian) or :< (little endian).  The
buffer should *not* be multibyte (`set-buffer-multibyte')."
  (let* ((frexp (frexp (abs x)))
         (fract (car frexp))
         (exp (cdr frexp))
         (negp (< (copysign 1.0 x) 0.0))
         (biased-exp nil)
         (mantissa nil))
    (cond ((isnan x)     ; NaN
           (setf biased-exp #x7ff
                 mantissa #xc000000000000))
          ((> fract 1.0) ; infinity
           (setf biased-exp #x7ff
                 mantissa 0))
          ((= fract 0.0)  ; zero
           (setf biased-exp 0
                 mantissa 0))
          ((setf biased-exp (+ exp 1022)
                 mantissa (truncate (ldexp fract 53)))))
    (cl-case byte-order
      (:> (bitpack--store-f64> negp biased-exp mantissa))
      (:< (bitpack--store-f64< negp biased-exp mantissa)))))

(defun bitpack-store-i64 (byte-order x)
  "Store 64-bit integer X in buffer at point per BYTE-ORDER.

BYTE-ORDER may be :> (big endian) or :< (little endian).  The
buffer should *not* be multibyte (`set-buffer-multibyte')."
  (cl-case byte-order
    (:> (insert (logand (ash x -56) #xff)
                (logand (ash x -48) #xff)
                (logand (ash x -40) #xff)
                (logand (ash x -32) #xff)
                (logand (ash x -24) #xff)
                (logand (ash x -16) #xff)
                (logand (ash x  -8) #xff)
                (logand      x      #xff)))
    (:< (insert (logand      x      #xff)
                (logand (ash x  -8) #xff)
                (logand (ash x -16) #xff)
                (logand (ash x -24) #xff)
                (logand (ash x -32) #xff)
                (logand (ash x -40) #xff)
                (logand (ash x -48) #xff)
                (logand (ash x -56) #xff)))))

(defun bitpack-store-i32 (byte-order x)
  "Store 32-bit integer X in buffer at point per BYTE-ORDER.

BYTE-ORDER may be :> (big endian) or :< (little endian).  The
buffer should *not* be multibyte (`set-buffer-multibyte')."
  (cl-case byte-order
    (:> (insert (logand (ash x -24) #xff)
                (logand (ash x -16) #xff)
                (logand (ash x  -8) #xff)
                (logand      x      #xff)))
    (:< (insert (logand      x      #xff)
                (logand (ash x  -8) #xff)
                (logand (ash x -16) #xff)
                (logand (ash x -24) #xff)))))

(defun bitpack-store-i16 (byte-order x)
  "Store 16-bit integer X in buffer at point per BYTE-ORDER.

BYTE-ORDER may be :> (big endian) or :< (little endian).  The
buffer should *not* be multibyte (`set-buffer-multibyte')."
  (cl-case byte-order
    (:> (insert (logand (ash x  -8) #xff)
                (logand      x      #xff)))
    (:< (insert (logand      x      #xff)
                (logand (ash x  -8) #xff)))))

(defsubst bitpack-store-i8 (x)
  "Store 8-bit integer X in buffer at point.

The buffer should *not* be multibyte (`set-buffer-multibyte')."
  (insert (logand x #xff)))

;; Load functions

(defsubst bitpack--load-f32 (b0 b1 b2 b3)
  "Load single precision float from the given bytes.

B0, B1, B2, B3 are the bytes making up the float.
B0 contains the MSB."
  (let* ((negp (= #x80 (logand b0 #x80)))
         (exp (logand (logior (ash b0 1) (ash b1 -7)) #xff))
         (mantissa (logior #x800000
                           (ash (logand #x7f b1) 16)
                           (ash b2 8)
                           b3))
         (result (if (= #xff exp)
                     (if (= #x800000 mantissa)
                         1.0e+INF
                       0.0e+NaN)
                   (ldexp (ldexp mantissa -24) (- exp 126)))))
    (if negp
        (- result)
      result)))

(defsubst bitpack--load-f64 (b0 b1 b2 b3 b4 b5 b6 b7)
  "Load double precision float from the given bytes.

B0, B1, B2, B3, B4, B5, B6, B7 are the bytes making up the float.
B0 contains the MSB."
  (let* ((negp (= #x80 (logand b0 #x80)))
         (exp (logand (logior (ash b0 4) (ash b1 -4)) #x7ff))
         (mantissa (logior #x10000000000000
                           (ash (logand #xf b1) 48)
                           (ash b2 40)
                           (ash b3 32)
                           (ash b4 24)
                           (ash b5 16)
                           (ash b6  8)
                           b7))
         (result (if (= #x7ff exp)
                     (if (= #x10000000000000 mantissa)
                         1.0e+INF
                       0.0e+NaN)
                   (ldexp (ldexp mantissa -53) (- exp 1022)))))
    (if negp
        (- result)
      result)))

(defun bitpack-load-f32 (byte-order)
  "Load single precision float from buffer at point per BYTE-ORDER.

BYTE-ORDER may be :> (big endian) or :< (little endian).  The
point will be left just after the loaded value."
  (let ((b0 (prog1 (char-after) (forward-char)))
        (b1 (prog1 (char-after) (forward-char)))
        (b2 (prog1 (char-after) (forward-char)))
        (b3 (prog1 (char-after) (forward-char))))
    (cl-case byte-order
      (:> (bitpack--load-f32 b0 b1 b2 b3))
      (:< (bitpack--load-f32 b3 b2 b1 b0)))))

(defun bitpack-load-f64 (byte-order)
  "Load double precision float from buffer at point per BYTE-ORDER.

BYTE-ORDER may be :> (big endian) or :< (little endian).  The
point will be left just after the loaded value."
  (let ((b0 (prog1 (char-after) (forward-char)))
        (b1 (prog1 (char-after) (forward-char)))
        (b2 (prog1 (char-after) (forward-char)))
        (b3 (prog1 (char-after) (forward-char)))
        (b4 (prog1 (char-after) (forward-char)))
        (b5 (prog1 (char-after) (forward-char)))
        (b6 (prog1 (char-after) (forward-char)))
        (b7 (prog1 (char-after) (forward-char))))
    (cl-case byte-order
      (:> (bitpack--load-f64 b0 b1 b2 b3 b4 b5 b6 b7))
      (:< (bitpack--load-f64 b7 b6 b5 b4 b3 b2 b1 b0)))))

(defsubst bitpack-load-u8 ()
  "Load unsigned 8-bit integer from buffer at point.

The point will be left just after the loaded value."
  (prog1 (char-after)
    (forward-char)))

(defsubst bitpack-load-s8 ()
  "Load signed 8-bit integer from buffer at point.

The point will be left just after the loaded value."
  (let ((b0 (prog1 (char-after) (forward-char))))
    (if (> b0 #x7f)
        (logior -256 b0)
      b0)))

(defun bitpack-load-u16 (byte-order)
  "Load unsigned 16-bit integer from buffer at point per BYTE-ORDER.

BYTE-ORDER may be :> (big endian) or :< (little endian).  The
point will be left just after the loaded value."
  (let ((b0 (prog1 (char-after) (forward-char)))
        (b1 (prog1 (char-after) (forward-char))))
    (cl-case byte-order
      (:> (logior (ash b0 8) b1))
      (:< (logior (ash b1 8) b0)))))

(defun bitpack-load-s16 (byte-order)
  "Load signed 16-bit integer from buffer at point per BYTE-ORDER.

BYTE-ORDER may be :> (big endian) or :< (little endian).  The
point will be left just after the loaded value."
  (let ((x (bitpack-load-u16 byte-order)))
    (if (> x #x7fff)
        (logior -65536 x)
      x)))

(defun bitpack-load-u32 (byte-order)
  "Load unsigned 32-bit integer from buffer at point per BYTE-ORDER.

BYTE-ORDER may be :> (big endian) or :< (little endian).  The
point will be left just after the loaded value."
  (let ((b0 (prog1 (char-after) (forward-char)))
        (b1 (prog1 (char-after) (forward-char)))
        (b2 (prog1 (char-after) (forward-char)))
        (b3 (prog1 (char-after) (forward-char))))
    (cl-case byte-order
      (:> (logior (ash b0 24) (ash b1 16) (ash b2 8) b3))
      (:< (logior (ash b3 24) (ash b2 16) (ash b1 8) b0)))))

(defun bitpack-load-s32 (byte-order)
  "Load signed 32-bit integer from buffer at point per BYTE-ORDER.

BYTE-ORDER may be :> (big endian) or :< (little endian).  The
point will be left just after the loaded value."
  (let ((x (bitpack-load-u32 byte-order)))
    (if (> x #x7fffffff)
        (logior -4294967296 x)
      x)))

(defmacro bitpack--strict (&rest body)
  "Toss out BODY if bignum is supported."
  (declare (indent 0))
  (unless (fboundp 'bignump)
    `(progn ,@body)))

(defun bitpack--load-i64 (byte-order)
  "Load 64-bit integer from buffer at point per BYTE-ORDER.

BYTE-ORDER may be :> (big endian) or :< (little endian).  The
point will be left just after the loaded value.

This is an internal function, use `bitpack-load-u64' or
`bitpack-load-s64' instead."
  (let ((b0 (prog1 (char-after) (forward-char)))
        (b1 (prog1 (char-after) (forward-char)))
        (b2 (prog1 (char-after) (forward-char)))
        (b3 (prog1 (char-after) (forward-char)))
        (b4 (prog1 (char-after) (forward-char)))
        (b5 (prog1 (char-after) (forward-char)))
        (b6 (prog1 (char-after) (forward-char)))
        (b7 (prog1 (char-after) (forward-char))))
    (bitpack--strict
      (let* ((msb (cl-case byte-order
                    (:> b0)
                    (:< b7)))
             (high (lsh msb -6)))
        (unless (or (= high #x00) (= high #x03))
          (signal 'arith-error (list "Unrepresentable" high
                                     b0 b1 b2 b3 b4 b5 b6 b7)))))
    (cl-case byte-order
      (:> (logior (ash b0 56) (ash b1 48) (ash b2 40) (ash b3 32)
                  (ash b4 24) (ash b5 16) (ash b6 8) b7))
      (:< (logior (ash b7 56) (ash b6 48) (ash b5 40) (ash b4 32)
                  (ash b3 24) (ash b2 16) (ash b1 8) b0)))))

(defun bitpack-load-u64 (byte-order)
  "Load unsigned 64-bit integer from buffer at point per BYTE-ORDER.

BYTE-ORDER may be :> (big endian) or :< (little endian).  The
point will be left just after the loaded value.

Prior to Emacs 27, this function will signal `arith-error' if the
integer cannot be represented as an Emacs Lisp integer."
  (let ((x (bitpack--load-i64 byte-order)))
    (prog1 x
      (bitpack--strict
        (when (< x 0)
          (signal 'arith-error (cons "Unrepresentable" x)))))))

(defun bitpack-load-s64 (byte-order)
  "Load signed 64-bit integer from buffer at point per BYTE-ORDER.

BYTE-ORDER may be :> (big endian) or :< (little endian).  The
point will be left just after the loaded value.

Prior to Emacs 27, this function will signal `arith-error' if the
integer cannot be represented as an Emacs Lisp integer."
  (let ((x (bitpack--load-i64 byte-order)))
    (if (> x #x7fffffffffffffff)
        (logior -18446744073709551616 x)
      x)))

(provide 'bitpack)

;;; bitpack.el ends here
