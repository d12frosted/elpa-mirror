;;; topsy.el --- Simple sticky header  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Adam Porter

;; Author: Adam Porter <adam@alphapapa.net>
;; URL: https://github.com/alphapapa/topsy.el
;; Package-Version: 20210831.133
;; Package-Commit: 8ae0976dfdbe4461c33ed44cf1dedc2c903b0bb0
;; Version: 0.1-pre
;; Package-Requires: ((emacs "26.3"))
;; Keywords: convenience

;;;; License:

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

;; This library shows a sticky header at the top of the window.  The
;; header shows which definition the top line of the window is within.
;; Intended as a simple alternative to `semantic-stickyfunc-mode`.

;; Mode-specific functions may be added to `topsy-mode-functions'.

;; NOTE: For Org mode buffers, please use org-sticky-header:
;; <https://github.com/alphapapa/org-sticky-header>.

;;; Code:

;;;; Requirements

(require 'subr-x)

;;;; Variables

(defconst topsy-header-line-format
  '(:eval (list (propertize " " 'display '((space :align-to 0)))
                (funcall topsy-fn)))
  "The header line format used by `topsy-mode'.")
(put 'topsy-header-line-format 'risky-local-variable t)

(defvar-local topsy-old-hlf nil
  "Preserves the old value of `header-line-format'.")

(defvar-local topsy-fn nil
  "Function that returns the header in a buffer.")

;;;; Customization

(defgroup topsy nil
  "Show a sticky header at the top of the window.
The header shows which definition the top line of the window is
within.  Intended as a simple alternative to
`semantic-stickyfunc-mode`."
  :group 'convenience)

(defcustom topsy-mode-functions
  '((emacs-lisp-mode . topsy--beginning-of-defun)
    (magit-section-mode . (lambda ()
                            (save-excursion
                              (goto-char (window-start))
                              (when-let (strings
					 (cl-loop while (/= (point) (progn
                                                                      (magit-section-up)
                                                                      (point)))
						  for section = (magit-current-section)
						  collect (string-trim
							   (buffer-substring
							    (oref section start)
							    (oref section content)))))
				(string-join strings " « ")))))
    (org-mode . (lambda ()
                  "topsy: Please use package `org-sticky-header' for Org mode"))
    (nil . topsy--beginning-of-defun))
  "Alist mapping major modes to functions.
Each function provides the sticky header string in a mode.  The
nil key defines the default function."
  :type '(alist :key-type symbol
                :value-type function))

;;;; Commands

;;;###autoload
(define-minor-mode topsy-mode
  "Minor mode to show a simple sticky header.
With prefix argument ARG, turn on if positive, otherwise off.
Return non-nil if the minor mode is enabled."
  :group 'topsy
  (if topsy-mode
      (progn
        (when (and (local-variable-p 'header-line-format (current-buffer))
                   (not (eq header-line-format topsy-header-line-format)))
          ;; Save previous buffer local value of header line format.
          (setf topsy-old-hlf header-line-format))
        ;; Enable the mode
        (setf topsy-fn (or (alist-get major-mode topsy-mode-functions)
                           (alist-get nil topsy-mode-functions))
              header-line-format 'topsy-header-line-format))
    ;; Disable mode
    (when (eq header-line-format 'topsy-header-line-format)
      ;; Restore previous buffer local value of header line format if
      ;; the current one is the sticky func one.
      (kill-local-variable 'header-line-format)
      (when topsy-old-hlf
        (setf header-line-format topsy-old-hlf
              topsy-old-hlf nil)))))

;;;; Functions

(defun topsy--beginning-of-defun ()
  "Return the line moved to by `beginning-of-defun'."
  (when (> (window-start) 1)
    (save-excursion
      (goto-char (window-start))
      (beginning-of-defun)
      (font-lock-ensure (point) (point-at-eol))
      (buffer-substring (point) (point-at-eol)))))

;;;; Footer

(provide 'topsy)

;;; topsy.el ends here
