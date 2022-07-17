;;; readable-numbers.el --- Visually separate long integers -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Óscar Nájera
;;
;; Author: Oscar Najera <https://oscarnajera.com>
;; Maintainer: Oscar Najera <hi@oscarnajera.com>
;; Version: 0.1.0
;; Package-Version: 20220711.911
;; Package-Commit: a3ebdcdd91d32f044b68541a00e162396e4acb38
;; Homepage: https://github.com/Titan-C/cardano.el
;; Package-Requires: ((emacs "24.1"))
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
;;  Overlay to make large numbers in buffer readable

;;; Code:

(defgroup readable-numbers nil
  "Make unreadable big integers readable."
  :group 'tools)

(defcustom readable-numbers-separator "_"
  "Character to separate integers."
  :type 'string)

(defcustom readable-numbers-separator-interval 3
  "Group this many numbers."
  :type 'integer)

(defcustom readable-numbers-separator-ignore-threshold 4
  "Ignore numbers with this many digits.
This prevents separating four digit years."
  :type 'integer)

(defun readable-numbers-set-overlay-properties ()
  "Set properties of readable-numbers overlays.
Consider current setting of user variables."
  ;; In-identifier overlay
  (put 'readable-numbers 'evaporate t)
  (put 'readable-numbers 'before-string readable-numbers-separator))

(readable-numbers-set-overlay-properties)

(defun readable-numbers-overlay-p (overlay)
  "Return whether OVERLAY is an overlay of glasses mode."
  (eq (overlay-get overlay 'category) 'readable-numbers))

(defun readable-numbers-make-overlay (beg end)
  "Create and return readability overlay over the region from BEG to END."
  (let ((overlay (make-overlay beg end)))
    (overlay-put overlay 'category 'readable-numbers)
    overlay))

(defun readable-numbers-make-unreadable (beg end)
  "Return identifiers in the region from BEG to END to their unreadable state."
  (dolist (o (overlays-in beg end))
    (when (readable-numbers-overlay-p o)
      (delete-overlay o))))

(defun readable-numbers-make-readable (beg end)
  "Make the identifiers in the region from BEG to END readable."
  (save-excursion
    (save-match-data
      (goto-char beg)
      (while (re-search-forward (rx word-boundary
                                    (group  (1+ digit)
                                            word-boundary)) end t)
        (when (> (length (match-string 1)) readable-numbers-separator-ignore-threshold)
          (dolist (ins (number-sequence
                        (- (match-end 1) readable-numbers-separator-interval)
                        (1+ (match-beginning 1))
                        (- readable-numbers-separator-interval)))
            (readable-numbers-make-overlay ins (1+ ins))))))))

(defun readable-numbers-change (beg end)
  "After-change function updating readable-numbers overlays between BEG to END."
  (readable-numbers-make-unreadable beg end)
  (readable-numbers-make-readable beg end))

(define-minor-mode readable-numbers-mode
  "Separate long readable-numbers."
  :lighter " numsep"
  (if readable-numbers-mode
      (jit-lock-register #'readable-numbers-change)
    (jit-lock-unregister #'readable-numbers-change)))

(provide 'readable-numbers)
;;; readable-numbers.el ends here
