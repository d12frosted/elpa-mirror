;;; ascii-table.el --- Interactive ASCII table -*- lexical-binding: t -*-
;;
;; SPDX-License-Identifier: ISC
;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lassik/emacs-ascii-table
;; Package-Version: 20221230.1244
;; Package-Commit: c71f54b85edc6bd42abdc79dd82248958c8a24f9
;; Package-Requires: ((emacs "24.3"))
;; Version: 0.1.0
;; Keywords: help tools
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Show a character map of the ubiquitous 7-bit ASCII character set
;; (128 characters in total).
;;
;; Do `M-x ascii-table` to bring up a window with the ASCII table.  Press 'b'
;; for binary, 'o' for octal, 'd' for decimal and 'x' for hexadecimal.
;; Press TAB to change the way control characters are shown.
;;
;;; Code:

(require 'cl-lib)

(defvar ascii-table-base 16
  "Number base used for character codes in the ASCII table.

Valid values are 2 (binary), 8 (octal), 10 (decimal), and
16 (hex).  Another word for 'base' is 'radix'.")

(defvar ascii-table-control nil
  "Use ^A notation for control characters in the ASCII table?

If non-nil, control characters use caret notation (^A .. ^?).
Otherwise their names NUL .. DEL are shown.")

(defvar ascii-table-escape nil
  "Use backslash notation for control characters in the ASCII table?")

(defun ascii-table--binary (codepoint)
  "Internal helper to format CODEPOINT in binary."
  (cl-assert (<= 0 codepoint #x7F))
  (string (+ ?0 (logand 1 (lsh codepoint -6)))
          (+ ?0 (logand 1 (lsh codepoint -5)))
          (+ ?0 (logand 1 (lsh codepoint -4)))
          (+ ?0 (logand 1 (lsh codepoint -3)))
          (+ ?0 (logand 1 (lsh codepoint -2)))
          (+ ?0 (logand 1 (lsh codepoint -1)))
          (+ ?0 (logand 1 (lsh codepoint -0)))))

(defun ascii-table--class-face (class)
  "Internal helper to get face for character CLASS."
  (cl-case class
    (control font-lock-keyword-face)
    (punct font-lock-preprocessor-face)
    (space font-lock-string-face)
    (digit font-lock-function-name-face)
    (upper font-lock-variable-name-face)
    (lower font-lock-variable-name-face)
    (t nil)))

(defun ascii-table--character-class (codepoint)
  "Internal helper to classify CODEPOINT."
  (cond ((< codepoint #x00) nil)
        ((< codepoint #x09) 'control)
        ((< codepoint #x0e) 'space)
        ((< codepoint #x20) 'control)
        ((= codepoint #x20) 'space)
        ((< codepoint #x30) 'punct)
        ((< codepoint #x3a) 'digit)
        ((< codepoint #x41) 'punct)
        ((< codepoint #x47) 'upper)
        ((< codepoint #x5b) 'upper)
        ((< codepoint #x61) 'punct)
        ((< codepoint #x67) 'lower)
        ((< codepoint #x7b) 'lower)
        ((< codepoint #x7f) 'punct)
        ((= codepoint #x7f) 'control)
        (t nil)))

(defun ascii-table--control-caret (codepoint)
  "Internal helper to format CODEPOINT in caret notation."
  (cond ((< codepoint #x00) nil)
        ((< codepoint #x20) (string ?^ (+ ?@ codepoint)))
        ((= codepoint #x7F) "^?")
        (t nil)))

(defun ascii-table--control-name (codepoint)
  "Internal helper to get the control character name of CODEPOINT."
  (cond ((< codepoint #x00) nil)
        ((< codepoint #x20)
         (elt ["NUL" "SOH" "STX" "ETX" "EOT" "ENQ" "ACK" "BEL"
               "BS" "HT" "LF" "VT" "FF" "CR" "SO" "SI"
               "DLE" "DC1" "DC2" "DC3" "DC4" "NAK" "SYN" "ETB"
               "CAN" "EM" "SUB" "ESC" "FS" "GS" "RS" "US"]
              codepoint))
        ((= codepoint #x7F) "DEL")
        (t nil)))

(defun ascii-table--control-escape (codepoint)
  "Internal helper to get the C backslash escape of CODEPOINT."
  (cond ((<= #x07 codepoint #x0D)
         (string ?\\ (elt "abtnvfr" (- codepoint #x07))))
        ((= codepoint #x1B) "\\e")
        (t nil)))

(defun ascii-table--table (codepoints/row)
  "Internal helper to compute the cells in the ASCII table.

CODEPOINTS/ROW is how many ASCII characters to show in each row.

Each character takes two cells: one for the character number, and
one for the name or other representation."
  (let* ((codepoints 128)
         (rows (ceiling codepoints codepoints/row))
         (cols (* 2 codepoints/row))
         (table (make-vector (* 2 rows cols) (cons "" nil))))
    (cl-do
        ((codepoint 0 (1+ codepoint)))
        ((= codepoint codepoints) table)
      (let* ((code (cl-ecase ascii-table-base
                     (2  (ascii-table--binary codepoint))
                     (8  (format "%03o" codepoint))
                     (10 (format "%d" codepoint))
                     (16 (format "%02X" codepoint))))
             (name (or (and ascii-table-escape
                            (ascii-table--control-escape codepoint))
                       (cl-ecase ascii-table-control
                         ((nil) (ascii-table--control-name codepoint))
                         (caret (ascii-table--control-caret codepoint)))
                       (string codepoint)))
             (face (ascii-table--class-face
                    (ascii-table--character-class codepoint)))
             (row  (mod codepoint rows))
             (col  (truncate codepoint rows))
             (cell (* 2 (+ (* codepoints/row row) col))))
        (aset table (+ 0 cell) (cons code 'font-lock-comment-face))
        (aset table (+ 1 cell) (cons name face))))))

(defun ascii-table--column-widths (table cols)
  "Internal helper to compute column widths needed for TABLE.

Assume the table is formatted using COLS columns."
  (let* ((cells (length table))
         (widths (make-vector cols 0)))
    (cl-do
        ((cell 0 (1+ cell)))
        ((= cell cells) widths)
      (let* ((col (mod cell cols))
             (pair (aref table cell))
             (contents (car pair))
             (width (length contents)))
        (aset widths col (max (aref widths col) width))))))

(defun ascii-table--width-limit ()
  "Internal helper to get narrowest window width for ASCII table."
  (let ((min-width nil))
    (let ((ascii-table-buffer (get-buffer "*ASCII*")))
      (when ascii-table-buffer
        (walk-windows
         (lambda (w)
           (when (eq ascii-table-buffer (window-buffer w))
             (let ((width (window-width w)))
               (setq min-width (or (and min-width (min min-width width))
                                   width)))))
         nil t)))
    (or min-width (window-width))))

(defun ascii-table--revert (&optional _arg _noconfirm)
  "Redisplay the *ASCII* buffer, i.e. refresh the ASCII table."
  (let ((inhibit-read-only t))
    (cl-assert (equal major-mode 'ascii-table-mode))
    (cl-assert (null (buffer-file-name)))
    (erase-buffer)
    (insert "ASCII Table"
            " ("
            (cl-ecase ascii-table-base
              (2 "binary")
              (8 "octal")
              (10 "decimal")
              (16 "hex"))
            ")\n\n")
    (cl-dolist (codepoints/row '(8 7 6 5 4 3 2 1))
      (let* ((table (ascii-table--table codepoints/row))
             (cols (* 2 codepoints/row))
             (rows (truncate (truncate (length table) 2) cols))
             (widths (ascii-table--column-widths table cols))
             (width (+ (cl-reduce #'+ widths)
                       (* 2 (length widths))))
             (width-limit (ascii-table--width-limit)))
        (when (< width width-limit)
          (cl-dotimes (row rows)
            (cl-dotimes (col cols)
              (let* ((cell (+ col (* row cols)))
                     (pair (aref table cell))
                     (contents (car pair))
                     (face (cdr pair))
                     (col-width (aref widths col))
                     (pad-amount (max 0 (- col-width (length contents))))
                     (pad (make-string pad-amount ? ))
                     (right-justify-p (= 0 (mod col 2))))
                (unless (= col 0) (insert "  "))
                (when right-justify-p
                  (insert pad))
                (let ((start (point)))
                  (insert contents)
                  (let* ((end (point))
                         (overlay (make-overlay start end)))
                    (overlay-put overlay 'face face)))
                (unless right-justify-p
                  (insert pad))))
            (insert "\n"))
          (cl-return))))
    (goto-char (point-min))))

(defun ascii-table--revert-if-active ()
  "Redisplay the *ASCII* buffer if it exists."
  (let ((buffer (get-buffer "*ASCII*")))
    (when buffer (with-current-buffer buffer (ascii-table--revert)))))

(defun ascii-table--set-base (base)
  "Internal helper to change the ASCII number base to BASE."
  (setq ascii-table-base (cl-case base ((2 8 16) base) (t 10)))
  (ascii-table--revert-if-active))

(defun ascii-table-toggle-control ()
  "Toggle the way control characters are shown in the ASCII table.

Changes between ^A notation and control character names."
  (interactive)
  (setq ascii-table-control (if ascii-table-control nil 'caret))
  (ascii-table--revert-if-active))

(defun ascii-table-toggle-escape ()
  "Toggle whether C backslash escapes are shown in the ASCII table."
  (interactive)
  (setq ascii-table-escape (not ascii-table-escape))
  (ascii-table--revert-if-active))

(defun ascii-table-base-binary ()
  "Switch ASCII table to binary (base 2)."
  (interactive)
  (ascii-table--set-base 2))

(defun ascii-table-base-octal ()
  "Switch ASCII table to octal (base 8)."
  (interactive)
  (ascii-table--set-base 8))

(defun ascii-table-base-decimal ()
  "Switch ASCII table to decimal (base 10)."
  (interactive)
  (ascii-table--set-base 10))

(defun ascii-table-base-hex ()
  "Switch ASCII table to hexadecimal (base 16)."
  (interactive)
  (ascii-table--set-base 16))

(defvar ascii-table-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map special-mode-map)
    (define-key map (kbd "b") 'ascii-table-base-binary)
    (define-key map (kbd "e") 'ascii-table-toggle-escape)
    (define-key map (kbd "d") 'ascii-table-base-decimal)
    (define-key map (kbd "o") 'ascii-table-base-octal)
    (define-key map (kbd "x") 'ascii-table-base-hex)
    (define-key map (kbd "TAB") 'ascii-table-toggle-control)
    map)
  "Keymap for `ascii-table-mode'.")

(define-derived-mode ascii-table-mode special-mode "ASCII"
  "Major mode that shows an interactive ASCII table.

\\{ascii-table-mode-map}"
  (setq-local revert-buffer-function 'ascii-table--revert)
  (ascii-table--revert))

;;;###autoload
(defun ascii-table ()
  "Show an interactive ASCII table in the other window."
  (interactive)
  (switch-to-buffer-other-window (get-buffer-create "*ASCII*"))
  (ascii-table-mode))

(provide 'ascii-table)

;;; ascii-table.el ends here
