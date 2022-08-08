;;; ebnf-mode.el --- Major mode for EBNF files -*- lexical-binding: t; -*-

;; This is free and unencumbered software released into the public domain.

;; Author: Noah Peart <noah.v.peart@gmail.com>
;; URL: https://github.com/nverno/ebnf-mode
;; Package-Version: 20220606.1846
;; Package-Commit: 89df6ca4215b3a325dc94a8f246f403cacc99745
;; Version: 1.0.0
;; Package-Requires: ((emacs "25.1"))
;; Created: 29 December 2021

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;;  Basic indentation and font-locking support for EBNF language files.
;;  http://en.wikipedia.org/wiki/Extended_Backus-Naur_Form
;;
;;  Refer to ebnf2ps.el for language description/variables to customize
;;  syntax.
;;
;;  This mode uses '.' as rule ender and ';' as comment starter.
;;  (TODO: support different rule endings [.|;] and comment starters?)
;;
;;; Code:
(eval-when-compile
  (require 'cl-lib)
  (require 'subr-x))

(defgroup ebnf nil
  "Major mode for EBNF files."
  :group 'languages
  :group 'ebnf)

(defcustom ebnf-mode-indent-by-production t
  "If non-nil, indent each production continuation with its initial '='."
  :type 'boolean
  :group 'ebnf)

(defcustom ebnf-mode-indent-offset 8
  "Default number of spaces to indent production continuations."
  :type 'integer
  :group 'ebnf)

(defcustom ebnf-mode-comment-char ?\;
  "Line comment character."
  :type 'character
  :group 'ebnf)

(defcustom ebnf-mode-eop-char ?.
  "End of production character."
  :type 'character
  :group 'ebnf)

(defvar ebnf-mode-production-re "^\\s-*\\([[:alnum:]_]+\\)\\s-*=")

(defvar ebnf-mode-font-lock-keywords
  `((,ebnf-mode-production-re (1 font-lock-variable-name-face))
    (,(regexp-quote (char-to-string ebnf-mode-eop-char)) . font-lock-warning-face)))

(defvar ebnf-mode-syntax-table
  (let ((syn (make-syntax-table)))
    (modify-syntax-entry ebnf-mode-comment-char "<" syn)
    (modify-syntax-entry ?\n ">" syn)
    syn))

(defun ebnf-mode--end-of-line ()
  "Move point to end of line."
  (end-of-line)
  (let ((syntax (syntax-ppss)))
    (and (nth 8 syntax)
         (goto-char (nth 8 syntax)))
    (skip-syntax-backward " " (line-beginning-position))))

(defun ebnf-mode--production-line-p ()
  "Non-nil if line is a production."
  (save-excursion
    (beginning-of-line)
    (looking-at-p ebnf-mode-production-re)))

(defun ebnf-mode-beginning-of-production ()
  "Move point to beginning of last production."
  (while (not (or (bobp) (looking-at-p ebnf-mode-production-re)))
    (beginning-of-line 0))
  (point))

(defun ebnf-mode-end-of-production ()
  "Move point to end of current production, but before any trailing comments."
  (while (not (or (eobp)
                  (progn
                    (ebnf-mode--end-of-line)
                    (eq (char-before) ebnf-mode-eop-char))))
    (beginning-of-line 2))
  (point))

(defun ebnf-mode--production-bounds ()
  "Bounds of current production."
  (save-excursion
    (let* ((cur (point))
           (beg (progn
                  (ebnf-mode-beginning-of-production)
                  (and (looking-at-p ebnf-mode-production-re) (point))))
           (end (when beg
                  (ebnf-mode-end-of-production)
                  (and (eq (char-before) ebnf-mode-eop-char) (point)))))
      (when (and beg end (<= beg cur) (>= end cur))
        (cons beg end)))))

(put 'ebnf-production 'bounds-of-thing-at-point 'ebnf-mode--production-bounds)

(defun ebnf-mode--production-indent (beg)
  "Indent level for production at BEG."
  (if ebnf-mode-indent-by-production
      (save-excursion
        (goto-char beg)
        (if (search-forward "=" (line-end-position) t)
            (1- (current-column))
          ebnf-mode-indent-offset))
    ebnf-mode-indent-offset))

(defun ebnf-mode-indent-line ()
  "Indent a line for EBNF mode.
Indent production continuation lines to `ebnf-mode-indent-offset'."
  (when-let ((bnds (bounds-of-thing-at-point 'ebnf-production)))
    (cl-destructuring-bind (beg . end) bnds
      (when (< beg (line-beginning-position))
        (let ((amnt (ebnf-mode--production-indent beg)))
          (save-excursion
            (back-to-indentation)
            (delete-horizontal-space)
            (indent-to amnt)))))))

;;;###autoload
(define-derived-mode ebnf-mode prog-mode "EBNF"
  "Major mode for editing EBNF files.

\\{ebnf-mode-map}"
  (setf font-lock-defaults '(ebnf-mode-font-lock-keywords nil nil nil nil))
  (setq-local comment-start ";")
  (setq-local comment-end "")
  (setq-local indent-line-function #'ebnf-mode-indent-line))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ebnf\\'" . ebnf-mode))

(provide 'ebnf-mode)
;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:
;;; ebnf-mode.el ends here
