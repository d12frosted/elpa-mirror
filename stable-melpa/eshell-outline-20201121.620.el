;;; eshell-outline.el --- Enhanced outline-mode for Eshell  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Jamie Beardslee

;; Author: Jamie Beardslee <jdb@jamzattack.xyz>
;; Keywords: unix, eshell, outline, convenience
;; Package-Version: 20201121.620
;; Package-Commit: 6f917afa5b3d36764d76d7864589094647d8c3b4
;; Version: 2020.09.12
;; URL: https://git.jamzattack.xyz/eshell-outline
;; Package-Requires: ((emacs "25.1"))

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

;; `eshell-outline-mode' defines a few commands to integrate
;; `outline-minor-mode' into `eshell'.  Some eshell-specific keys have
;; been rebound so that they have multiple uses.

;; Namely, "C-c C-c" and "C-c C-k" will either kill/interrupt the
;; running process, or show/hide the prompt+output at point.

;; "C-c M-o" (`eshell-mark-output'/`eshell-outline-narrow') now uses
;; narrowing to clear the buffer as an analogue to
;; `comint-clear-buffer' and replacement for `eshell/clear'.  It is
;; also able to narrow to a previous prompt+output.

;; "C-c M-m" (undefined/`eshell-outline-mark') marks the prompt+output
;; at point, replacing "C-c M-o" which has been rebound.  If point is
;; at an empty prompt at the end of the buffer, this will mark the
;; previous prompt+output instead.

;; Because this mode doesn't actually enable `outline-minor-mode', I
;; also bind "C-c @" to `outline-mode-prefix-map'.

;; See the docstring of `eshell-outline-mode' for a full list of
;; keybindings.

;;; Code:

(require 'eshell)
(require 'outline)

(defvar eshell-last-input-start)
(defvar eshell-prompt-regexp)

;;; Internal functions

(defun eshell-outline--final-prompt-p ()
  "Return t if point is at or after the final prompt."
  (>= (point) (marker-position eshell-last-input-start)))

(defun eshell-outline--setup-outline-variables ()
  "Set a couple of outline variables for Eshell."
  (setq-local outline-regexp eshell-prompt-regexp)
  (setq-local outline-level (lambda () 1)))


;;; Commands

(defun eshell-outline-toggle-or-interrupt (&optional arg)
  "Interrupt the process or toggle outline children.
If prefix ARG is simply \\[universal-argument], always toggle
children.  If ARG is anything else, or if a process is running
and point is beyond the final prompt, attempt to interrupt it.
Otherwise, toggle children."
  (interactive "P")
  (cond ((eq arg '(4))
	 (outline-toggle-children))
	((or arg (and eshell-process-list
		      (eshell-outline--final-prompt-p)))
	 (eshell-interrupt-process))
	(t
	 (outline-toggle-children))))

(defun eshell-outline-toggle-or-kill (&optional arg)
  "Kill the process or toggle outline children.
If prefix ARG is simply \\[universal-argument], always toggle
children.  If ARG is anything else, or if a process is running
and point is beyond the final prompt, kill it.  Otherwise, toggle
children."
  (interactive "P")
  (cond ((eq arg '(4))
	 (outline-toggle-children))
	((or arg (and eshell-process-list
		      (eshell-outline--final-prompt-p)))
	 (eshell-kill-process))
	(t
	 (outline-toggle-children))))

(defun eshell-outline-mark ()
  "Mark the current prompt and output.
If point is at the end of the buffer, this will mark the previous
command's output."
  (interactive)
  (if (= (point) (point-max))
      (forward-line -1))
  (outline-mark-subtree))

(defun eshell-outline-narrow (&optional widen)
  "Narrow to the current prompt and output.
With prefix arg, WIDEN instead of narrowing."
  (interactive "P")
  (cond (widen
	 (widen))
	((and eshell-process-list
	      (not (eshell-outline--final-prompt-p)))
	 (user-error "Cannot narrow while a process is running"))
	(t
	 (let ((beg
		(save-excursion
		  (end-of-line)
		  (re-search-backward eshell-prompt-regexp nil t)))
	       (end
		(save-excursion
		  (if (re-search-forward eshell-prompt-regexp nil t 1)
		      (progn (forward-line 0)
			     (point))
		    (point-max)))))
	   (narrow-to-region beg end)))))


;;; The minor mode

;;;###autoload
(define-minor-mode eshell-outline-mode
  "Outline-mode in Eshell.

\\{eshell-outline-mode-map}"
  :lighter " $…"
  :keymap
  (let ((map (make-sparse-keymap)))
    ;; eshell-{previous,next}-prompt are the same as
    ;; outline-{next,previous} -- no need to bind these.
    (define-key map (kbd "C-c C-c") #'eshell-outline-toggle-or-interrupt)
    (define-key map (kbd "C-c C-k") #'eshell-outline-toggle-or-kill)
    (define-key map (kbd "C-c M-m") #'eshell-outline-mark)
    ;; similar to `comint-clear-buffer'
    (define-key map (kbd "C-c M-o") #'eshell-outline-narrow)

    ;; From outline.el
    (define-key map (kbd "C-c C-a") #'outline-show-all)
    (define-key map (kbd "C-c C-t") #'outline-hide-body)

    ;; Default `outline-minor-mode' keybindings
    (define-key map (kbd "C-c @") outline-mode-prefix-map)
    map)

  (if eshell-outline-mode
      (progn
	(eshell-outline--setup-outline-variables)
	(add-to-invisibility-spec '(outline . t))
	;; TODO: how to make minor-mode only available in eshell-mode?
	(unless (derived-mode-p 'eshell-mode)
	  (eshell-outline-mode -1)
	  (user-error "Only enable this mode in eshell")))
    (remove-from-invisibility-spec '(outline . t))
    (outline-show-all)))

;;;###autoload
(defun eshell-outline-view-buffer ()	; temporary
  "Clone the current eshell buffer, and enable `outline-mode'.
This will clone the buffer via `clone-indirect-buffer', so all
following changes to the original buffer will be transferred.
The command `eshell-outline-mode' offers a more interactive
version, with specialized keybindings."
  (interactive)
  (let ((buffer
	 (clone-indirect-buffer
	  (generate-new-buffer-name "*eshell outline*")
	  nil)))
    (with-current-buffer buffer
      (outline-mode)
      (eshell-outline--setup-outline-variables)
      (outline-hide-body))
    (pop-to-buffer buffer)))

(provide 'eshell-outline)
;;; eshell-outline.el ends here
