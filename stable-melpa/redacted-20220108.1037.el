;;; redacted.el --- Obscure text in buffer           -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Benjamin Kästner

;; Author:  Benjamin Kästner <benjamin.kaestner@gmail.com>
;; URL: https://github.com/bkaestner/redacted.el
;; Package-Version: 20220108.1037
;; Package-Commit: c4ea6cbffda9c67af112f25b2db2843aa4abce85
;; Keywords: games
;; Version: 0.1.1
;; Package-Requires: ((emacs "25.1"))

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

;; This package provides `redacted-mode', a buffer-local mode that uses
;; `buffer-display-table' to replace the displayed glyphs with Unicode
;; blocks.

;;; Code:

(eval-and-compile
  (defconst redacted-mode--max-letter-char-code
    (eval-when-compile
      (let ((max-code-point #x10FFFF)    ; Max Unicode code point
            (letter-categories '(Lu Ll)) ; Upper and Lower case letters
            result)
        (dotimes (i (1+ max-code-point))
          (when (memq (get-char-code-property i 'general-category)
                      letter-categories)
            (setq result i)))
        result))
    "Maximum Unicode code point that designates a letter.")

  (defun redacted-mode--compute-table ()
    "Compute the display table for `redacted-mode'."
    (let ((disptbl (make-display-table)))
      (dotimes (i (1+ redacted-mode--max-letter-char-code))
        (aset disptbl i
              (pcase (get-char-code-property i 'general-category)
                ((or 'Cc 'Cf 'Zs 'Zl 'Zp) nil)
                ('Ll (vector (make-glyph-code ?▃)))
                (_   (vector (make-glyph-code ?▆))))))
      disptbl)))

(defconst redacted-mode-table (eval-when-compile (redacted-mode--compute-table))
  "Display table for the command `redacted-mode'.")

;;;###autoload
(define-minor-mode redacted-mode
  "Obscure text."
  :lighter " Redacted"
  (if redacted-mode
      (setq buffer-display-table redacted-mode-table)
    (setq buffer-display-table nil)))

(provide 'redacted)
;;; redacted.el ends here
