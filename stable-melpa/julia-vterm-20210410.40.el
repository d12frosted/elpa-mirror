;;; julia-vterm.el --- A mode for Julia REPL using vterm -*- lexical-binding: t -*-

;; Copyright (C) 2020 Shigeaki Nishina

;; Author: Shigeaki Nishina
;; Maintainer: Shigeaki Nishina
;; Created: March 11, 2020
;; URL: https://github.com/shg/julia-vterm.el
;; Package-Version: 20210410.40
;; Package-Commit: d57448466c11833d4fd67f5dbbea9cb9a07a74e2
;; Package-Requires: ((emacs "25.1") (vterm "0.0.1"))
;; Version: 0.13
;; Keywords: languages, julia

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see https://www.gnu.org/licenses/.

;;; Commentary:

;; Provides a major-mode for inferior Julia process that runs in vterm, and a
;; minor-mode that extends julia-mode to support interaction with the inferior
;; Julia process.

;;; Usage:

;; You must have julia-mode and vterm installed.
;; Install julia-vterm.el manually using package.el
;;
;;   (package-install-file "/path-to-download-dir/julia-vterm.el")
;;
;; Eval the following line. Add this line to your init file to enable this
;; mode in future sessions.
;;
;;   (add-hook 'julia-mode-hook #'julia-vterm-mode)
;;
;; Now you can interact with an inferior Julia REPL from a Julia buffer.
;;
;; C-c C-z in a julia-mode buffer to open an inferior Julia REPL buffer.
;; C-c C-z in the REPL buffer to switch back to the script buffer.
;; C-<return> in the script buffer to send region or current line to REPL.
;;
;; See the code below for a few more key bidindings.

;;; Code:

(require 'vterm)


;;----------------------------------------------------------------------
(defgroup julia-vterm-repl nil
  "A major mode for inferior Julia REPL."
  :group 'julia)

(defvar julia-vterm-repl-program "julia")

(defvar-local julia-vterm-repl-script-buffer nil)

(defvar julia-vterm-repl-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-z") #'julia-vterm-repl-switch-to-script-buffer)
    (define-key map (kbd "M-k") #'julia-vterm-repl-clear-buffer)
    (define-key map (kbd "C-c C-t") #'julia-vterm-repl-copy-mode)
    (define-key map (kbd "C-l") #'recenter-top-bottom)
    map))

(define-derived-mode julia-vterm-repl-mode vterm-mode "Inf-Julia"
  "A major mode for inferior Julia REPL."
  :group 'julia-vterm-repl)

(defun julia-vterm-repl-buffer-name (&optional session-name)
  "Return a Julia REPL buffer name whose session name is SESSION-NAME."
  (format "*julia:%s*" (if session-name session-name "main")))

(defun julia-vterm-repl-session-name (repl-buffer)
  "Return the session name of REPL-BUFFER."
  (let ((bn (buffer-name repl-buffer)))
    (if (string= (substring bn 1 7) "julia:")
	(substring bn 7 -1)
      nil)))

(defun julia-vterm-repl-buffer-with-session-name (session-name &optional restart)
  "Return an inferior Julia REPL buffer of the session name SESSION-NAME.
If there exists no such buffer, one is created and returned.
With non-nil RESTART, the existing buffer will be killed and
recreated."
  (if-let ((buffer (get-buffer (julia-vterm-repl-buffer-name session-name)))
	   (alive (vterm-check-proc buffer))
	   (no-restart (not restart)))
      buffer
    (if (get-buffer-process buffer) (delete-process buffer))
    (if buffer (kill-buffer buffer))
    (let ((buffer (generate-new-buffer (julia-vterm-repl-buffer-name session-name)))
	  (vterm-shell julia-vterm-repl-program))
      (with-current-buffer buffer
	(julia-vterm-repl-mode))
      buffer)))

(defun julia-vterm-repl-buffer (&optional session-name restart)
  "Return an inferior Julia REPL buffer.
The main REPL buffer will be returned if SESSION-NAME is not
given.  If non-nil RESTART is given, the REPL buffer will be
recreated even when a process is alive and running in the buffer."
  (if session-name
      (julia-vterm-repl-buffer-with-session-name session-name restart)
    (julia-vterm-repl-buffer-with-session-name "main" restart)))

(defun julia-vterm-repl ()
  "Create an inferior Julia REPL buffer `*julia:main*` and open it.
If there's already one with the process alive, just open it."
  (interactive)
  (pop-to-buffer-same-window (julia-vterm-repl-buffer)))

(defun julia-vterm-repl-switch-to-script-buffer ()
  "Switch to the script buffer that is paired with this Julia REPL buffer."
  (interactive)
  (let ((repl-buffer (current-buffer))
	(script-buffer (if (buffer-live-p julia-vterm-repl-script-buffer)
			   julia-vterm-repl-script-buffer
			 nil)))
    (if script-buffer
	(with-current-buffer script-buffer
	  (setq julia-vterm-fellow-repl-buffer repl-buffer)
	  (switch-to-buffer-other-window script-buffer)))))

(defun julia-vterm-repl-clear-buffer ()
  "Clear the content of the Julia REPL buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (vterm-clear 1)))

(defvar julia-vterm-repl-copy-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-t") #'julia-vterm-repl-copy-mode)
    (define-key map [return] #'julia-vterm-repl-copy-mode-done)
    (define-key map (kbd "RET") #'julia-vterm-repl-copy-mode-done)
    (define-key map (kbd "C-c C-r") #'vterm-reset-cursor-point)
    map))

(define-minor-mode julia-vterm-repl-copy-mode
  "Toggle copy mode."
  :group 'julia-vterm-repl
  :lighter " VTermCopy"
  :keymap julia-vterm-repl-copy-mode-map
  (if julia-vterm-repl-copy-mode
      (progn
	(message "Start copy mode")
	(use-local-map nil)
	(vterm-send-stop))
    (vterm-reset-cursor-point)
    (use-local-map julia-vterm-repl-mode-map)
    (vterm-send-start)
    (message "End copy mode")))

(defun julia-vterm-repl-copy-mode-done ()
  "Save the active region to the kill ring and exit copy mode."
  (interactive)
  (if (region-active-p)
      (kill-ring-save (region-beginning) (region-end))
    (user-error "No active region"))
  (julia-vterm-repl-copy-mode -1))


;;----------------------------------------------------------------------
(defgroup julia-vterm nil
  "A minor mode to interact with an inferior Julia REPL."
  :group 'julia)

(defcustom julia-vterm-hook nil
  "Hook run after starting a Julia script buffer with an inferior Julia REPL."
  :type 'hook
  :group 'julia-vterm)

(defvar-local julia-vterm-fellow-repl-buffer nil)

(defun julia-vterm-fellow-repl-buffer (&optional session-name)
  "Return the paired REPL buffer or the one specified with SESSION-NAME."
  (if session-name
      (julia-vterm-repl-buffer session-name)
    (if (buffer-live-p julia-vterm-fellow-repl-buffer)
	julia-vterm-fellow-repl-buffer
      (julia-vterm-repl-buffer))))

(defun julia-vterm-switch-to-repl-buffer (&optional prefix)
  "Switch to the paired REPL buffer or to the one with a specified session name.
With PREFIX, prompt for session name."
  (interactive "P")
  (let* ((session-name
	  (cond ((null prefix) nil)
		(t (read-from-minibuffer "Session name: "))))
	 (script-buffer (current-buffer))
	 (repl-buffer (julia-vterm-fellow-repl-buffer session-name)))
    (setq julia-vterm-fellow-repl-buffer repl-buffer )
    (with-current-buffer repl-buffer
      (setq julia-vterm-repl-script-buffer script-buffer)
      (switch-to-buffer-other-window repl-buffer))))

(defun julia-vterm-send-return-key ()
  "Send a return key to the Julia REPL."
  (with-current-buffer (julia-vterm-fellow-repl-buffer)
    (vterm-send-return)))

(defun julia-vterm-paste-string (string &optional session-name)
  "Send STRING to the Julia REPL buffer using brackted paste mode."
  (with-current-buffer (julia-vterm-fellow-repl-buffer session-name)
    (vterm-send-string string t)))

(defun julia-vterm-send-current-line ()
  "Send the current line to the Julia REPL, and move to the next line.
This sends a newline after the content of the current line even if there's no
newline at the end.  A newline is also inserted after the current line of the
script buffer."
  (interactive)
  (save-excursion
    (end-of-line)
    (let ((clmn (current-column))
	  (char (char-after))
	  (line (string-trim (thing-at-point 'line t))))
      (unless (and (zerop clmn) char)
	(when (/= 0 clmn)
	  (julia-vterm-paste-string line)
	  (julia-vterm-send-return-key)
	  (if (not char)
	      (newline))))))
  (forward-line))

(defun julia-vterm-send-region-or-current-line ()
  "Send the content of the region if the region is active, or send the current line."
  (interactive)
  (if (use-region-p)
      (progn
	(julia-vterm-paste-string
	 (buffer-substring-no-properties (region-beginning) (region-end)))
	(deactivate-mark))
    (julia-vterm-send-current-line)))

(defun julia-vterm-send-buffer ()
  "Send the whole content of the script buffer to the Julia REPL line by line."
  (interactive)
  (save-excursion
    (julia-vterm-paste-string (buffer-string))))

(defun julia-vterm-send-include-buffer-file (&optional arg)
  "Send a line to evaluate the buffer's file using include() to the Julia REPL.
With a prefix argument ARG (or interactively C-u), use Revise.includet() instead."
  (interactive "P")
  (let ((fmt (if arg "Revise.includet(\"%s\")\n" "include(\"%s\")\n")))
    (if (and buffer-file-name
	     (file-exists-p buffer-file-name)
	     (not (buffer-modified-p)))
	(julia-vterm-paste-string (format fmt buffer-file-name))
      (message "The buffer must be saved in a file to include."))))

(defun julia-vterm-send-cd-to-buffer-directory ()
  "Send cd() function call to the Julia REPL to change the current working directory of REPL to the buffer's directory."
  (interactive)
  (if buffer-file-name
      (let ((buffer-directory (file-name-directory buffer-file-name)))
	(julia-vterm-paste-string (format "cd(\"%s\")\n" buffer-directory))
	(with-current-buffer (julia-vterm-fellow-repl-buffer)
	  (setq default-directory buffer-directory)))
    (message "The buffer is not associated with a directory.")))

(defalias 'julia-vterm-sync-wd 'julia-vterm-send-cd-to-buffer-directory)

(unless (fboundp 'julia)
  (defalias 'julia 'julia-vterm-repl))

;;;###autoload
(define-minor-mode julia-vterm-mode
  "A minor mode for a Julia script buffer that interacts with an inferior Julia REPL."
  nil "⁂"
  `((,(kbd "C-c C-z") . julia-vterm-switch-to-repl-buffer)
    (,(kbd "C-<return>") . julia-vterm-send-region-or-current-line)
    (,(kbd "C-c C-b") . julia-vterm-send-buffer)
    (,(kbd "C-c C-i") . julia-vterm-send-include-buffer-file)
    (,(kbd "C-c C-d") . julia-vterm-send-cd-to-buffer-directory)))

(provide 'julia-vterm)

;;; julia-vterm.el ends here
