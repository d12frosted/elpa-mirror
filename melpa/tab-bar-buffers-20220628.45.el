;;; tab-bar-buffers.el --- Use tab-bar-mode as a buffer manager -*- lexical-binding: t; -*-

;; Author: Andy Rosen <ajr@corp.mlfs.org>
;; URL: https://github.com/ajrosen/emacs
;; Package-Version: 20220628.45
;; Package-Commit: c7581d244665d86464a301eb0aa68dd08c44501f
;; Version: 20220627.2012
;; Package-Requires: ((emacs "28.1"))
;; Keywords: convenience, frames

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.


;;; Commentary:

;; This package piggy-backs on `tab-bar-mode' to implement a simple
;; buffer manager.  Instead of managing tabs it manages buffers.

;; Installation:

;; Add (`tab-bar-buffers-mode' t) to your `custom-file'.
;;
;; Or enable `tab-bar-buffers-mode` from the Easy Customization form.
;;
;; (customize-group 'tab-bar-buffers)

;; Some of tab-bar-mode's customization options are also relevant for
;; tab-bar-buffers.
;;
;; `tab-bar-close-button-show'
;; `tab-bar-position'
;; `tab-bar-select-tab-modifiers'
;; `tab-bar-tab-hints'

;; If `tab-bar-tab-name-function' is `tab-bar-tab-name-truncated' then
;; `tab-bar-tab-name-truncated-max' and `tab-bar-tab-name-ellipsis'
;; are honored.

;; The face for `tab-bar-tab' is used for `current-buffer'.
;; `tab-bar-tab-inactive' is used for all other buffers.

;; Key and mouse bindings are preserved by advising some of
;; tab-bar-mode's commands around their tab-bar-buffers equivalent, as
;; defined by `tab-bar--define-keys'.
;;
;; `tab-new'
;; `tab-bar-select-tab'
;; `tab-next'
;; `tab-previous'
;; `tab-recent'
;; `tab-last'
;; `tab-bar-close-tab'


;;; Code:

(require 'cl-lib)
(require 'tab-bar)

;; Customization
;;;###autoload
(defgroup tab-bar-buffers nil
  "Buffers in tab-mode."
  :group 'tab-bar)

(defcustom tab-bar-buffers-uninteresting-buffers
  (list "*Backtrace*" "*Completions*" "*Help*" "*Messages*")
  "A list of buffer names that are not interesting.

A buffer is shown in the tab bar only if it is interesting."
  :type '(repeat string)
  :group 'tab-bar-buffers
  :tag "Uninteresting Buffers"
  :link '(function-link tab-bar-buffers--interesting-buffer-p))

;;;###autoload
(define-minor-mode tab-bar-buffers-mode
  "Show buffers instead of tabs in tab-bar."
  :global t
  :interactive (tab-bar-mode)
  :group 'tab-bar-buffers
  (if tab-bar-buffers-mode
      (progn
	(setq tab-bar-tabs-function 'tab-bar-buffers)
	(tab-bar-buffers--define-keys))
    (progn
      (setq tab-bar-tabs-function 'tab-bar-tabs)
      (tab-bar-buffers--undefine-keys))))


(defun tab-bar-buffers (&optional _frame)
  "Return a list of buffers for use as `tab-bar-tabs-function'.

See `tab-bar-buffers--interesting-buffer-p' for what makes a buffer interesting."
  (mapcar
   (lambda (buffer)
     (setq-local name-prop `(name . ,(tab-bar-buffers--name-format buffer)))
     (if (eq buffer (current-buffer)) `(current-tab ,name-prop) `(tab ,name-prop)))
   (tab-bar-buffers--interesting-buffers--sort)))


(defun tab-bar-buffers--name-format (buffer)
  "Function to format a BUFFER name in the tab bar.

`tab-bar-tab-name-truncated-max' and `tab-bar-tab-name-ellipsis'
are honored if `tab-bar-tab-name-function' is
`tab-bar-tab-name-truncated'."
  (let ((n (buffer-name buffer)))
    (if (and (eq tab-bar-tab-name-function 'tab-bar-tab-name-truncated)
	     (length> n tab-bar-tab-name-truncated-max))
	(truncate-string-to-width n tab-bar-tab-name-truncated-max nil nil tab-bar-tab-name-ellipsis)
      n)))


(defun tab-bar-buffers--current-buffer-number ()
  "Return `current-buffer's number."
  (cl-position (current-buffer) (tab-bar-buffers--interesting-buffers--sort)))


;; Buffer selection

(defun tab-bar-buffers--interesting-buffer-p (buffer)
  "Check if BUFFER is interesting.

A buffer is interesting if its name does not start with space, it
is visible, or it is not in `tab-bar-buffers-uninteresting-buffers'"
  (let ((n (buffer-name buffer)))
    (cond
     ((string-prefix-p " " n) nil)
     ((get-buffer-window n) t)
     ((seq-contains-p tab-bar-buffers-uninteresting-buffers n) nil)
     (t t))))


(defun tab-bar-buffers--interesting-buffers ()
  "Return a list of interesting buffers.

See `tab-bar-buffers--interesting-buffer-p'."
  (let ((ib nil) )
    (mapc
     (lambda (b)
       (if (tab-bar-buffers--interesting-buffer-p b) (push b ib)))
     (buffer-list))
    ib))


(defun tab-bar-buffers--interesting-buffers--sort ()
  "Return a list of `tab-bar-buffers--interesting-buffers' sorted by name."
  (sort (tab-bar-buffers--interesting-buffers) 'tab-bar-buffers--buffer-name-lessp))


(defun tab-bar-buffers--buffer-name-lessp (buffer1 buffer2)
  "Return non-nil if BUFFER1 is less than BUFFER2 in lexicographic order.

 See `string-lessp'."
  (string-lessp (buffer-name buffer1) (buffer-name buffer2)))


(defun tab-bar-buffers--switch-to-buffer-by-number (&optional buffer-number)
  "`switch-to-buffer' by its number.

Buffers that are `tab-bar-buffers--interesting-buffer-p' are
ordered by `tab-bar-buffers--buffer-name-lessp'.  If
BUFFER-NUMBER is nil it is assumed we are being called from a
mouse click event."
  (unless buffer-number
    (setq buffer-number (- (event-basic-type last-command-event) ?0 1)))

  (let ((ib (tab-bar-buffers--interesting-buffers--sort)))
    (if (nth 1 ib)
	(pop-to-buffer (nth buffer-number ib)))))


;; Repurpose tab-bar navigation commands

;; tab-bar-new-tab
(defun tab-bar-buffers-new-buffer (&optional _arg _from-number)
  "`switch-to-buffer' *scratch*."
  (interactive "P")
  (switch-to-buffer "*scratch*"))


;; tab-bar-select-tab
(defun tab-bar-buffers-select-buffer (_func &rest event)
  "Select the buffer at mouse click.

EVENT corresponds to a key event, or nil for mouse clicks.

See `tab-bar-mouse-down-1'."
  (if (car event) (tab-bar-buffers--switch-to-buffer-by-number (- (car event) 1))
    (tab-bar-buffers--switch-to-buffer-by-number)))


;; tab-next
(defun tab-bar-buffers-next (_func &rest _args)
  "Switch to the next buffer shown in the tab bar."
  (interactive)
  (let* ((c (tab-bar-buffers--current-buffer-number))
	 (l (length (tab-bar-buffers--interesting-buffers))))
    (when (and c (< (+ c 1) l))
      (tab-bar-buffers--switch-to-buffer-by-number (+ c 1)))))


;; tab-prev
(defun tab-bar-buffers-prev (_func &rest _args)
  "Switch to the previous buffer shown in the tab bar."
  (interactive)
  (let ((c (tab-bar-buffers--current-buffer-number)))
    (when (and c (> c 0))
      (tab-bar-buffers--switch-to-buffer-by-number (- c 1)))))


;; tab-recent
(defun tab-bar-buffers-recent (_func &rest _args)
  "Switch to most recently selected buffer as defined by `other-buffer'."
  (interactive)
  (switch-to-buffer (other-buffer)))


;; tab-last
(defun tab-bar-buffers-last (_func &rest _args)
  "Switch to the last buffer in the tab bar."
  (interactive)
  (switch-to-buffer (car (last (tab-bar-buffers--interesting-buffers--sort)))))


;; tab-bar-close-tab
(defun tab-bar-buffers-close-buffer (_func &rest event)
  "Call `kill-buffer' on the selected buffer.

EVENT corresponds to a key event, or nil for mouse clicks."
  (if (car event) (kill-buffer (nth (- (car event) 1) (tab-bar-buffers--interesting-buffers--sort)))
    (kill-buffer)))


;; tab-bar-buffers--define-keys
(defun tab-bar-buffers--define-keys()
  "Remap tab-bar key bindings to their `tab-bar-buffers` equivalents.

See `tab-bar--define-keys'."
  (advice-add 'tab-new :around #'tab-bar-buffers-new-buffer)
  (advice-add 'tab-bar-select-tab :around #'tab-bar-buffers-select-buffer)
  (advice-add 'tab-next :around #'tab-bar-buffers-next)
  (advice-add 'tab-previous :around #'tab-bar-buffers-prev)
  (advice-add 'tab-recent :around #'tab-bar-buffers-recent)
  (advice-add 'tab-last :around #'tab-bar-buffers-last)
  (advice-add 'tab-bar-close-tab :around #'tab-bar-buffers-close-buffer))


;; tab-bar-buffers--undefine-keys
(defun tab-bar-buffers--undefine-keys()
  "Restore original tab-bar key bindings.

See `tab-bar--undefine-keys'."
  (advice-remove 'tab-new #'tab-bar-buffers-new-buffer)
  (advice-remove 'tab-bar-select-tab #'tab-bar-buffers-select-buffer)
  (advice-remove 'tab-next #'tab-bar-buffers-next)
  (advice-remove 'tab-previous #'tab-bar-buffers-prev)
  (advice-remove 'tab-recent #'tab-bar-buffers-recent)
  (advice-remove 'tab-last #'tab-bar-buffers-last)
  (advice-remove 'tab-bar-close-tab #'tab-bar-buffers-close-buffer))


(provide 'tab-bar-buffers)

;;; tab-bar-buffers.el ends here
