;;; undo-propose.el --- Simple and safe undo navigation -*- lexical-binding: t -*-

;; Author: Jack Kamm
;; Maintainer: Jack Kamm
;; Version: 4.0.0
;; Package-Version: 20210207.45
;; Package-Commit: 91a1dfe516d90dab69c368f6669bacb2458ec5e9
;; Package-Requires: ((emacs "24.3"))
;; Homepage: https://github.com/jackkamm/undo-propose.el
;; Keywords: convenience, files, undo, redo, history


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.


;;; Commentary:


;; undo-propose.el is a package for navigating through your undo history
;; in a temporary buffer.

;; To use undo-propose, call "M-x undo-propose" in the buffer you are editing.
;; This will send you to a new temporary buffer, which is read-only except
;; for allowing `undo' commands.  Cycle through the list of undo's as normal.
;; When you are finished, type "C-c C-c" to commit the chain of undo's.
;; This copies both the buffer and undo-ring back to the parent buffer.
;; Alternatively, type "C-c C-b" to copy the buffer but not the undo-ring
;; (the changes are added as a single edit in the undo-history).
;; To cancel, type "C-c C-k".  You can also
;; ediff the proposed chain of undo's by typing "C-c C-d".

;;; Code:

(require 'cl-lib)

(defgroup undo-propose nil
  "Simple and safe undo navigation"
  :group 'convenience)

(defcustom undo-propose-done-hook nil
  "Hook runs when leaving the temporal buffer."
  :type 'hook
  :group 'undo-propose)

(defcustom undo-propose-entry-hook nil
  "Hook runs when entering the temporal buffer."
  :type 'hook
  :group 'undo-propose)

(make-obsolete-variable 'undo-propose-pop-to-buffer
                        "`undo-propose-pop-to-buffer' is obsolete.
The default window behavior has also changed. Use
`display-buffer-alist' to configure window behavior."
                        "4.0.0")

(defcustom undo-propose-marker-list
  '(org-clock-marker org-clock-hd-marker)
  "List of quoted markers to update after running undo-propose."
  :type 'list
  :group 'undo-propose)

(defvar undo-propose-parent nil "Parent buffer of ‘undo-propose’ buffer.")

(defun undo-propose--message (content)
  "Message CONTENT, possibly with prefix \"undo-propose: \"."
  (let ((prefix "undo-propose: "))
    (message
     (concat (when (> (frame-width)
                      (+ (length prefix) (length content)))
               prefix)
             content))))

;;;###autoload
(defun undo-propose ()
  "Navigate undo history in a new temporary buffer.
\\<undo-propose-mode-map>
Copies 'current-buffer' and 'buffer-undo-list' to a new temporary buffer,
which is read-only except for undo commands.  After finished undoing, type
\\[undo-propose-commit] to accept the chain of undos,
or \\[undo-propose-squash-commit] to copy the buffer but squash the undo's into a single edit event event.  To cancel, type \\[undo-propose-cancel], and
to view an ediff type \\[undo-propose-diff].

If already inside an `undo-propose' buffer, this will simply call `undo'."
  (interactive)
  (if (bound-and-true-p undo-propose-mode)
      (undo)
    (let ((mode major-mode)
          (orig-buffer (current-buffer))
          (list-copy (undo-copy-list buffer-undo-list))
          (pos (point))
          (win-start (window-start))
          (tmp-buffer (generate-new-buffer
                       (concat "*Undo Propose: "
                               (buffer-name) "*"))))
      (pop-to-buffer tmp-buffer)
      (funcall mode)
      (insert-buffer-substring orig-buffer 1 (1+ (buffer-size orig-buffer)))
      (goto-char pos)
      (set-window-start (selected-window) win-start)
      (setq-local buffer-undo-list list-copy)
      (setq-local buffer-read-only t)
      (setq-local undo-propose-parent orig-buffer)
      (undo-propose-mode 1)
      (undo-propose-copy-markers)
      (run-hooks 'undo-propose-entry-hook)
      (undo-propose--message "C-c C-c to commit, C-c C-s to squash commit, C-c C-k to cancel, C-c C-d to diff"))))

(define-minor-mode undo-propose-mode
  "Minor mode for `undo-propose'."
  nil " UndoP" (make-sparse-keymap))
(define-key undo-propose-mode-map (kbd "C-c C-c") 'undo-propose-commit)
(define-key undo-propose-mode-map (kbd "C-c C-s") 'undo-propose-squash-commit)
(define-key undo-propose-mode-map (kbd "C-c C-d") 'undo-propose-diff)
(define-key undo-propose-mode-map (kbd "C-c C-k") 'undo-propose-cancel)

(defmacro undo-propose-wrap (command)
  "Wrap COMMAND so it is useable within the ‘undo-propose’ buffer."
  `(define-key undo-propose-mode-map [remap ,command]
     (lambda ()
       (interactive)
       (let ((inhibit-read-only t))
         (call-interactively ',command)))))

(undo-propose-wrap undo)
(undo-propose-wrap undo-only)

(defun undo-propose-commit ()
  "Quit and copy ‘undo-propose’ buffer and undo-ring back to the parent buffer."
  (interactive)
  (let ((win (selected-window))
        (orig-buffer undo-propose-parent)
        (list-copy (undo-copy-list buffer-undo-list))
        (pos (point)))
    (copy-to-buffer orig-buffer 1 (buffer-end 1))
    (with-current-buffer orig-buffer
      (setq-local buffer-undo-list list-copy))
    (undo-propose-update-markers)
    (quit-restore-window win 'kill)
    (switch-to-buffer orig-buffer)
    (goto-char pos)
    (undo-propose--message "commit"))
  (run-hooks 'undo-propose-done-hook))

(defun undo-propose-squash-commit ()
  "Like `undo-propose-commit', but squashing undos into a single edit.
That is, the undo-ring is NOT copied to the parent, only the
buffer contents are copied."
  (interactive)
  (let* ((win (selected-window))
         (pos (point))
         (tmp-buffer (current-buffer))
         (tmp-end (1+ (buffer-size tmp-buffer)))
         (orig-buffer undo-propose-parent)
         (orig-end (1+ (buffer-size orig-buffer)))
         (first-diff (abs (compare-buffer-substrings
                           tmp-buffer 1 tmp-end orig-buffer 1 orig-end))))
    ;; copy from 1st diff, so we don't jump to top of buffer when redoing
    (with-current-buffer orig-buffer
      (when (/= first-diff 0)
        (delete-region first-diff (point-max))
        (goto-char (point-max))
        (insert-buffer-substring tmp-buffer first-diff tmp-end)
        (goto-char first-diff)))
    (undo-propose-update-markers)
    (quit-restore-window win 'kill)
    (switch-to-buffer orig-buffer)
    (goto-char pos)
    (undo-propose--message "squash commit"))
  (run-hooks 'undo-propose-done-hook))
(define-obsolete-function-alias 'undo-propose-commit-buffer-only
  'undo-propose-squash-commit "3.0.0")

(define-obsolete-function-alias 'undo-propose-finish
  'undo-propose-squash-commit "3.0.0")

(defun undo-propose-cancel ()
  "Kill ‘undo-propose’ buffer without copying back to its parent."
  (interactive)
  (quit-restore-window (selected-window) 'kill)
  (undo-propose--message "cancel")
  (run-hooks 'undo-propose-done-hook))

(defun undo-propose-diff ()
  "View differences between ‘undo-propose’ buffer and its parent using `ediff'."
  (interactive)
  (ediff-buffers undo-propose-parent (current-buffer)))

(defvar-local undo-propose-marker-map nil)

(defun undo-propose-copy-markers ()
  "Copy markers registered in `undo-propose-marker-list'."
  (setq-local undo-propose-marker-map
              (cl-loop for marker-symbol in undo-propose-marker-list
                       if (when (boundp marker-symbol)
                            (let ((orig-marker (symbol-value marker-symbol)))
                              (when (markerp orig-marker)
                                (eq (marker-buffer orig-marker)
                                    undo-propose-parent))))
                       collect
                       (let ((orig-marker (symbol-value marker-symbol))
                             (new-marker (make-marker)))
                         (move-marker new-marker (marker-position orig-marker))
                         (cons new-marker orig-marker)))))

(defun undo-propose-update-markers ()
  "Update marker positions in parent buffer."
  (cl-loop for association in undo-propose-marker-map do
           (let ((new-marker (car association))
                 (orig-marker (cdr association)))
             ;; only update if orig-marker still exists
             (when (and (markerp orig-marker)
                        (eq (marker-buffer orig-marker) undo-propose-parent))
               (move-marker orig-marker (marker-position new-marker)
                            undo-propose-parent)))))

(provide 'undo-propose)

;;; undo-propose.el ends here
