;;; password-mode.el --- Hide password text using overlays

;; Copyright (C) 2012-2021  Jürgen Hötzel

;; Author: Jürgen Hötzel <juergen@archlinux.org>
;; URL: https://github.com/juergenhoetzel/password-mode
;; Package-Version: 20210323.1816
;; Package-Commit: 114b721ebbf384b6af6fd46797e83896a9e14aca
;; Version: 1.0-snapshot
;; Package-Requires: ((emacs "25.1"))
;; Keywords: docs password passphrase

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

;; example usage: (add-hook 'text-mode-hook 'password-mode)
;; Using with GPG:
;; http://blog.bogosity.se/2011/01/12/managing-passwords-using-gnupg-git-and-emacs/

;;; Code:

(require 'seq)

;;---------------------------------------------------------------------------
;; user-configurable variables

(defgroup password-mode nil
  "Minor mode for hiding passwords.")

(defcustom password-mode-hook nil
  "*Hook called when password minor mode is activated or deactivated."
  :type 'hook
  :group 'password-mode)

(defcustom password-mode-password-prefix-regexs
  '("[Pp]assword:?[[:space:]]+" "[Pp]asswort:?[[:space:]]+")
  "Regexps recognized as password prefix.

Regexps must not contain parentheses for grouping, otherwise your
match wouldn't work.  Shy groups are OK."
  :type '(repeat (regexp :tag "Password Regex"))
  :group 'password-mode)

(defconst password-mode-shown-text
  (propertize
   (apply 'concat (make-list 5 "*"))
   'face 'font-lock-debug-face)
  "Always show the same text for passwords, so the length is not known.")

(defcustom password-mode-password-regex
  "\\([[:graph:]]*\\)"
  "Regex to match Passwords."
  :type 'regexp
  :group 'password-mode)

(defun password-mode-make-overlay (b e)
  "Return a new overlay in region defined by B and E."
  (let ((ov (make-overlay b e)))
    (overlay-put ov 'display
		 password-mode-shown-text)
    (overlay-put ov 'password-mode-length (- e b))
    ov))

(defun password-mode-prompt-password (ov after start end &optional len)
  "Prompt for new password."
  (when after
    (assert (zerop len))	;when doing insertion, len is always 0
    (let* ((inhibit-modification-hooks t)
	   (insert-length (- (overlay-end ov) (overlay-start ov) (overlay-get ov 'password-mode-length)))
	   (istr (buffer-substring (overlay-start ov) (+ (overlay-start ov) insert-length)))
	   (new-password (password-mode-read-passwd "Password: " t istr)))
      (delete-region (overlay-start ov) (overlay-end ov))
      (delete-overlay ov)
      (password-mode-insert-password new-password)
      (clear-string new-password))))

(defun password-mode-insert-password (new-password)
  "Insert NEW-PASSWORD with hidden password overlay."
  ;; timing issue, first insert a dummy string, so the password is never visible
  (insert (apply 'concat (make-list (length new-password) "*")))
  (let ((ov (password-mode-make-overlay (- (point) (length new-password)) (point))))
    (goto-char (- (point) (length new-password)))
    (insert new-password)
    (delete-region (point) (+ (point) (length new-password)))
    (overlay-put ov 'insert-in-front-hooks '(password-mode-prompt-password))))

;;; reimplementation, of read-passwd (which das not support initial value)
(defun password-mode-read-passwd (prompt &optional confirm initial)
  "Read a password, prompting with PROMPT.
If optional CONFIRM is non-nil, read the password twice to make sure.
Optional INITIAL is a default password to use instead of empty input.

This function echoes `*' for each character that the user types.

The user ends with RET, LFD, or ESC.  DEL or C-h rubs out.
C-y yanks the current kill.  C-u kills line.
C-g quits; if `inhibit-quit' was non-nil around this function,
then it returns nil if the user types C-g, but `quit-flag' remains set.

Once the caller uses the password, it can erase the password
by doing (clear-string STRING)."
  (with-local-quit
    (when confirm
      (let (success)
	(while (not success)
	  (let ((first (password-mode-read-passwd--internal prompt initial))
		(second (password-mode-read-passwd--internal "Confirm password: ")))
	    (if (equal first second)
		(progn
		  (and (arrayp second) (clear-string second))
		  (setq success first))
	      (and (arrayp first) (clear-string first))
	      (and (arrayp second) (clear-string second))
	      (message "Password not repeated accurately; please start over")
	      (setq initial "")
	      (sit-for 1))))
	success))))

(defun password-mode-read-passwd--internal (prompt &optional initial)
  "Internal helper for reading password."
  (let ((pass initial)
	;; Copy it so that add-text-properties won't modify
	;; the object that was passed in by the caller.
	(prompt (copy-sequence prompt))
	(c 0)
	(echo-keystrokes 0)
	(cursor-in-echo-area t)
	(message-log-max nil)
	(stop-keys (list 'return ?\r ?\n ?\e))
	(rubout-keys (list 'backspace ?\b ?\177)))
	(add-text-properties 0 (length prompt)
			     minibuffer-prompt-properties prompt)
	(while (progn (message "%s%s"
			       prompt
			       (make-string (length pass) ?.))
		      (setq c (read-key))
		      (not (memq c stop-keys)))
	  (clear-this-command-keys)
	  (cond ((memq c rubout-keys) ; rubout
		 (when (> (length pass) 0)
		   (let ((new-pass (substring pass 0 -1)))
		     (and (arrayp pass) (clear-string pass))
		     (setq pass new-pass))))
                ((eq c ?\C-g) (keyboard-quit))
		((not (numberp c)))
		((= c ?\C-u) ; kill line
		 (and (arrayp pass) (clear-string pass))
		 (setq pass ""))
		((= c ?\C-y) ; yank
		 (let* ((str (condition-case nil
				 (current-kill 0)
			       (error nil)))
			new-pass)
		   (when str
		     (setq new-pass
			   (concat pass
				   (substring-no-properties str)))
		     (and (arrayp pass) (clear-string pass))
		     (setq c ?\0)
		     (setq pass new-pass))))
		((characterp c) ; insert char
		 (let* ((new-char (char-to-string c))
			(new-pass (concat pass new-char)))
		   (and (arrayp pass) (clear-string pass))
		   (clear-string new-char)
		   (setq c ?\0)
		   (setq pass new-pass)))))
	(message nil)
	pass))

(defun password-mode-hide (b e)
  "Hide password."
  (overlay-put (password-mode-make-overlay b e) 'insert-in-front-hooks '(password-mode-prompt-password)))

(define-minor-mode password-mode
  "Minor mode to hide passwords
With a prefix argument ARG, enable the mode if ARG is positive,
and disable it otherwise.  If called from Lisp, enable the mode
if ARG is omitted or nil.

Passwords are recognized, when the previous word is part of
`password-mode-words' followed by a colon and whitespace

Lastly, the normal hook `password-mode-hook' is run using `run-hooks'.
"
  :group 'password-mode
  :lighter " pw"
  (if password-mode
      (password-mode-hide-all)
    ;; hs-show-all does nothing unless h-m-m is non-nil.
    (add-hook 'post-self-insert-hook 'password-mode-insert-hook-function)
    (let ((passord-mode t))
      (password-mode-discard-overlays (point-min) (point-max)))))

(defun password-mode-insert-hook-function ()
  "Function for editing hidden passwords."
  (when (save-match-data
	  (and password-mode
	       (looking-back (password-mode-regexp) nil)
	       ;; prevent reinvoking
	       (= (match-beginning 2) (point))))
    (password-mode-insert-password (password-mode-read-passwd "Password: " t ""))))

(defun password-mode-regexp ()
  "Regexp from custom variables `password-mode-password-prefix-regexs' and `password-mode-password-regex'."
  (concat "\\(" (mapconcat 'identity  password-mode-password-prefix-regexs "\\|") "\\)"
	  password-mode-password-regex))

(defun password-mode-hide-all ()
  "Hide all passwords using overlays."
  (interactive)
  (password-mode-discard-overlays (point-min) (point-max))
  (save-excursion
    (goto-char (point-min))
    (while
	(re-search-forward (password-mode-regexp) (point-max) t)
      (password-mode-hide (match-beginning 2) (match-end 2)))))

(defun password-mode-discard-overlays (from to)
  "Delete password overlays in region defined by FROM and TO."
  (dolist (ov (overlays-in from to))
    (when (overlay-get ov 'password-mode-length)
      (delete-overlay ov))))

(defun password-mode-copy-as-kill ()
  "Copy the next password at point to the `kill-ring'."
  (interactive)
  (let* ((overlays (nreverse (overlays-in (point) (point-max))))
	 (pov (seq-find (lambda (ov) (overlay-get ov 'password-mode-length)) overlays)))
    (when pov
      (copy-region-as-kill (overlay-start pov) (+ (overlay-start pov) (overlay-get pov 'password-mode-length)))
      (message "Password have been copied to the kill ring."))))

(provide 'password-mode)

;;; password-mode.el ends here
