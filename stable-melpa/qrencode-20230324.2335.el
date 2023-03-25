;;; qrencode.el --- QRCode encoder  -*- lexical-binding: t -*-

;; Copyright (C) 2021-2023 Rüdiger Sonderfeld <ruediger@c-plusplus.net>

;; Author: Rüdiger Sonderfeld <ruediger@c-plusplus.net>
;; Keywords: qrcode comm
;; Package-Version: 20230324.2335
;; Package-Commit: d7896e9594d45d7b2622d4617ff9cb7037378167
;; Version: 1.2
;; Package-Requires: ((emacs "25.1"))
;; Package: qrencode
;; URL: https://github.com/ruediger/qrencode-el

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; qrencode provides a QR Code (ISO/IEC 18004:2015) encoder written
;; entirely in Emacs Lisp (elisp).  See README.org for full
;; documentation.
;;
;; Usage: Call `qrencode-region' to convert a region into a QR Code
;; and `qrencode-url-at-point' to convert a URL.  QR Codes are shown
;; in a separate buffer.

;;; Code:

(require 'cl-lib)
(eval-when-compile (require 'easymenu))
(require 'seq)
(require 'thingatpt)

;;; Error correction
;; Reed solomon ECC implementation based on https://research.swtch.com/field

(defun qrencode--mul-no-lut (x y poly)
  "Caryless-multiply  X and Y modulo POLY."
  (let ((z 0))
    (while (> x 0)
      (when (/= (logand x 1) 0)
        (setq z (logxor z y)))
      (setq x (ash x -1))
      (setq y (ash y +1))
      ;; Modulo operation: If we shift y too far we have to subtract
      ;; poly again.
      (when (/= (logand y #x100) 0)
        (setq y (logxor y poly))))
    z))

(defun qrencode--init-field (poly a)
  "Initialise a field LUT with POLY and A."
  (let ((log (make-vector 256 0))
        (exp (make-vector 510 0))
        (x 1))
    (dotimes (i 255)
      (aset exp i x)
      (aset exp (+ i 255) x)
      (aset log x i)
      (setq x (qrencode--mul-no-lut x a poly)))
    (aset log 0 255)
    (list log exp)))

(defun qrencode--field-exp (field e)
  "Return exponential E in FIELD."
  (if (< e 0)
      0
    (aref (cadr field) (% e 255))))

(defun qrencode--field-log (field l)
  "Return log of L in FIELD."
  (if (= l 0)
      -1
    (aref (car field) l)))

(defun qrencode--field-mul (field x y)
  "Multiply X with Y in FIELD."
  (if (or (= x 0) (= y 0))
      0
    (qrencode--field-exp field
                         (+ (qrencode--field-log field x)
                            (qrencode--field-log field y)))))

(defun qrencode--gen (field e)
  "Return generator polynomial of degree E and its log in FIELD."
  (let ((p (make-vector (1+ e) 0))
        (lp (make-vector (1+ e) 0)))  ; log(p)
    ;; calculate p
    (aset p e 1)
    (dotimes (i e)
      (let ((c (qrencode--field-exp field i)))
        (dotimes (j e)
          (aset p j (logxor
                     (qrencode--field-mul field (aref p j) c)
                     (aref p (1+ j)))))
        (aset p e (qrencode--field-mul field (aref p e) c))))

    ;; calculate log(p)
    (dotimes (i (1+ e))
      (let ((c (aref p i)))
        (if (= c 0)
            (aset lp i 255)
          (aset lp i (qrencode--field-log field c)))))

    (list p (seq-subseq lp 1))))

(defun qrencode--ecc (data c &optional field lgen)
  "Return ECC for DATA with length C.
Optionally provide a FIELD and LGEN (log of generator polynomial)."
  (setq field (or field (qrencode--init-field #x11d 2)))
  (setq lgen (or lgen (cadr (qrencode--gen field c))))
  (let ((p (vconcat data (make-vector c 0))))  ; Data padded with 0 bytes

    (dotimes (i (length data))
      (unless (= (aref p i) 0)
        (let ((exp (qrencode--field-log field (aref p i))))
          (dotimes (j (length lgen))
            (let ((lg (aref lgen j)))
              (when (/= lg 255)
                (aset p (+ i j 1)
                      (logxor (aref p (+ i j 1))
                              (aref (cadr field) (+ exp lg))))))))))
    (seq-subseq p (length data))))

;;; Util

(defun qrencode--size (version)
  "Return number of modules for VERSION."
  (cl-assert (<= 1 version 40) 'show-args "Version %d out of valid range [1, 40]" version)
  (+ (* (1- version) 4) 21))

;;; Data encoding
(defun qrencode--mode (mode)
  "Return encoding representation of MODE."
  (pcase mode
    ('byte 4)  ; 0100
    ;; TODO(#11): Support other encodings
    (other (error "Mode %s not supported" other))))

(defun qrencode--encode-byte (input version)
  "Return INPUT encoded in byte format for QR Code size VERSION.
See Section 7.4 of ISO/IEC standard.  This code adds a 4 bit mode
indicator and then the character count in either 16 bit (for
version > 9) or 8 bit, followed by input."
  (let* ((l (length input))
         (rest (logand l #xF)))
    (cl-assert (<= l (if (> version 9) 65535 255)))
    (vconcat
     (vector (logior (ash (qrencode--mode 'byte) 4)
                     ;; Version <=9 use 8 bit, larger 16 bit for size
                     (ash l (if (<= version 9) -4 -12))))
     (when (> version 9)
       (vector (ash (logand l #xFF0) -4)))
     (cl-loop for d across input
              vconcat (vector (logior (ash rest 4) (ash d -4)))
              do (setq rest (logand d #xF)))
     (vector (ash rest 4)))))

;;; Basic patterns and templates handling
(defconst qrencode--finder-pattern
  '[[1 1 1 1 1 1 1]
    [1 0 0 0 0 0 1]
    [1 0 1 1 1 0 1]
    [1 0 1 1 1 0 1]
    [1 0 1 1 1 0 1]
    [1 0 0 0 0 0 1]
    [1 1 1 1 1 1 1]]
  "QRCode Finder Pattern.")

(defconst qrencode--alignment-pattern
  '[[1 1 1 1 1]
    [1 0 0 0 1]
    [1 0 1 0 1]
    [1 0 0 0 1]
    [1 1 1 1 1]]
  "QRCode Alignment Pattern.")

(defconst qrencode--alignment-pattern-placement
  '[nil
    nil
    [6 18]
    [6 22]
    [6 26]
    [6 30]
    [6 34]
    [6 22 38]
    [6 24 42]
    [6 26 46]
    [6 28 50]
    [6 30 54]
    [6 32 58]
    [6 34 62]
    [6 26 46 66]
    [6 26 48 70]
    [6 26 50 74]
    [6 30 54 78]
    [6 30 56 82]
    [6 30 58 86]
    [6 34 62 90]
    [6 28 50 72 94]
    [6 26 50 74 98]
    [6 30 54 78 102]
    [6 28 54 80 106]
    [6 32 58 84 110]
    [6 30 58 86 114]
    [6 34 62 90 118]
    [6 26 50 74 98 122]
    [6 30 54 78 102 126]
    [6 26 52 78 104 130]
    [6 30 56 82 108 134]
    [6 34 60 86 112 138]
    [6 30 58 86 114 142]
    [6 34 62 90 118 146]
    [6 30 54 78 102 126 150]
    [6 24 50 76 102 128 154]
    [6 28 54 80 106 132 158]
    [6 32 58 84 110 136 162]
    [6 26 54 82 110 138 166]
    [6 30 58 86 114 142 170]]
  "Placement of alignment pattern.  Vector index is the version.")

(defun qrencode--square (n &optional init)
  "Return a square of size N.
The square is initialised with INIT or 0."
  (let ((sq (make-vector n '[])))
    (dotimes (i n)
      (aset sq i (make-vector n (or init 0))))
    sq))

(defun qrencode--aaset (dst x y val)
  "Set in sequence of sequences DST position X (inner), Y (outer) to VAL."
  (aset (aref dst y) x val))

(defun qrencode--aaref (src x y)
  "Return from sequence of sequences SRC value at position X (inner), Y (outer)."
  (aref (aref src y) x))

(defun qrencode--copy-square (dst pattern x y)
  "Copy to DST from PATTERN at X and Y."
  (dotimes (i (length pattern))
    (dotimes (j (length (aref pattern i)))
      (qrencode--aaset dst (+ x j) (+ y i) (qrencode--aaref pattern j i)))))

(defun qrencode--set-rect (dst x y width height &optional value)
  "Set a rectangle in DST at X, Y of WIDTH and HEIGHT to VALUE."
  (dotimes (i height)
    (dotimes (j width)
      (qrencode--aaset dst (+ x j) (+ y i) (or value 1)))))

(defun qrencode--template (version)
  "Return basic QRCode template for VERSION."
  (let* ((size (qrencode--size version))
         (qrcode (qrencode--square size))
         (function-pattern (qrencode--square size)))  ; Keeps track of location of function patterns
    ;; Finder pattern
    ;; Top Left
    (qrencode--copy-square qrcode qrencode--finder-pattern 0 0)
    (qrencode--set-rect function-pattern 0 0 9 9) ; finder pattern + separator

    ;; Top Right
    (qrencode--copy-square qrcode qrencode--finder-pattern (- size 7) 0)
    (qrencode--set-rect function-pattern (- size 8) 0 8 8)  ; finder pattern + separator
    (when (>= version 7)
      (qrencode--set-rect function-pattern (- size 11) 0 3 6))  ; version info
    (qrencode--set-rect function-pattern (- size 8) 8 8 1) ; format info

    ;; Bottom Left
    (qrencode--copy-square qrcode qrencode--finder-pattern 0 (- size 7))
    (qrencode--set-rect function-pattern 0 (- size 8) 8 8)  ; finder pattern + separator
    (when (>= version 7)
      (qrencode--set-rect function-pattern 0 (- size 11) 6 3))  ; version info
    (qrencode--set-rect function-pattern 8 (- size 8) 1 8)  ; format info

    ;; Alignment patterns
    (let ((alignment-pattern (aref qrencode--alignment-pattern-placement version)))
      (when alignment-pattern
        ;; Alignment patterns are placed centred at all row/column
        ;; combinations.
        (seq-doseq (r alignment-pattern)
          (seq-doseq (c alignment-pattern)
            (unless (= 1 (qrencode--aaref function-pattern c r))
              (qrencode--copy-square qrcode qrencode--alignment-pattern (- c 2) (- r 2))
              (qrencode--set-rect function-pattern (- c 2) (- r 2) 5 5))))))


    ;; Timing pattern
    (cl-loop for i from 8 to (- size 8)
             do (qrencode--aaset qrcode 6 i (% (1+ i) 2))
             do (qrencode--aaset function-pattern 6 i 1)
             do (qrencode--aaset qrcode i 6 (% (1+ i) 2))
             do (qrencode--aaset function-pattern i 6 1))

    (cons qrcode function-pattern)))

(defun qrencode--nextpos (row column size up)
  "Return next possible ROW, COLUMN and UP value in square of SIZE."
  ;; A QRcode "column" (not to be confused with the column var here,
  ;; which is the x module position) is two modules (pixels).
  ;; Placement is from right to left and then upwards.
  ;;
  ;; Size or the QRCode is odd. So if a column number is even (except
  ;; if we are in column < 6 due to the timing pattern in col 6) the
  ;; go left.  Otherwise go upwards/downwards (depending on up) and
  ;; right.  Except if we hit the top/bottom then move a QCode column
  ;; (two modules) to the right and change direction (up).
  (when (= column 6)  ; Handle timing pattern column 6
    (setq column 5))

  (if (= (% column 2) (if (< column 6) 1 0))
      (if (<= column 0)
          (error "Overflowing pattern.  Data too large?")
        (list row (1- column) up))
    (if up
        (if (= row 0)
            (if (= column 0)
                (error "Overflowing pattern.  Data too large?")
              (list row (1- column) nil))
          (list (1- row) (1+ column) up))
      (if (>= row  (1- size))
          (if (= column 0)
              (error "Overflowing pattern.  Data too large?")
            (list row (1- column) t))
        (list (1+ row) (1+ column) up)))))

(defun qrencode--draw-data (qrcode function-pattern version data)
  "Draw DATA on QRCODE of VERSION and respecting FUNCTION-PATTERN."
  (let* ((size (qrencode--size version))
         (up t)
         (row (1- size))
         (column (1- size)))
    (cl-loop for byte across data and didx from 0
             do (cl-loop for bidx from 7 downto 0
                         do (qrencode--aaset qrcode column row (logand (ash byte (- bidx)) 1))
                         do (unless (and (= didx (1- (length data))) (= bidx 0))
                              ;; Find new position avoiding function-patterns.
                              (cl-loop do (pcase-let ((`(,nrow ,ncolumn ,nup) (qrencode--nextpos row column size up)))
                                            (setq row nrow
                                                  column ncolumn
                                                  up nup))
                                       while (= (qrencode--aaref function-pattern row column) 1)))))))


;;; Data masking
(defun qrencode--penalty (qr)
  "Return penalty (the higher the worse) for a given QR pattern."

  (let ((size (length qr))
        (penalty 0))

    ;; 1. Adjacency:
    ;; More than 5 adjacent modules of same colour.
    (let ((N1 3))
      ;; Scan columns
      (let ((row 0) (col 0))
        (while (< row (1- size))
          (while (< col (1- size))
            (if (= (qrencode--aaref qr col row)
                   (qrencode--aaref qr (1+ col) row))
                (let ((i 1))
                  (while (and (< col (1- size)) (= (qrencode--aaref qr col row)
                                                   (qrencode--aaref qr (1+ col) row)))
                    (setq i (1+ i)
                          col (1+ col)))
                  (when (> i 5)
                    (setq penalty (+ penalty N1 (- i 5)))))
              (setq col (1+ col))))
          (setq row (1+ row)
                col 0)))

      ;; Scan rows
      (let ((row 0) (col 0))
        (while (< col (1- size))
          (while (< row (1- size))
            (if (= (qrencode--aaref qr col row)
                   (qrencode--aaref qr col (1+ row)))
                (let ((i 1))
                  (while (and (< row (1- size)) (= (qrencode--aaref qr col row)
                                                   (qrencode--aaref qr col (1+ row))))
                    (setq i (1+ i)
                          row (1+ row)))
                  (when (> i 5)
                    (setq penalty (+ penalty N1 (- i 5)))))
              (setq row (1+ row))))
          (setq col (1+ col)
                row 0))))

    ;; 2. Block (2×2 block) of modules of the same colour
    (let ((N2 3))
      (setq penalty (+ penalty
                       (cl-loop for row from 0 below (1- size)
                                sum (cl-loop for col from 0 below (1- size)
                                             when (= (qrencode--aaref qr col row)
                                                     (qrencode--aaref qr col (1+ row))
                                                     (qrencode--aaref qr (1+ col) row)
                                                     (qrencode--aaref qr (1+ col) (1+ row)))
                                             sum N2)))))

    ;; 3. 1:1:3:1:1 pattern
    ;; Pattern: 4 light modules before/after 1011101. I.e., 00001011101 or 10111010000.
    (let ((N3 40))
      (let ((row 0) (col 0))
        (while (< row (1- size))
          (while (< col (- size 10))
            ;; Optimisation: Both patterns match in these spots
            (when (and (= 0 (qrencode--aaref qr (+ col 1) row))
                       (= 1 (qrencode--aaref qr (+ col 4) row))
                       (= 0 (qrencode--aaref qr (+ col 5) row))
                       (= 1 (qrencode--aaref qr (+ col 6) row))
                       (= 0 (qrencode--aaref qr (+ col 9) row))
                       (or (and
                            ;; Pattern beginning with 0
                            (= 0 (qrencode--aaref qr col row))
                            ;; 0
                            (= 0 (qrencode--aaref qr (+ col 2) row))
                            (= 0 (qrencode--aaref qr (+ col 3) row))
                            ;; 1
                            (= 1 (qrencode--aaref qr (+ col 7) row))
                            (= 1 (qrencode--aaref qr (+ col 8) row))
                            ;; 0
                            (= 1 (qrencode--aaref qr (+ col 10) row)))
                           (and
                            ;; Pattern ending with 0
                            (= 1 (qrencode--aaref qr col row))
                            ;; 0
                            (= 1 (qrencode--aaref qr (+ col 2) row))
                            (= 1 (qrencode--aaref qr (+ col 3) row))
                            ;; 1
                            (= 0 (qrencode--aaref qr (+ col 7) row))
                            (= 0 (qrencode--aaref qr (+ col 8) row))
                            ;; 0
                            (= 0(qrencode--aaref qr (+ col 10) row)))))
              (setq penalty (+ penalty N3)))
            (setq col (1+ col)))
          (setq row (1+ row)
                col 0)))

      (let ((row 0) (col 0))
        (while (< col (1- size))
          (while (< row (- size 10))
            ;; Optimisation: Both patterns match in these spots
            (when (and (= 0 (qrencode--aaref qr col (+ row 1)))
                       (= 1 (qrencode--aaref qr col (+ row 4)))
                       (= 0 (qrencode--aaref qr col (+ row 5)))
                       (= 1 (qrencode--aaref qr col (+ row 6)))
                       (= 0 (qrencode--aaref qr col (+ row 9)))
                       (or (and
                            ;; Pattern beginning with 0
                            (= 0 (qrencode--aaref qr col row))
                            ;; 0
                            (= 0 (qrencode--aaref qr col (+ row 2)))
                            (= 0 (qrencode--aaref qr col (+ row 3)))
                            ;; 1
                            (= 1 (qrencode--aaref qr col (+ row 7)))
                            (= 1 (qrencode--aaref qr col (+ row 8)))
                            ;; 0
                            (= 1 (qrencode--aaref qr col (+ row 10))))
                           (and
                            ;; Pattern ending with 0
                            (= 1 (qrencode--aaref qr col row))
                            ;; 0
                            (= 1 (qrencode--aaref qr col (+ row 2)))
                            (= 1 (qrencode--aaref qr col (+ row 3)))
                            ;; 1
                            (= 0 (qrencode--aaref qr col (+ row 7)))
                            (= 0 (qrencode--aaref qr col (+ row 8)))
                            ;; 0
                            (= 0(qrencode--aaref qr col (+ row 10))))))
              (setq penalty (+ penalty N3)))
            (setq row (1+ row)))
          (setq col (1+ col)
                row 0))))

    ;; 4. Ratio of dark to light
    (let ((N4 10)
          (dark (cl-loop for row across qr
                         sum (cl-loop for d across row sum d))))
      (setq penalty
            (+ penalty
               ;; Every 5% deviation from 50% dark/white ratio is penalised.
               (* (floor (/ (abs (- 0.5 (/ dark (* size size)))) 0.05) N4)))))

    penalty))

(defconst qrencode--masks
  [(lambda (i j) (= (% (+ i j) 2) 0))
   (lambda (i _j) (= (% i 2) 0))
   (lambda (_i j) (= (% j 3) 0))
   (lambda (i j) (= (% (+ i j) 3) 0))
   (lambda (i j) (= (% (+ (/ i 2) (/ j 3)) 2) 0))
   (lambda (i j) (= (+ (% (* i j) 2) (% (* i j) 3)) 0))
   (lambda (i j) (= (% (+ (% (* i j) 2) (% (* i j) 3)) 2) 0))
   (lambda (i j) (= (% (+ (% (+ i j) 2) (% (* i j) 3)) 2) 0))]
  "Mask patterns.")

(defun qrencode--copy (seq)
  "Copy a sequence of sequence SEQ."
  (let ((sq (make-vector (length seq) '[])))
    (dotimes (i (length seq))
      (aset sq i (seq-copy (aref seq i))))
    sq))

(defun qrencode--apply-mask (qrcode function-pattern datamask)
  "Return a copy of QRCODE with DATAMASK applied except for FUNCTION-PATTERN."
  (let ((qr (qrencode--copy qrcode))
        (size (length qrcode))
        (m (aref qrencode--masks datamask)))
    (cl-loop for i below size
             do (cl-loop for j below size
                         unless (= (qrencode--aaref function-pattern j i) 1)
                         do (qrencode--aaset qr j i
                                             (logxor (qrencode--aaref qr j i)
                                                     (if (funcall m i j) 1 0)))))
    qr))

(defun qrencode--find-best-mask (qr function-pattern)
  "Return QR with best mask applied and mask number, avoiding FUNCTION-PATTERN."
  (let (bestqr (bestmask 0) (bestpenalty #xFFFFFFFF))
    (dotimes (mask (length qrencode--masks))
      (let* ((newqr (qrencode--apply-mask qr function-pattern mask))
             (penalty (qrencode--penalty newqr)))
        (when (< penalty bestpenalty)
          (setq bestqr newqr
                bestmask mask
                bestpenalty penalty))))
    (cons bestqr bestmask)))

;;; Version/Info encoding
(defun qrencode--bit-length (x)
  "Return the number of bits necessary to represent integer X in binary."
  (let ((r 0))
    (while (> x 0)
      (setq x (ash x -1)
            r (1+ r)))
    r))

(defun qrencode--mod (x y)
  "Return remainder of carry-less long division of X over Y."
  (let ((xbl (qrencode--bit-length x))
        (ybl (qrencode--bit-length y)))
    (unless (< xbl ybl)
      (cl-loop for i from (- xbl ybl) downto 0
               when (/= (logand x (ash 1 (+ i ybl -1)))  0)
               do (setq x (logxor x (ash y i)))))
    x))

(defun qrencode--bch-encode (data &optional mask)
  "Return DATA properly error correction encoded for info data.
Optionally provide a MASK or #x5412 is used."
  (logxor (ash data 10) (qrencode--mod (ash data 10)
                                       #x537)  ; 10100110111
          (or mask #x5412)))  ; 101010000010010

(defun qrencode--errcorr (errcorr)
  "Return info representation of error correction level ERRCORR."
  (pcase errcorr
    ('L 1)  ; 01
    ('M 0)  ; 00
    ('Q 3)  ; 11
    ('H 2)  ; 10
    (other (error "Unknown error correction level %s" other))))

(defun qrencode--encode-info (qr errcorr datamask)
  "Set info data on QR encoding ERRCORR and DATAMASK."
  (let* ((size (length qr))
         (info (qrencode--bch-encode (logior (ash (qrencode--errcorr errcorr) 3) datamask)))
         (r1 0) (c1 8)
         (r2 8) (c2 (1- size)))
    (dotimes (i 8)
      (let ((data (logand (ash info (- i)) 1)))
        (qrencode--aaset qr c1 r1 data)
        (setq r1 (1+ r1))
        (when (= r1 6)                  ; Avoid timing pattern
          (setq r1 (1+ r1)))
        (qrencode--aaset qr c2 r2 data)
        (setq c2 (1- c2))))

    (setq c1 (1- c1)
          r1 (1- r1)
          r2 (- size 7)
          c2 8)
    (qrencode--aaset qr c2 (1- r2) 1)   ; Dark module in corner
    (cl-loop for i from 8 to 14
             do (let ((data (logand (ash info (- i)) 1)))
                  (qrencode--aaset qr c1 r1 data)
                  (setq c1 (1- c1))
                  (when (= c1 6)        ; Avoid timing pattern
                    (setq c1 (1- c1)))
                  (qrencode--aaset qr c2 r2 data)
                  (setq r2 (1+ r2))))))

(defun qrencode--version-ecc (v)
  "Return version V info error correction code."
  (logior (ash v 12)
          (qrencode--mod (ash v 12)
                         #x1F25))) ; 1111100100101

(defun qrencode--encode-version (qr version)
  "Set on QR the VERSION data."
  (unless (< version 7)      ; only version >= 7 have version encoding
    (let ((e (qrencode--version-ecc version))
          (size (length qr)))
      (let ((c1 0) (r1 (- size 11))  ; Bottom left version location
            (c2 (- size 11)) (r2 0))  ; Top right version location
        (cl-loop for i from 0 to 17
                 ;; Calculate row/column.  A and B usage as row/column
                 ;; switch depend on bottom/top location.
                 do (let ((a (/ i 3)) (b (% i 3))
                          (val (logand (ash e (- i)) 1)))
                      (qrencode--aaset qr (+ c1 a) (+ r1 b) val)
                      (qrencode--aaset qr (+ c2 b) (+ r2 a) val)))))))

(defun qrencode--unused (_)
  "This doesn't use _ but tricks the compiler.")

;; Analyse data: sizing etc.
(defun qrencode--char-count-bits (version mode)
  "Return the number of bits per character given VERSION and MODE."
  (cdr (assq mode
             (pcase version
               ((and n (guard (<= 1 n 9)))
                (qrencode--unused n)
                '((numeric      . 10)
                  (alphanumeric .  9)
                  (byte         .  8)
                  (kanji        .  8)))
               ((and n (guard (<= 10 n 26)))
                (qrencode--unused n)
                '((numeric      . 12)
                  (alphanumeric . 11)
                  (byte         . 16)
                  (kanji        . 10)))
               ((and n (guard (<= 27 n 40)))
                (qrencode--unused n)
                '((numeric      . 14)
                  (alphanumeric . 13)
                  (byte         . 16)
                  (kanji        . 12)))
               (other (error "Unsupported version %d (range 1 to 40)" other))))))

(defun qrencode--length-in-version (n version mode)
  "Return length of a string of size N in VERSION and MODE."
  (+ n (ceiling (+ 4 (/ (qrencode--char-count-bits version mode) 8)))))

(defconst qrencode--size-table
  [(26 . ((L . ( 7 3 1))
          (M . (10 2 1))
          (Q . (13 1 1))
          (H . (17 1 1))))
   (44 . ((L . (10 2 1))
          (M . (16 0 1))
          (Q . (22 0 1))
          (H . (28 0 1))))
   (70 . ((L . (15 1 1))
          (M . (26 0 1))
          (Q . (36 0 2))
          (H . (44 0 2))))
   (100 . ((L . (20 0 1))
           (M . (36 0 2))
           (Q . (52 0 2))
           (H . (64 0 4))))
   (134 . ((L . (26 0 1))  ; 5
           (M . (48 0 2))
           (Q . (72 0 ((2 . 15) . (2 . 16))))
           (H . (88 0 ((2 . 11) . (2 . 12))))))
   (172 . ((L . (36 0 2))
           (M . (64 0 4))
           (Q . (96 0 4))
           (H . (112 0 4))))
   (196 . ((L . (40 0 2))
           (M . (72 0 4))
           (Q . (108 0 ((2 . 14) . (4 . 15))))
           (H . (130 0 ((4 . 13) . (1 . 14))))))
   (242 . ((L . (48 0 2))
           (M . (88 0 ((2 . 38) . (2 . 39))))
           (Q . (132 0 ((4 . 18) . (2 . 19))))
           (H . (156 0 ((4 . 14) . (2 . 15))))))
   (292 . ((L . (60 0 2))
           (M . (110 0 ((3 . 36) . (2 . 37))))
           (Q . (160 0 ((4 . 16) . (4 . 17))))
           (H . (192 0 ((4 . 12) . (4 . 13))))))
   (346 . ((L . (72 0 ((2 . 68) . (2 . 69))))
           (M . (130 0 ((4 . 43) . (1 . 44))))
           (Q . (192 0 ((6 . 19) . (2 . 20))))
           (H . (224 0 ((6 . 15) . (2 . 16))))))
   (404 . ((L . (80 0 4))
           (M . (150 0 ((1 . 50) . (4 . 51))))
           (Q . (224 0 ((4 . 22) . (4 . 23))))
           (H . (264 0 ((3 . 12) . (8 . 13))))))
   (466 . ((L . (96 0 ((2 . 92) . (2 . 93))))
           (M . (176 0 ((6 . 36) . (2 . 37))))
           (Q . (260 0 ((4 . 20) . (6 . 21))))
           (H . (308 0 ((7 . 14) . (4 . 15))))))
   (532 . ((L . (104 0 4))
           (M . (198 0 ((8 . 37) . (1 . 38))))
           (Q . (288 0 ((8 . 20) . (4 . 21))))
           (H . (352 0 ((12 . 11) . (4 . 12))))))
   (581 . ((L . (120 0 ((3 . 115) . (1 . 116))))
           (M . (216 0 ((4 . 40) . (5 . 41))))
           (Q . (320 0 ((11 . 16) . (5 . 17))))
           (H . (384 0 ((11 . 12) . (5 . 13))))))
   (655 . ((L . (132 0 ((5 . 87) . (1 . 88))))
           (M . (240 0 ((5 . 41) . (5 . 42))))
           (Q . (360 0 ((5 . 24) . (7 . 25))))
           (H . (432 0 ((11 . 12) . (7 . 13))))))
   (733 . ((L . (144 0 ((5 . 98) . (1 . 99))))
           (M . (280 0 ((7 . 45) . (3 . 46))))
           (Q . (408 0 ((15 . 19) . (2 . 20))))
           (H . (480 0 ((3 . 15) . (13 . 16))))))
   (815 . ((L . (168 0 ((1 . 107) . (5 . 108))))
           (M . (308 0 ((10 . 46) . (1 . 47))))
           (Q . (448 0 ((1 . 22) . (15 . 23))))
           (H . (532 0 ((2 . 14) . (17 . 15))))))
   (901 . ((L . (180 0 ((5 . 120) . (1 . 121))))
           (M . (338 0 ((9 . 43) . (4 . 44))))
           (Q . (504 0 ((17 . 22) . (1 . 23))))
           (H . (588 0 ((2 . 14) . (19 . 15))))))
   (991 . ((L . (196 0 ((3 . 113) . (4 . 114))))
           (M . (364 0 ((3 . 44) . (11 . 45))))
           (Q . (546 0 ((17 . 21) . (4 . 22))))
           (H . (650 0 ((9 . 13) . (16 . 14))))))
   (1085 . ((L . (224 0 ((3 . 107) . (5 . 108))))
            (M . (416 0 ((3 . 41) . (13 . 42))))
            (Q . (600 0 ((15 . 24) . (5 . 25))))
            (H . (700 0 ((15 . 15) . (10 . 16))))))
   (1156 . ((L . (224 0 ((4 . 116) . (4 . 117))))
            (M . (442 0 17))
            (Q . (644 0 ((17 . 22) . (6 . 23))))
            (H . (750 0 ((19 . 16) . (6 . 17))))))
   (1258 . ((L . (252 0 ((2 . 111) . (7 . 112))))
            (M . (476 0 17))
            (Q . (690 0 ((7 . 24) . (16 . 25))))
            (H . (816 0 34))))
   (1364 . ((L . (270 0 ((4 . 121) . (5 . 122))))
            (M . (504 0 ((4 . 47) . (14 . 48))))
            (Q . (750 0 ((11 . 24) . (14 . 25))))
            (H . (900 0 ((16 . 15) . (14 . 16))))))
   (1474 . ((L . (300 0 ((6 . 117) . (4 . 118))))
            (M . (560 0 ((6 . 45) . (14 . 46))))
            (Q . (810 0 ((11 . 24) . (16 . 25))))
            (H . (960 0 ((30 . 16) . (2 . 17))))))
   (1588 . ((L . (312 0 ((8 . 106) . (4 . 107))))
            (M . (588 0 ((8 . 47) . (13 . 48))))
            (Q . (870 0 ((7 . 24) . (22 . 25))))
            (H . (1050 0 ((22 . 15) . (13 . 16))))))
   (1706 . ((L . (336 0 ((10 . 114) . (2 . 115))))
            (M . (644 0 ((19 . 46) . (4 . 47))))
            (Q . (952 0 ((28 . 22) . (6 . 23))))
            (H . (1110 0 ((33 . 16) . (4 . 17))))))
   (1828 . ((L . (360 0 ((8 . 122) . (4 . 123))))
            (M . (700 0 ((22 . 45) . (3 . 46))))
            (Q . (1020 0 ((8 . 23) . (26 . 24))))
            (H . (1200 0 ((12 . 15) . (28 . 16))))))
   (1921 . ((L . (390 0 ((3 . 117) . (10 . 118))))
            (M . (728 0 ((3 . 45) . (23 . 46))))
            (Q . (1050 0 ((4 . 24) . (31 . 25))))
            (H . (1260 0 ((11 . 15) . (31 . 16))))))
   (2051 . ((L . (420 0 ((7 . 116) . (7 . 117))))
            (M . (784 0 ((21 . 45) . (7 . 46))))
            (Q . (1140 0 ((1 . 23) . (37 . 24))))
            (H . (1350 0 ((19 . 15) . (26 . 16))))))
   (2185 . ((L . (450 0 ((5 . 115) . (10 . 116))))
            (M . (812 0 ((19 . 47) . (10 . 48))))
            (Q . (1200 0 ((15 . 24) . (25 . 25))))
            (H . (1440 0 ((23 . 15) . (25 . 16))))))
   (2323 . ((L . (480 0 ((13 . 115) . (3 . 116))))
            (M . (868 0 ((2 . 46) . (29 . 47))))
            (Q . (1290 0 ((42 . 24) . (1 . 25))))
            (H . (1530 0 ((23 . 15) . (28 . 16))))))
   (2465 . ((L . (510 0 17))
            (M . (924 0 ((10 . 46) . (23 . 47))))
            (Q . (1350 0 ((10 . 24) . (35 . 25))))
            (H . (1620 0 ((19 . 15) . (35 . 16))))))
   (2611 . ((L . (540 0 ((17 . 115) . (1 . 116))))
            (M . (980 0 ((14 . 46) . (21 . 47))))
            (Q . (1440 0 ((29 . 24) . (19 . 25))))
            (H . (1710 0 ((11 . 15) . (46 . 16))))))
   (2761 . ((L . (570 0 ((13 . 115) . (6 . 116))))
            (M . (1036 0 ((14 . 46) . (23 . 47))))
            (Q . (1530 0 ((44 . 24) . (7 . 25))))
            (H . (1800 0 ((59 . 16) . (1 . 17))))))
   (2876 . ((L . (570 0 ((12 . 121) . (7 . 122))))
            (M . (1064 0 ((12 . 47) . (26 . 48))))
            (Q . (1590 0 ((39 . 24) . (14 . 25))))
            (H . (1890 0 ((22 . 15) . (41 . 16))))))
   (3034 . ((L . (600 0 ((6 . 121) . (14 . 122))))
            (M . (1120 0 ((6 . 47) . (34 . 48))))
            (Q . (1680 0 ((46 . 24) . (10 . 25))))
            (H . (1980 0 ((2 . 15) . (64 . 16))))))
   (3196 . ((L . (630 0 ((17 . 122) . (4 . 123))))
            (M . (1204 0 ((29 . 46) . (14 . 47))))
            (Q . (1770 0 ((49 . 24) . (10 . 25))))
            (H . (2100 0 ((24 . 15) . (46 . 16))))))
   (3362 . ((L . (660 0 ((4 . 122) . (18 . 123))))
            (M . (1260 0 ((13 . 46) . (32 . 47))))
            (Q . (1860 0 ((48 . 24) . (14 . 25))))
            (H . (2220 0 ((42 . 15) . (32 . 16))))))
   (3532 . ((L . (720 0 ((20 . 117) . (4 . 118))))
            (M . (1316 0 ((40 . 47) . (7 . 48))))
            (Q . (1950 0 ((43 . 24) . (22 . 25))))
            (H . (2310 0 ((10 . 15) . (67 . 16))))))
   (3706 . ((L . (750 0 ((19 . 118) . (6 . 119))))
            (M . (1372 0 ((18 . 47) . (31 . 48))))
            (Q . (2040 0 ((34 . 24) . (34 . 25))))
            (H . (2430 0 ((20 . 15) . (61 . 16))))))]
  "List of size table.
Index is version number - 1 and content is cons of size to an
assoc list of error correction level to number of error
correction code words, p, and error correction blocks.  See Table
9 in ISO/IEC 18004:2015.")

(defun qrencode--find-version (n mode &optional errcorr)
  "Return cons of version and error correction based on data length N, MODE.
Provide ERRCORR if a specific error correction level is desired,
otherwise this will try to find the highest level in the smallest
version."
  (or (cl-loop named outer-loop
               for entry across qrencode--size-table and version from 1
               do (pcase-let ((`(,num-codewords . ,errlevels) entry)
                              (m (qrencode--length-in-version n version mode)))
                    (if errcorr
                        (when (>= (- num-codewords (cadr (assq errcorr errlevels))) m)
                          (cl-return (cons version errcorr)))
                      (cl-loop for e in '(H Q M L) ; Go from highest err corr level to lowest
                               do (when (>= (- num-codewords (cadr (assq e errlevels))) m)
                                    (cl-return-from outer-loop (cons version e)))))))
      (user-error "No version found supporting %d in mode %s with error correction level %s" n mode errcorr)))

;;; Structuring
(defun qrencode--get-subseq (blocks n &optional off)
  "Return a list of cons of start and end of all subseqs BLOCKS with N bytes.
Optional offset OFF or 0."
  (setq off (or off 0))
  (cl-loop for i from 0 below blocks
           collect (cons (+ (* i n) off)
                         (+ (* (1+ i) n) off))))

(defun qrencode--get-blocks (version errcorr)
  "Return a list of all blocks (subseqs) for VERSION with ERRCORR level."
  (pcase-let* ((size-table (aref qrencode--size-table (1- version)))
               (num-codewords (car size-table))
               (`(,num-errcorr ,_p ,err-blocks) (cdr (assq errcorr (cdr size-table))))
               (num-words (- num-codewords num-errcorr)))
    (if (consp err-blocks)
        (pcase-let ((`(,first-block . ,second-block) err-blocks))
          (append
           (qrencode--get-subseq (car first-block) (cdr first-block))
           (qrencode--get-subseq (car second-block) (cdr second-block) (* (car first-block) (cdr first-block)))))
      (qrencode--get-subseq err-blocks (/ num-words err-blocks)))))

(defun qrencode--blocks (data version errcorr)
  "Return DATA split in blocks according to VERSION and ERRCORR level."
  (cl-loop for b in (qrencode--get-blocks version errcorr)
           vconcat (vector (seq-subseq data (car b) (cdr b)))))

;;; QRCode encoding
(defun qrencode (s &optional mode errcorr return-raw)
  "Encode string S into a QRCode.
Optionally specify MODE and ERRCORR level.  Only supported MODE
is `byte'.  If RETURN-RAW is set a raw vector version of the
QRCode is returned instead of a formatted string."
  ;; Following Section 7.1 from ISO/IEC 18004 2015

  (let (version data qr function-pattern datamask)
    ;; Step 1: Analyse data
    ;; TODO(#11): find suitable mode. For now we only support byte
    (setq mode (or mode 'byte))
    ;; Find the version with the highest error correction to fit the data
    (pcase-let ((`(,ver . ,ec) (qrencode--find-version (length s) mode errcorr)))
      (setq version ver
            errcorr ec))

    ;; Step 2: Encode data
    (setq data (qrencode--encode-byte s version))
    ;; Add padding
    (let* ((size-table (aref qrencode--size-table (1- version)))
           (qrlen (car size-table))
           (errcorrlen (cadr (assq errcorr (cdr size-table))))
           (datalen (- qrlen errcorrlen))
           (padding [#xEC #x11]))
      (setq data (vconcat data [#x40]  ; TODO: why the #x40?
                          (cl-loop for i from 0 below (- datalen (length data) 1)
                                   vconcat (vector (aref padding (% i 2))))))

      ;; Step 3: Error correction coding
      (let* ((datablocks (qrencode--blocks data version errcorr))
             (blockerrcorrlen (/ errcorrlen (length datablocks)))
             (field (qrencode--init-field #x11d 2))
             (lgen (cadr (qrencode--gen field blockerrcorrlen)))
             (errblocks (cl-loop for b across datablocks
                                 vconcat (vector (qrencode--ecc b blockerrcorrlen field lgen)))))

        ;; Step 4: Structure final message
        ;; Take from datablocks first until all data is taken and then add the error correction blocks.
        (setq data (vconcat (cl-loop for i from 0 below datalen
                                     vconcat (cl-loop for j from 0 below (length datablocks)
                                                      when (< i (length (aref datablocks j)))
                                                      vconcat (vector (seq-elt (aref datablocks j) i))))
                            (cl-loop for i from 0 below errcorrlen
                                     vconcat (cl-loop for j from 0 below (length errblocks)
                                                      when (< i (length (aref errblocks j)))
                                                      vconcat (vector (seq-elt (aref errblocks j) i))))))))

    ;; Step 5: Module placement
    (pcase-let ((`(,qrcode . ,fp) (qrencode--template version)))
      (qrencode--draw-data qrcode fp version data)
      (setq qr qrcode
            function-pattern fp))

    ;; Step 6: Data masking
    (pcase-let ((`(,qrcodemasked . ,mask) (qrencode--find-best-mask qr function-pattern)))
      (setq qr qrcodemasked
            datamask mask))

    ;; Step 7: Format and version information
    (qrencode--encode-info qr errcorr datamask)
    (qrencode--encode-version qr version)

    (if return-raw
        qr
      (qrencode-format qr))))

(defun qrencode-format (qr)
  "Format QR using utf-8 blocks."
  (let* ((size (length qr))
         (sizeqz (+ size 8)))  ; size with quiet zone
    (concat (make-string sizeqz ? ) "\n"
            (make-string sizeqz ? ) "\n"
            (cl-loop for row from 0 below (1- size) by 2
                     concat "    "
                     concat (cl-loop for col from 0 below size
                                     concat (if (and (/= (qrencode--aaref qr col row) 0)
                                                     (/= (qrencode--aaref qr col (1+ row)) 0))
                                                "█"
                                              (if (and (/= (qrencode--aaref qr col row) 0)
                                                       (= (qrencode--aaref qr col (1+ row)) 0))
                                                  "▀"
                                                (if (and (= (qrencode--aaref qr col row) 0)
                                                         (/= (qrencode--aaref qr col (1+ row)) 0))
                                                    "▄"
                                                  " "))))
                     concat "    \n")
            "    "
            (cl-loop for col from 0 below size
                     concat (if (/= (qrencode--aaref qr col (1- size)) 0) "▀" " "))
            "    \n"
            (make-string sizeqz ? ) "\n"
            (make-string sizeqz ? ) "\n")))

(defun qrencode--repeat-string (s n &optional sep)
  "Return string S repeated N timed with optional separator SEP in between."
  (cl-loop for i from 1 to n
           concat s
           when (/= i n)
           concat (or sep "")))

(defun qrencode-format-as-netpbm (qr &optional pixel-size)
  "Format QR as NetPBM (bitmap) file.
Optionally specify PIXEL-SIZE (default is 3)."
  (let* ((size (length qr))
         (factor (or pixel-size 3))
         (nsize (* (+ size 8) factor)))
    (concat (format "P1\n%d %d\n" nsize nsize)
            ;; Quiet zone top
            (cl-loop for i from 0 below (* 4 factor)
                     concat (qrencode--repeat-string "0" nsize " ")
                     concat "\n")
            (cl-loop for row from 0 below size
                     concat (cl-loop for i from 1 to factor
                                     ;; Quiet zone left
                                     concat (qrencode--repeat-string "0 " (* 4 factor))
                                     ;; QR Code
                                     concat (cl-loop for col from 0 below size
                                                     concat (qrencode--repeat-string
                                                             (format "%d " (qrencode--aaref qr col row))
                                                             factor))
                                     ;; Quiet zone right
                                     concat (qrencode--repeat-string "0" (* 4 factor) " ")
                                     concat "\n"))
            ;; Quiet zone bottom
            (cl-loop for i from 0 below (* 4 factor)
                     concat (qrencode--repeat-string "0" nsize " ")
                     concat "\n"))))

(defgroup qrencode nil
  "QREncode: Encoder for QR Codes."
  :link '(url-link "https://github.com/ruediger/qrencode-el")
  :prefix "qrencode-"
  :group 'communication)

(defcustom qrencode-buffer-name "*QRCode*"
  "Name to use for QRCode buffer."
  :type 'string
  :group 'qrencode)

(defcustom qrencode-export-pixel-size 3
  "Pixel size used for NetPBM (Bitmap) export."
  :type 'integer
  :group 'qrencode)

(defcustom qrencode-post-export-functions nil
  "Abnormal hook run after QRCode file export.
FILENAME of the exported file is passed as parameter.  For
example this can be used to convert the output to a different
bitmap format."
  :type 'hook
  :package-version "1.2-beta1"
  :group 'qrencode)

(defface qrencode-face
  '((t :foreground "black" :background "white"))
  "Face used for writing QRCodes."
  :group 'qrencode)

(defvar-local qrencode--raw-qr nil
  "Store raw QRCode content for further processing.")

(defun qrencode-export-buffer-to-file (filename)
  "Export QRCode as netpbm to FILENAME."
  (interactive "FFilename: ")
  (if (null qrencode--raw-qr)
      (error "No raw QRCode data found")
    (let ((qr qrencode--raw-qr))       ; save ref to buffer local var.
      (with-temp-file filename
        (insert (qrencode-format-as-netpbm qr qrencode-export-pixel-size)))
      (run-hook-with-args 'qrencode-post-export-functions filename)
      (message "Wrote QRCode to file %s" filename))))

(defvar qrencode-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map special-mode-map)
    (define-key map "e" #'qrencode-export-buffer-to-file)
    map)
  "Keymap for `qrencode-mode' map.")

(easy-menu-define qrencode-mode-menu qrencode-mode-map
  "Menu for QREncode Mode."
  '("QR"
    ["Export Image" qrencode-export-buffer-to-file :help "Export QRCode as a NetPBM bitmap image."]))

(define-derived-mode qrencode-mode special-mode "QRCode"
  "Major mode for viewing QR Codes.
Commands:
\\{qrencode-mode-map}"
  :group 'qrencode)

(defun qrencode--encode-to-buffer (s)
  "Encode S as QR Code and insert into `qrencode-buffer-name`."
  (save-excursion
    (let ((buf (get-buffer-create qrencode-buffer-name)))
      (with-current-buffer buf
        (let ((inhibit-read-only t))
          (erase-buffer)
          (setq-local line-spacing nil)  ; ensure no line spacing
          (qrencode-mode)
          (setq-local qrencode--raw-qr (qrencode s nil nil 'return-raw))
          (insert (propertize (qrencode-format qrencode--raw-qr) 'face 'qrencode-face))
          (insert "\nEncoded Text:\n" s)
          (goto-char (point-min)))
        (pop-to-buffer buf)))))


;;;###autoload
(defun qrencode-region (beg end)
  "Encode region between BEG and END into a QR code and show in a buffer."
  (interactive "r")
  (qrencode--encode-to-buffer (buffer-substring beg end)))

;;;###autoload
(defun qrencode-url-at-point ()
  "Encode any URL found at point."
  (interactive)
  (let ((url (thing-at-point-url-at-point)))
    (if (null url)
        (message "No URL found at point")
      (qrencode--encode-to-buffer url))))

(provide 'qrencode)

;;; qrencode.el ends here
