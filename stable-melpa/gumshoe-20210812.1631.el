;;; gumshoe.el --- Scoped spatial and temporal POINT movement tracking -*- lexical-binding: t; -*-

;; Copyright (C) 2021 overdr0ne

;; Author: overdr0ne
;; Version: 1.0
;; Package-Version: 20210812.1631
;; Package-Commit: 35a4b0f45437309a10e2c72e523012c2e2eded07
;; Package-Requires: ((emacs "25.1"))
;; Keywords: tools
;; URL: https://github.com/Overdr0ne/gumshoe

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
;; Gumshoe is a collection of global minor modes that quietly
;; keep tabs on your Point movements so you can retrace your steps if you
;; ever need a reminder of where you’ve been.  Each mode keeps a log local
;; to some scope.

;; Gumshoes log any movements outside their minimum follow distance.
;; They will also log any position you idle at for a while.
;; You may then use their log to backtrack to previous locations.

;;; Code:

(require 'eieio)
(require 'cl-lib)
(require 'ring)

(defgroup gumshoe nil
  "The gumshoe movement tracker."
  :group 'convenience
  :prefix "gumshoe-")

(defcustom gumshoe-log-len 100
  "Length of gumshoe--backlog’s ring-buffer."
  :type 'integer)
(defcustom gumshoe-follow-distance 15
  "Gumshoe logs movements beyond this Euclidean distance from previous entry."
  :type 'integer)
(defcustom gumshoe-horizontal-scale 3
  "Horizontal follow distances are divided by this factor."
  :type 'integer)

(defcustom gumshoe-idle-time 60
  "Gumshoe automatically logs your position if you’ve been idle at POINT for this amount of time."
  :type 'integer)

(defcustom gumshoe-display-buffer-action '((display-buffer-reuse-window display-buffer-same-window))
  "`display-buffer-action’ to use when jumping through the backlog.

See `display-buffer' for more information"
  :type 'list)

(defclass gumshoe--backlog ()
  ((log :initform (make-ring gumshoe-log-len)
        :documentation "Ring-buffer to remember the previous editing position.")
   (index :initform 0
          :documentation "Current index backwards into the log when backtracking.")
   (backtrackingp :initform nil
                  :documentation "Flag indicating when a gumshoe is using the log to backtrack.")
   (:documentation "Gumshoe’s backlog for tracking POINT positions.") ))

(defun gumshoe--line-number-at (pos)
  "Return column number at POS."
  (save-excursion
    (goto-char pos)
    (current-column)))

(defun gumshoe--distance-to (marker)
  "Return the Euclidean distance between point and MARKER."
  (let* ((pos (marker-position marker))
         (line (line-number-at-pos pos))
         (dline (abs (- line
                        (line-number-at-pos (point)))))
         (column (gumshoe--line-number-at pos))
         (dcolumn (abs (- column
                          (current-column))))
         (dcolumn-scaled (/ dcolumn gumshoe-horizontal-scale)))
    (sqrt (+ (expt dline 2) (expt dcolumn-scaled 2)))))

(defun gumshoe--end-of-leash-p (last-mark)
  "Check if LAST-MARK is outside gumshoe’s boundary."
  (> (gumshoe--distance-to last-mark)
     gumshoe-follow-distance))

(defun gumshoe--log-current-position (ring)
  "Add current position to the RING as a marker."
  (when (or (ring-empty-p ring)
            (not (equal (point-marker) (ring-ref ring 0))))
    (ring-insert ring (point-marker))))

(cl-defmethod gumshoe--track ((self gumshoe--backlog))
  "Log the current position to SELF if necessary."
  (unless self (error "Gumshoe argument self is nil"))
  (with-slots (backtrackingp log index) self
    (unless (or backtrackingp (minibufferp))
      (setf index 0)
      (if (ring-empty-p log)
          (gumshoe--log-current-position log)
        (let ((last-mark (ring-ref log 0)))
          (when (or (not (eq (current-buffer)
                             (marker-buffer last-mark)))
                    (gumshoe--end-of-leash-p last-mark))
            (ring-insert log (point-marker))))))
    (setf backtrackingp nil)))

(defun gumshoe--ring-clean (ring)
  "Cleanup markers from RING without a buffer."
  (let ((i 0))
    (while (< i (ring-length ring))
      (let ((marker (ring-ref ring i)))
        (if (marker-buffer marker)
            (cl-incf i)
          (ring-remove ring i))))))

(defun gumshoe--ring-reset (ring)
  "Reset all entries in RING to nil."
  (let ((i 0))
    (while (< i (ring-length ring))
      (ring-remove ring i))))

(defun gumshoe--jump-to-marker (marker)
  "Move to MARKER point and associated buffer."
  (let ((buf  (marker-buffer marker)))
    (when buf
      (pop-to-buffer buf gumshoe-display-buffer-action)
      (goto-char marker))))

(cl-defmethod gumshoe--backtrack-back ((self gumshoe--backlog))
  "Jump backward one position in SELF."
  (with-slots (backtrackingp log index) self
    (setf backtrackingp t)
    (unless (ring-empty-p log)
      (when (equal (ring-ref log index) (point-marker))
        (cl-incf index))
      (gumshoe--jump-to-marker (ring-ref log index))
      (cl-incf index))))

(cl-defmethod gumshoe--backtrack-forward ((self gumshoe--backlog))
  "Jump forward one position in the SELF backlog."
  (with-slots (backtrackingp log index) self
    (setf backtrackingp t)
    (unless (or (ring-empty-p log)
                (eq index 0))
      (cl-decf index)
      (when (equal (ring-ref log index) (point-marker))
        (cl-decf index))
      (gumshoe--jump-to-marker (ring-ref log index)))))

(defun gumshoe--timer-callback (backlog-var)
  "Called by timer to log current position in BACKLOG-VAR."
  (unless (symbol-value backlog-var)
    (set backlog-var (gumshoe--backlog)))
  (unless (oref (symbol-value backlog-var) backtrackingp)
    (gumshoe--log-current-position (oref (symbol-value backlog-var) log))))

(defun gumshoe--start-timer (backlog-var timer-var)
  "Start TIMER-VAR timer to log BACKLOG-VAR position by name.

Set TIMER-VAR globally such that it can be cancelled on revert."
  (set timer-var
       (run-with-idle-timer gumshoe-idle-time t
                            (apply-partially #'gumshoe--timer-callback backlog-var))))

(defun gumshoe--pre-command-callback (backlog-var)
  "Triggers tracking for BACKLOG-VAR, initializing it if necessary."
  (unless (symbol-value backlog-var)
    (set backlog-var (gumshoe--backlog)))
  (gumshoe--track (symbol-value backlog-var)))

(defun gumshoe--kill-buffer-callback (backlog-var)
  "Garbage collect dangling markers in BACKLOG-VAR for killed buffer."
  (when (symbol-value backlog-var)
    (gumshoe--ring-clean (oref (symbol-value backlog-var) log))))

(defun gumshoe--add-hooks (backlog-var)
  "Add hooks using the BACKLOG-VAR by name.

Reference the variable by name because the value will change depending on context."
  (add-hook 'pre-command-hook
            (apply-partially #'gumshoe--pre-command-callback backlog-var))
  (add-hook 'kill-buffer-hook
            (apply-partially #'gumshoe--kill-buffer-callback backlog-var)))

(defmacro gumshoe--make-commands (backlog-var backtrack-back-name backtrack-forward-name)
  "Make the command interface for BACKLOG-VAR by name.

BACKTRACK-BACK-NAME and BACKTRACK-FORWARD-NAME are names for the backtracking commands."
  `(progn
     (defun ,backtrack-back-name () (interactive) (gumshoe--backtrack-back ,backlog-var))
     (defun ,backtrack-forward-name () (interactive) (gumshoe--backtrack-forward ,backlog-var))))

(defmacro gumshoe--mode-init (backlog-var timer-var backtrack-back-name backtrack-forward-name)
  "Initialize gumshoe mode for BACKLOG-VAR.

Set timer for TIMER-VAR.

Set BACKTRACK-BACK-NAME and BACKTRACK-FORWARD-NAME commands."
  `(progn
     (gumshoe--add-hooks ',backlog-var)
     (gumshoe--start-timer ',backlog-var ',timer-var)
     (gumshoe--make-commands ,backlog-var ,backtrack-back-name ,backtrack-forward-name)))

(defmacro gumshoe--revert (backlog-var timer-var)
  "Revert BACKLOG-VAR and TIMER-VAR.

Variables are not purged, because it’s easier, and because that’s probably
what users want anyway, to keep old marks."
  `(progn
     (remove-hook 'pre-command-hook
                  (apply-partially #'gumshoe--pre-command-callback ,backlog-var))
     (remove-hook 'kill-buffer-hook
                  (apply-partially #'gumshoe--kill-buffer-callback ,backlog-var))
     (cancel-timer ,timer-var)))

(defvar gumshoe--global-backlog nil
  "A class of symbol `gumshoe--backlog' with global scope.")
(defvar gumshoe--global-timer nil
  "Global idle timer that logs position for `gumshoe--global-backlog’ after `gumshoe-idle-time'.")
;;;###autoload
(define-minor-mode global-gumshoe-mode
  "Toggle global Gumshoe minor mode.

Interactively with no argument, this command toggles the mode.
A positive prefix argument enables the mode, any other prefix
argument disables it.  From Lisp, argument omitted or nil enables
the mode, `toggle' toggles the state.

When enabled, Gumshoe logs point movements when they exceed the
`gumshoe-follow-distance', or when the user is idle longer than
`gumshoe-idle-time'."
  :init-value nil
  :lighter " Gumshoe:global"
  :group 'gumshoe
  :global t
  (if global-gumshoe-mode
      (gumshoe--mode-init gumshoe--global-backlog
                          gumshoe--global-timer
                          gumshoe-backtrack-back
                          gumshoe-backtrack-forward)
    (gumshoe--revert gumshoe--global-backlog gumshoe--global-timer)))

(defvar gumshoe--persp-backlog nil
  "A class of symbol `gumshoe--backlog' with perspective scope.")
(defvar gumshoe--persp-timer nil
  "Global idle timer that logs position for `gumshoe--persp-backlog’ after`gumshoe-idle-time'.")
;; suppress warning that this function isn’t defined because perspective
;; is required
(declare-function persp-make-variable-persp-local "perspective.el")
(defun gumshoe--persp-created-callback ()
  "Create a new backlog for every new persp.

This wouldn’t be necessary if persp initialized local variables to
nil, because there is no other way to know generically whether that
variable actually belongs to that perspective generically."
  (setq gumshoe--persp-backlog (gumshoe--backlog)))
(defun gumshoe--global-gumshoe-persp-mode-enable ()
  "Enable the symbol `global-gumshoe-persp-mode’."
  (require 'perspective)
  (persp-make-variable-persp-local 'gumshoe--persp-backlog)
  (add-hook 'persp-created-hook
            #'gumshoe--persp-created-callback)
  (gumshoe--mode-init gumshoe--persp-backlog
                      gumshoe--persp-timer
                      gumshoe-persp-backtrack-back
                      gumshoe-persp-backtrack-forward))
;;;###autoload
(define-minor-mode global-gumshoe-persp-mode
  "Toggle persp Gumshoe minor mode.

Interactively with no argument, this command toggles the mode.
A positive prefix argument enables the mode, any other prefix
argument disables it.  From Lisp, argument omitted or nil enables
the mode, `toggle' toggles the state.

When enabled, Gumshoe logs point movements when they exceed the

`gumshoe-follow-distance', or when the user is idle longer than
`gumshoe-idle-time'."
  :init-value nil
  :lighter " Gumshoe:persp"
  :group 'gumshoe
  :global t
  (if global-gumshoe-persp-mode
      (gumshoe--global-gumshoe-persp-mode-enable)
    (gumshoe--revert gumshoe--persp-backlog gumshoe--persp-timer)))

(defvar-local gumshoe--buf-backlog nil
  "A class of gumshoe--backlog with buffer scope.")
(defvar gumshoe--buf-timer nil
  "Global idle timer that logs position for `gumshoe--buf-backlog’ after `gumshoe-idle-time'.")
;;;###autoload
(define-minor-mode global-gumshoe-buf-mode
  "Toggle global Gumshoe minor mode.

Interactively with no argument, this command toggles the mode.
A positive prefix argument enables the mode, any other prefix
argument disables it.  From Lisp, argument omitted or nil enables
the mode, `toggle' toggles the state.

When enabled, Gumshoe logs point movements when they exceed the
`gumshoe-follow-distance', or when the user is idle longer than
`gumshoe-idle-time'."
  :init-value nil
  :lighter " Gumshoe:buf"
  :group 'gumshoe
  :global t
  (if global-gumshoe-buf-mode
      (gumshoe--mode-init gumshoe--buf-backlog
                          gumshoe--buf-timer
                          gumshoe-buf-backtrack-back
                          gumshoe-buf-backtrack-forward)
    (gumshoe--revert gumshoe--buf-backlog gumshoe--buf-timer)))

(provide 'gumshoe)
;;; gumshoe.el ends here
