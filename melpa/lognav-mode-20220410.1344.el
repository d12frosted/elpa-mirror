;;; lognav-mode.el --- Navigate Log Error Messages -*- lexical-binding:t -*-

;; Copyright (C) 2017 - 2022

;; Author: Shawn Ellis <shawn.ellis17@gmail.com>
;; Version: 0.0.9
;; Package-Version: 20220410.1344
;; Package-Commit: 100541ec31468b771073a7d2ad4512c1dcb1eb07
;; Package-Requires: ((emacs "24.3"))
;; URL: https://hg.osdn.net/view/lognav-mode/lognav-mode
;; Keywords: log error lognav-mode convenience
;;

;; lognav-mode.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; lognav-mode.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Lognav-mode is a minor mode used for finding and navigating errors within a
;; buffer or a log file.  The keybinding M-n moves the cursor to the first error
;; within the log file.  M-p moves the cursor to the previous error.
;;
;; Lognav-mode only highlights the errors that are visible on the screen rather
;; than highlighting all errors found within the buffer.  This is especially
;; useful when opening up large log files for analysis.

;; Add the following line in your .emacs file to use Lognav-mode:
;;
;; (require 'lognav-mode)
;;
;;
;; The following bindings are created for Lognav-mode:
;; M-n   - Next log error            Moves the cursor to the next error
;; M-p   - Previous log error        Moves the cursor to the previous error
;;

(require 'easymenu)
(require 'cl-lib)

;;; Code:

(defgroup lognav-mode nil
  "Navigate to errors within a buffer or a log file."
  :group 'convenience)


(defcustom lognav-regexp "\\(FATAL\\)\\|\\(ERROR\\)\\|\\(WARN\\)\\|\\(SEVERE\\)\\|\\(Caused by:\\)\\|\\(nested exception is:\\)"
  "Regular expression used for navigating errors."
  :type 'regexp)


;;;###autoload
(add-to-list 'auto-mode-alist '("\\.log\\(\\.[0-9]+\\)?\\'" . lognav-mode))

(defvar lognav-mode-map nil)

(defface lognav-highlight-face
  '((t (:inherit error :underline nil)))
    "Face for highlighting the line that has an error message."
  :group 'lognav-mode)

(unless lognav-mode-map
  (setq lognav-mode-map (make-sparse-keymap "Lognav mode"))
  (define-key lognav-mode-map "\M-p" 'lognav-previous-error)
  (define-key lognav-mode-map "\M-n" 'lognav-next-error))

(easy-menu-define lognav-menu lognav-mode-map
  "'lognav-mode' menu"
  '("Lognav"
    ["Next Error" lognav-next-error t]
    ["Previous Error" lognav-previous-error t]
    ["Error Occur" lognav-error-occur t]
    ))

(defvar-local lognav-mode-idle-registered nil
  "Returns t if an idle timer has already been registered.")

;;;###autoload
(defun lognav-previous-error()
  "Moves the point to the previous error."
  (interactive)
  (move-beginning-of-line 1)
  (when (search-backward-regexp lognav-regexp nil t)
      (move-beginning-of-line nil)
      (lognav-highlight-visible)))

;;;###autoload
(defun lognav-next-error()
  "Moves the point forward to the next error."
  (interactive)
  (let ((current (point)))
    (move-end-of-line 1)
    (if (search-forward-regexp lognav-regexp nil t)
	(progn
	  (move-beginning-of-line 1)
	  (lognav-highlight-visible))
      (goto-char current))))


(defun lognav-highlight-region (begin end)
  "Highlight the region specified by BEGIN and END."
  (let  ((lognav-overlay (make-overlay begin end)))
    (overlay-put lognav-overlay 'lognav-overlay t)
    (overlay-put lognav-overlay 'face 'lognav-highlight-face)
    lognav-overlay))

(defun lognav-highlight-error (begin end)
  "Highlight any error within the region specified by BEGIN and END."
  (let ((current (point)))
    (goto-char begin)
    (while (search-forward-regexp lognav-regexp end t)
      (if (not (lognav-overlay-p (line-beginning-position)))
	  (lognav-highlight-region (line-beginning-position)
				   (line-end-position))))
    (goto-char current)))

(defun lognav-highlight-position (line)
  "Return the position based upon the LINE number."
  (save-excursion
    (forward-line line)
    (point)))

(defun lognav-overlay-p (pos)
  "Return the log overlay if it exists or nil based upon POS."
  (car (cl-remove-if-not (lambda (x) (overlay-get x 'lognav-overlay))
			 (overlays-at pos))))

(defun lognav-highlight-visible ()
  "Highlight the errors that are visible on the screen."
  (when (not buffer-read-only)
    (let* ((height (frame-height))
	   (start (lognav-highlight-position (* -1 height)))
	   (end (lognav-highlight-position height)))

      (lognav-highlight-error start end))))

;;;###autoload
(defun lognav-error-occur ()
  "Create an Occur buffer with the matching errors."
  (interactive)
  (occur lognav-regexp))

(defun lognav-mode-after-change (_begin _end _ignored)
  "Highlight the visible errors when a buffer is idle for 3 seconds."

  (when (not lognav-mode-idle-registered)
    (let ((buf (current-buffer)))
      (run-with-idle-timer 3 nil (lambda ()
				   (if (buffer-live-p buf)
				       (with-current-buffer buf
					 (lognav-highlight-visible)
					 (setq lognav-mode-idle-registered nil))))))
    (setq lognav-mode-idle-registered t)))

(defun lognav-mode-init ()
  "Highlight visible errors."
  (lognav-highlight-visible)

  (when buffer-file-name
    (add-hook 'after-change-functions 'lognav-mode-after-change t t)))

(defun lognav-mode-deinit ()
  "Disable 'lognav-mode'."
  (remove-overlays (point-min) (point-max) 'lognav-overlay t)
  (remove-hook 'after-change-functions 'lognav-mode-after-change t))


;;;###autoload
(define-minor-mode lognav-mode
  "Lognav-mode is a minor mode for finding and navigating errors
  within log files."
  :lighter " Lognav"
  :keymap lognav-mode-map
  (if lognav-mode
      (lognav-mode-init)
    (lognav-mode-deinit)))

(provide 'lognav-mode)

;;; lognav-mode.el ends here
