;;; aa-edit-mode.el --- Major mode for editing AA(S_JIS Art) and .mlt file -*- lexical-binding: t -*-

;; Copyright (C) 2016 USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 28 Feb 2016
;; Version: 0.0.2
;; Package-Version: 20170119.320
;; Package-Commit: 1dd801225b7ad3c23ad09698f5e77f0df7012a65
;; Keywords: wp text shiftjis mlt yaruo
;; Package-Requires: ((emacs "24.3") (navi2ch "2.0.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; （´д｀）
;;
;; aa-edit-mode is Major mode for AA (アスキーアート, known as Shift_JIS art).
;;
;; https://en.wikipedia.org/wiki/Shift_JIS_art
;; https://ja.wikipedia.org/wiki/%E3%82%A2%E3%82%B9%E3%82%AD%E3%83%BC%E3%82%A2%E3%83%BC%E3%83%88
;;
;; `aa-edit-mode' supports .mlt format.
;; http://yaruo.wikia.com/wiki/%E3%82%84%E3%82%8B%E5%A4%AB%E3%82%B9%E3%83%AC%E7%94%A8MLT%E5%8F%8E%E9%9B%86%E6%89%80


;;; Code:

(when (require 'navi2ch nil t)
  (require 'navi2ch-mona))

(defgroup aa-edit '()
  "Major mode for editing AA(Shift_JIS Art) and .mlt file"
  :group 'text)

(defconst aa-edit-mlt-delimiter-regexp
  (eval-when-compile
    (rx bol "[SPLIT]")))

(defcustom aa-edit-delimiter-pattern aa-edit-mlt-delimiter-regexp
  "A delimiter (separator) regexp pattern of ASCII Art that based on `PAGE-DELIMITER'."
  :type 'regexp)

(defun aa-edit-mode--face ()
  "Return face for display AA."
  (if (boundp 'navi2ch-mona-face-variable)
      (if (eq navi2ch-mona-face-variable t)
          'navi2ch-mona16-face
        navi2ch-mona-face-variable)
    ""))

;;;###autoload
(define-derived-mode aa-edit-mode text-mode "（´д｀）"
  "Major mode for editing AA"
  (when (fboundp 'navi2ch-mona-setup)
    (navi2ch-mona-setup))
  (setq-local page-delimiter aa-edit-delimiter-pattern)
  (buffer-face-set (aa-edit-mode--face)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.mlt\\'" . aa-edit-mode))

(provide 'aa-edit-mode)
;;; aa-edit-mode.el ends here
