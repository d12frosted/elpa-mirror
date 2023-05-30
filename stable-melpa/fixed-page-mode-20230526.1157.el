;;; fixed-page-mode.el --- A fixed page length mode  -*- lexical-binding:t -*-

;; Copyright (C) 2022-2023 Igor Wojnicki

;; Author: Igor Wojnicki <wojnicki@gmail.com>
;; URL: https://gitlab.com/igorwojnicki/fixed-page-mode
;; Package-Version: 20230526.1157
;; Package-Commit: f7f7925b59851419561be0784270b5d085359373
;; Version: 1.0
;; Package-Requires: ((emacs "24.3"))
;; Keywords: wp

;; SPDX-License-Identifier: GPL-3.0-or-later

;; Fixed Page mode is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Fixed Page mode is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public
;; License. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A page-based text editing/note taking/concept thinking Emacs minor
;; mode.  Presents buffer's content as pages of predefined number of
;; lines (50 by default).  It is an analog of pages in a notebook.  It
;; can be used with org mode or any other text mode.

;;; Code:

(defgroup fixed-page nil
  "A fixed page length mode and page-by-page navigation."
  :package-version '(fixed-page . "1.0")
  :group 'editing
  :prefix "fixed-page")

(defcustom fixed-page-length 50
  "Page length, in lines."
  :type 'integer)

(make-variable-buffer-local 'fixed-page-length)

(defvar-local fixed-page-number-mode-line " FP"
   "Modeline page number indicator.")

(defvar org-element-use-cache)

(defun fixed-page-number ()
  "Return a page number, counting from 0."
  (/ (1- (line-number-at-pos)) fixed-page-length))

(defun fixed-page-count-lines ()
  "Count lines on the current page."
  (if (buffer-narrowed-p) ;; ugly hack, if there is no narrowing report fixed-page-length
      (count-lines (point-min) (point-max))
    fixed-page-length))

(defun fixed-page-move (&optional n)
  "Move N pages.  Move backward with negative N.
Page length is defined by `fixed-page-length' variable."
  (interactive "p")
  (widen)
  (forward-line (* n fixed-page-length))
  (fixed-page-narrow))

(defalias 'fixed-page-next #'fixed-page-move)

(defun fixed-page-prev (&optional n)
  "Move N pages backward.  Move forward with negative N.
Page length is defined by `fixed-page-length' variable."
  (interactive "p")
  (fixed-page-move (* -1 n)))

(defmacro fixed-page-with-wide-buffer (body)
  "Execute BODY with buffer widened, then `fixed-page-narrow'."
  `(progn
     (widen)
     ,@body
     (fixed-page-narrow)))

(defun fixed-page-isearch-forward ()
  "Isearch forward the buffer."
  (interactive)
  (fixed-page-with-wide-buffer
   ((isearch-forward))))

(defun fixed-page-isearch-backward ()
  "Isearch the buffer backward."
  (interactive)
  (fixed-page-with-wide-buffer
   ((isearch-backward))))

(defun fixed-page-goto-page (page-number)
  "Jump to the given PAGE-NUMBER."
  (interactive "nGo to page number:")
  (fixed-page-with-wide-buffer
   ((goto-char 1)
    (forward-line (* page-number fixed-page-length)))))

(defun fixed-page--length-compensate ()
  "Check if current page is of `fixed-page-length'.
If not add newlines at the end."
  (let ((lines-to-add (- fixed-page-length (fixed-page-count-lines))))
    (when lines-to-add
      (save-excursion
	(goto-char (point-max))
	(newline lines-to-add)
	lines-to-add))))

(defun fixed-page-mode-empty-lines-at-end ()
  "Count empty lines at the end of buffer."
  (save-excursion
    (goto-char (point-max))
    (skip-chars-backward "\n[:space:]")
    (count-lines (point) (point-max))))

(defun fixed-page-narrow ()
    "Narrow to current page based on `fixed-page-length' variable."
    (save-excursion
      (let ((fixed-page-number-value (fixed-page-number)))
      ;; Go to a begining of current page.
	(goto-char (point-min))
	(forward-line (* fixed-page-number-value fixed-page-length))
	(setq fixed-page-number-mode-line (format " FP(%d)" fixed-page-number-value)))
      ;; Narrow
      (narrow-to-region (point)
			(progn
			  (forward-line fixed-page-length)
			  (point))))
    (goto-char (point-min)))

(defun fixed-page-mode-remove-lines-from-end (lines)
  "Remove number of LINES from the end of buffer."
  (save-excursion
    (goto-char (point-max))
    (forward-line (- lines))
    (delete-region (point) (point-max))))

(defun fixed-page--mode-prevent-too-long-page (beg end _len)
  "A hook for `after-change-functions' to control page length.
BEG, END and _LEN are begining, end and length of the change."
  (when (not undo-in-progress)
    (let* ((lines (fixed-page-count-lines))
	   ;; number of lines that are not empty at the end
	   (stuff-lines (- lines (1- (fixed-page-mode-empty-lines-at-end)))))
      (if (<= lines fixed-page-length)
	  (fixed-page--length-compensate)
	(if (<= stuff-lines fixed-page-length)
	    (fixed-page-mode-remove-lines-from-end (- lines fixed-page-length))
	  (kill-region beg end))))))

;;;###autoload
(define-minor-mode fixed-page-mode
  "A page-based text editing/note taking/concept thinking.
Edit text page by page."
  :lighter fixed-page-number-mode-line
  :group 'fixed-page
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "<next>") 'fixed-page-next)
            (define-key map (kbd "<prior>") 'fixed-page-prev)
            (define-key map (kbd "C-s") 'fixed-page-isearch-forward)
            (define-key map (kbd "C-r") 'fixed-page-isearch-backward)
            map)
  (if fixed-page-mode
      (progn
	(when (derived-mode-p 'org-mode)
	  (setq org-element-use-cache nil)) ;; WORKAROUND with org mode cache, otherwise org mode reports warnings
	(add-hook 'after-change-functions #'fixed-page--mode-prevent-too-long-page 0 1)
	(fixed-page-narrow))
    (remove-hook 'after-change-functions #'fixed-page--mode-prevent-too-long-page 1)
    (widen)))

(provide 'fixed-page-mode)

;;; fixed-page-mode.el ends here
