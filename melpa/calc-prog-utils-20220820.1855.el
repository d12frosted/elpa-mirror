;;; calc-prog-utils.el --- Calc programmers utilities -*- lexical-binding: t -*-

;; Author: Jesse Millwood
;; Maintainer: Jesse Millwood
;; Version: 0.1
;; Package-Version: 20220820.1855
;; Package-Commit: 190acfda56660a2d75df2d9eac5b14edaccccd80
;; Homepage: https://github.com/Jesse-Millwood/calc-prog
;; Keywords: tools, convenience
;; Package-Requires: ((emacs "24.1"))


;; This file is not part of GNU Emacs

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

;; This package provides utilities for programmers using calc.
;; The added features to calc are:
;;  - Added common IEC binary units
;;    - Multi-byte units found at
;;      https://en.wikipedia.org/wiki/Byte#Multiple-byte_units
;;  - Easier shifting function
;;  - Masking functions
;;  - Better kill/yank functions
;;
;; To convert between iec representation to hex
;; To use:
;;  - Enter Algebra mode: '
;;  - Enter number: 64 MiB
;;  - Convert to byte: u c B
;;  - Display in binary: d 2
;;  - Show grouping: d g


;;; Code:
(require 'calc-units)
(require 'calc)

(defvar calc-prog-utils-math-additional-units '(
  (PiB "1024 ^ 5 * B" "Pebibyte")
  (TiB "1024 ^ 4 * B" "Tebibyte")
  (GiB "1024 ^ 3 * B" "Gibibbyte")
  (MiB "1024 ^ 2 * B" "Mebibyte")
  (KiB "1024 * B" "Kibibyte")
  (B "8 * bit" "A byte is the usual grouping of bits to be used in computational storage")
  (bit nil "The most basic computational storage unit"))
  "Additional math units that cover a few IEC binary units.")

(mapc (lambda (unit) (add-to-list 'math-additional-units unit))
      calc-prog-utils-math-additional-units)

;; after changing `math-additional-units', `math-units-table' must be
;; set to nil to ensure that the combined units table will be rebuilt:
(setq math-units-table nil)


;;;###autoload
(defmath prog-shift-left-by (number shift)
  "Logical shift NUMBER by SHIFT bits to left.
Use first two items on the stack.  First item is NUMBER and second
 item is SHIFT."
  (interactive 2 "l-shft")
  (lsh number shift))

;;;###autoload
(defmath prog-shift-right-by (number shift)
  "Logical shift NUMBER by SHIFT bits to right.
Use first two items on the stack.  First item is NUMBER and second
 item is SHIFT."
  (interactive 2 "r-shft")
  (lsh number (* -1 shift)))

;;;###autoload
(defmath prog-mask (number mask)
  "Apply the MASK to the NUMBER with an AND operation.
Use first two items on the stack.  First item is NUMBER and second
 item is MASK."
  (interactive 2 "Masked")
  (logand number mask))

;;;###autoload
(defmath prog-hex-kill (n)
  "Kill the number on the top of the stack as the hex representation."
  (interactive 1 "hex-kill")
  (kill-new (format "0x%X" n))
  (+ 0 n))

(provide 'calc-prog-utils)

;;; calc-prog-utils.el ends here
