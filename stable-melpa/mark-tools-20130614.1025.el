;;; mark-tools.el --- Some simple tools to access the mark-ring in Emacs

;; Copyright (C) 2012, Alex Bennée

;; Author: Alex Bennée <alex@bennee.com>
;; Maintainer: Alex Bennée <alex@bennee.com>
;; Version: 0.3
;; Package-Version: 20130614.1025
;; Package-Commit: a11b61effa90bd0abc876d12573674d36fc17f0c
;; URL: https://github.com/stsquad/emacs-mark-tools

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy  of the GNU General Public License see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Emacs maintains a set of mark-rings (global and per-buffer) which
;; can be used as a simple "where have I been" log. This library
;; provides a function call list-marks which shows the list of marks
;; and allows a quick navigation to where you were.

;;; Further reading:

;; I've taken some hints from:
;; http://www.masteringemacs.org/articles/2010/12/22/fixing-mark-commands-transient-mark-mode/

;;; Code:

;; un-comment to debug
;(setq debug-on-error t)
;(setq edebug-all-defs t)

;; I use it for the loop macros
(eval-when-compile (require 'cl))

;;
;; Variables
;;

(defvar mark-list-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map (kbd "RET") 'mark-list-visit-buffer)
    (define-key map "\C-m" 'mark-list-visit-buffer)
    (define-key map (kbd "d") 'mark-list-delete-mark)
    map)
  "Local keymap for `mark-list-mode-mode' buffers.")

(defvar mark-list-current-mark-list nil
  "A reference to the current mark list.
This variable is automatically made buffer local for the
mark-list buffer it is in")
(make-variable-buffer-local 'mark-list-current-mark-list)
(put 'mark-list-current-mark-list 'permanent-local t)

;;;
;;; Mark List mode code
;;;

(defun marker-listp (marks)
  "Return 't if MARKS is a list of markers"
  (if (and (listp marks) (> 0 (length marks)))
      (not (find-if-not 'markerp marks))
    'nil))

;;;###autoload
(define-derived-mode mark-list-mode tabulated-list-mode "Mark List"
  "Major mode for listing the historical Mark List.
The Buffer Menu is invoked by the commands \\[list-marks].

Letters do not insert themselves; instead, they are commands.
\\<mark-list-mode-map>
\\{mark-list-mode-map}"
  (setq tabulated-list-format [("Buffer" 30 t)
	                       ("Line" 6 nil)
			       ("Function/Text" 30 t)])
  (setq tabulated-list-use-header-line 't)
  (setq tabulated-list-sort-key (cons "Buffer" nil))
  (add-hook 'tabulated-list-revert-hook 'mark-list--refresh nil t)
  (tabulated-list-init-header))

(defun mark-list--make-buffer (mark-list-or-prefix)
  "Return a buffer named \"*Mark List*\".

If MARK-LIST-OR-PREFIX is a list of marks then it uses that list.
Otherwise if it is non-nil it uses the current buffer mark-ring.
Finally if it is nil the buffer is constructed with the
global-mark-ring."
  (let ((buffer-ring mark-ring)
	(buffer (get-buffer-create "*Mark List*")))
    (with-current-buffer buffer
      (setq mark-list-current-mark-list
	    (cond
	     ((marker-listp mark-list-or-prefix) mark-list-or-prefix)
	     ((and
	       mark-list-or-prefix
	       (eq mark-list-or-prefix current-prefix-arg))
	      buffer-ring)
	     ((eq mark-list-or-prefix 'nil) global-mark-ring)))
      (mark-list-mode)
      (mark-list--refresh mark-list-current-mark-list))
    buffer))

;;;###autoload
(defun list-marks (&optional arg)
  "Display the mark ring.
The list is displayed in a buffer named \"*Mark List*\".

By default it displays the global-mark-ring.
With prefix argument ARG, show local buffer mark-ring."
  (interactive "P")
  (switch-to-buffer (mark-list--make-buffer arg)))

;;;###autoload
(defun list-marks-other-window (&optional arg)
  "Display the mark ring in a different window.
The list is displayed in a buffer named \"*Mark List*\".

By default it displays the global-mark-ring.
With prefix argument ARG, show local buffer mark-ring."
  (interactive "P")
  (switch-to-buffer-other-window (mark-list--make-buffer arg)))


;; It might be useful to combine the following two functions but handling
;; multiple return values doesn't seem very LISPy

(defun mark-list--find-defun (buffer position)
  "For a given BUFFER and POSITION find the nearest defun"
  (save-excursion
    (set-buffer buffer)
    (goto-char position)
    (or (ignore-errors (which-function))
	(buffer-substring (point) (line-end-position)))))

(defun mark-list--find-line (buffer position)
  "For a given BUFFER and POSITION return the line number"
  (with-current-buffer buffer
    (line-number-at-pos position)))

(defun mark-list--refresh (&optional marks)
  (let (entries)
    (dolist (mark marks)
      (when (and (markerp mark)
		 (marker-position mark))
;	(message "processing mark: %s" mark)
	(let* ((buffer (marker-buffer mark))
	       (bufname (buffer-name buffer))
	       (bufpos (marker-position mark))
	       (bufline (mark-list--find-line buffer bufpos))
	       (func (mark-list--find-defun buffer bufpos))
	       (bufstr (format "%d" bufline)))
	  (push (list mark (vector bufname bufstr func)) entries))))
    (setq tabulated-list-entries (nreverse entries)))
  (tabulated-list-init-header)
  (tabulated-list-print))

;;;
;;; Actions you can call from the buffer
;;;

;;;####autoload
(defun mark-list-visit-buffer ()
  "Visit the mark in the mark-list buffer"
  (interactive)
  (let* ((mark (tabulated-list-get-id))
	 (entry (and mark (assq mark tabulated-list-entries)))
	 (buffer (marker-buffer mark))
	 (position (marker-position mark)))
    (set-buffer buffer)
    (or (and (>= position (point-min))
	     (<= position (point-max)))
	(if widen-automatically
	    (widen)
	  (error "Global mark position is outside accessible part of buffer")))
    (goto-char position)
    (switch-to-buffer buffer)))

(defun mark-list-delete-mark ()
  "Remove all instances of MARK from the mark list and refresh the buffer."
  (interactive)
  (let ((mark (tabulated-list-get-id)))
    (delq mark mark-list-current-mark-list)
    (mark-list--refresh mark-list-current-mark-list)))

(provide 'mark-tools)
;;; mark-tools.el ends here
