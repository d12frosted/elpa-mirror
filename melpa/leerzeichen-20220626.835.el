;;; leerzeichen.el --- Minor mode to display whitespace characters.

;; Copyright (c) 2014-2015 Felix Geller

;; Author: Felix Geller <fgeller@gmail.com>
;; Keywords: whitespace characters
;; Package-Version: 20220626.835
;; Package-Commit: 9d4126d5f6563569080845a69b0867119a9fd6ea
;; URL: http://github.com/fgeller/leerzeichen.el

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; leerzeichen is a minor mode to display whitespace characters. That's all it
;; does, and it imposes little overhead by using a buffer local display table
;; rather than the font-lock functionality.

;; More information: https://github.com/fgeller/leerzeichen.el/

;;; Code:

(defgroup leerzeichen nil
  "Faces for highlighting whitespace characters."
  :group 'leerzeichen)

(defface leerzeichen '((t (:foreground "#b8b8b8")))
  "Face for `leerzeichen-mode'."
  :group 'leerzeichen)

(defvar leerzeichen-saved-buffer-display-table nil
  "Stored version of `buffer-display-table' before leerzeichen-mode was enabled.")

(defvar leerzeichen-line-feed-glyph (make-glyph-code ?$ 'leerzeichen))
(defvar leerzeichen-tab-glyph (make-glyph-code ?» 'leerzeichen))
(defvar leerzeichen-space-glyph (make-glyph-code ?· 'leerzeichen))

(defun leerzeichen-display-table ()
  "Display table to highlight whitespace characters."
  (let ((table (make-display-table)))
    (aset table ?\n `[,leerzeichen-line-feed-glyph ?\n])
    (aset table ?\t (vconcat `[,leerzeichen-tab-glyph] (make-vector (1- tab-width) ? )))
    (aset table ?\  `[,leerzeichen-space-glyph])
    table))

;;;###autoload
(define-minor-mode leerzeichen-mode
  "Minor mode to highlight whitespace characters by displaying them differently."
  :lighter "lz "
  :keymap nil
  (if leerzeichen-mode
      (leerzeichen-enable)
    (leerzeichen-disable)))

(defun leerzeichen-enable ()
  "Installs leerzeichen's display table as (buffer local) `buffer-display-table'."
  (setq leerzeichen-saved-buffer-display-table buffer-display-table)
  (setq buffer-display-table (leerzeichen-display-table)))

(defun leerzeichen-disable ()
  "Resets `buffer-display-table' to state before leerzeichen was enabled."
  (setq buffer-display-table leerzeichen-saved-buffer-display-table))

(provide 'leerzeichen)

;;; leerzeichen.el ends here
