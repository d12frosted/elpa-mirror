;;; rigid-tabs.el --- Fix TAB alignment in diff buffers  -*- lexical-binding: t -*-

;; Author: Yuri D'Elia <wavexx@thregr.org>
;; Version: 1.0
;; Package-Version: 20170903.1559
;; Package-Commit: eba84ceaba2e57e76ad2dfbb7a7154238a25d956
;; URL: https://github.com/wavexx/rigid-tabs.el
;; Package-Requires: ((emacs "24.3"))
;; Keywords: diff, whitespace, version control, magit

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; `rigid-tabs-mode' fixes the visual alignment of TABs in diff buffers without
;; actually changing the content of the buffer.
;;
;; `rigid-tabs-mode' "rigidifies" all TABs in the current buffer, preserving
;; their initial width but making them non-flexible just like a block of
;; spaces. This allows TABs to be moved around without changing width.
;;
;; This becomes helpful when viewing diffs, which introduce one or more prefix
;; characters that alter the target column of the displayed TABs. The resulting
;; misalignment may make code indentation look suspicious and overall harder to
;; read, even though it's perfectly aligned when the patch is applied.
;;
;; The function `rigid-tabs-rigid-align' turns on `rigid-tabs-mode' and adjusts
;; the visual alignment of TABs to compensate for the requested amount of
;; prefix characters. The result is a diff that looks correctly indented, as if
;; applied on the source.
;;
;; For convenience, to fix alignment in the various diff/magit modes, use
;; `rigid-tabs-diff-align', which detects the amount of prefix for both unified
;; and context diffs automatically:
;;
;; (add-hook 'diff-mode-hook 'rigid-tabs-diff-align)
;; (add-hook 'magit-refresh-buffer-hook 'rigid-tabs-diff-align)

;;; Code:

(eval-when-compile
  (require 'diff-mode))

(defvar-local rigid-tabs-shift-chars 0)


;;;###autoload
(define-minor-mode rigid-tabs-mode
    "Rigidify all TABs in the current buffer, making them non-flexible just
like a block of spaces. Use `rigid-tabs-rigid-align' to also align TABs in diff
modes properly (turns on `rigid-tabs-mode' as a result)."
    :init-value nil
    :lighter " RTab"
    (cond
      (rigid-tabs-mode
       (rigid-tabs-rigid-align)
       (rigid-tabs--turn-on))
      (t
       (remove-hook 'after-change-functions 'rigid-tabs--rigid-align-region t)
       (rigid-tabs--remove))))

;;;###autoload
(defun rigid-tabs-rigid-align (&optional shift-chars)
  "Rigidify TABs in the current buffer (make them non-flexible) and adjust
their visual alignment by 'shift-chars forward. Turns on `rigid-tabs-mode'."
  (when shift-chars
    (setq rigid-tabs-shift-chars shift-chars))
  (rigid-tabs--rigid-align-region (point-min) (point-max))
  (unless rigid-tabs-mode
    (rigid-tabs--turn-on)))

;;;###autoload
(defun rigid-tabs-diff-align ()
  "Turn on `rigid-tabs-mode' according to the current major mode and diff
format. Only `diff-mode' and various magit modes are supported. Use
`rigid-tabs-rigid-align' directly in other modes."
  (interactive)
  (cond
    ((eq major-mode 'diff-mode)
     ;; detect the diff format using `diff-hunk-style'
     (let ((style (save-excursion
		    (when (re-search-forward diff-hunk-header-re nil t)
		      (goto-char (match-beginning 0))
		      (diff-hunk-style)))))
       (rigid-tabs-rigid-align (if (eq style 'unified) 1 2))))
    ((member major-mode '(magit-diff-mode magit-revision-mode))
     (rigid-tabs-rigid-align 1))))


(defun rigid-tabs--turn-on ()
  (add-hook 'after-change-functions 'rigid-tabs--rigid-align-region nil t)
  (setq rigid-tabs-mode t))

(defun rigid-tabs--remove ()
  (dolist (ovr (overlays-in (point-min) (point-max)))
    (when (overlay-get ovr 'rigid-tab)
      (delete-overlay ovr))))

(defun rigid-tabs--rigid-align-region (beg end &optional length)
  (save-excursion
    (goto-char beg)
    (let (last-line last-point current-column)
      (while (search-forward "\t" end t)
	(goto-char (match-beginning 0))
	(let ((current-line (line-number-at-pos)))
	  (setq current-column
		(if (eq last-line current-line)
		    (+ (- (point) last-point) current-column)
		    (current-column)))
	  (let* ((column (- current-column rigid-tabs-shift-chars))
		 (target (+ (* (/ column tab-width) tab-width) tab-width))
		 (spaces (- target column)))
	    (goto-char (match-end 0))
	    (setq current-column (+ current-column spaces)
		  last-line current-line
		  last-point (point))
	    (rigid-tabs--rigidify (match-beginning 0) (point) spaces)))))))

(defun rigid-tabs--rigidify (beg end spaces)
  (let ((ovr (make-overlay beg end)))
    (overlay-put ovr 'rigid-tab t)
    (overlay-put ovr 'insert-in-front-hooks '(rigid-tabs--insert-in-front))
    (overlay-put ovr 'modifications-hooks '(rigid-tabs--modify))
    (overlay-put ovr 'display `(space . (:width ,spaces)))))

(defun rigid-tabs--insert-in-front (ovr after-change beg end &optional length)
  (when after-change
    (move-overlay ovr end (overlay-end ovr))))

(defun rigid-tabs--modify (ovr after-change beg end &optional length)
  (unless after-change
    (delete-overlay ovr)))


(provide 'rigid-tabs)

;;; rigid-tabs.el ends here
