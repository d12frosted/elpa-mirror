;;; emms-state.el --- Display track description and playing time in the mode line

;; Copyright © 2015, 2016, 2021 Alex Kost

;; Author: Alex Kost <alezost@gmail.com>
;; Created: 22 Jan 2015
;; Version: 0.2
;; Package-Version: 20211023.1942
;; Package-Commit: cdb3ee85369758727b3c082e4ade1ae2b559b334
;; Package-Requires: ((emms "0"))
;; URL: https://github.com/alezost/emms-state.el
;; Keywords: emms

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

;; This package provides a minor mode (`emms-state-mode') for displaying
;; description and playing time of the current track (played by EMMS) in
;; the mode line.  A typical mode line string would look like this (it
;; may be configured with `emms-state-mode-line-string' variable):
;;
;;   ⏵ 1:19(5:14) Chopin - Waltz in a-moll, Op.34 No.2

;; To install the package manually, add the following to your init file:
;;
;;   (add-to-list 'load-path "/path/to/emms-state-dir")
;;   (autoload 'emms-state-mode "emms-state" nil t)

;; This package is intended to be used instead of `emms-mode-line' and
;; `emms-playing-time' modes and it is strongly recommended to disable
;; these modes before enabling `emms-state-mode' (keep in mind that
;; these modes are enabled automatically if you use `emms-all' or
;; `emms-devel' setup function).

;;; Code:

(require 'emms-mode-line)
(require 'emms-playing-time)

(defgroup emms-state nil
  "Display track description and playing time in the mode line."
  :group 'emms)

(defface emms-state-title
  '((t nil))
  "Face used for the title of the current track."
  :group 'emms-state)

(defface emms-state-total-playing-time
  '((t :inherit font-lock-constant-face))
  "Face used for the total playing time."
  :group 'emms-state)

(defface emms-state-current-playing-time
  '((t :inherit font-lock-variable-name-face))
  "Face used for the current playing time."
  :group 'emms-state)

(defcustom emms-state-play "⏵"
  "String used to denote the 'play' state."
  :type 'string
  :group 'emms-state)

(defcustom emms-state-pause "⏸"
  "String used to denote the 'pause' state."
  :type 'string
  :group 'emms-state)

(defcustom emms-state-stop "⏹"
  "String used to denote the 'stop' state."
  :type 'string
  :group 'emms-state)

(defvar emms-state-mode-line-string
  '(emms-state
    (" " emms-state
     (emms-state-current-playing-time
      (" "
       (:propertize emms-state-current-playing-time
                    face emms-state-current-playing-time)))
     (emms-state-total-playing-time
      ("("
       (:propertize emms-state-total-playing-time
                    face emms-state-total-playing-time)
       ")"))
     emms-mode-line-string))
  "Mode line string with the EMMS info.")
(put 'emms-state-mode-line-string 'risky-local-variable t)

(defvar emms-state nil
  "Mode line construct for the state of the current EMMS process.")

(defvar emms-state-current-playing-time nil
  "Mode line construct for the current playing time of the track.")

(defvar emms-state-total-playing-time nil
  "Mode line construct for the total playing time of the track.")

(defun emms-state-format-time (time)
  "Convert TIME into a human readable string.
TIME is a number of seconds."
  (let* ((minutes (/ time 60))
         (seconds (% time 60))
         (hours   (/ minutes 60))
         (minutes (% minutes 60)))
    (if (zerop hours)
        (format "%d:%02d" minutes seconds)
      (format "%d:%02d:%02d" hours minutes seconds))))

(defun emms-state ()
  "Return string displaying the state of the current EMMS process."
  (if emms-player-playing-p
      (if emms-player-paused-p
          emms-state-pause
        emms-state-play)
    emms-state-stop))

(defun emms-state-set-state ()
  "Update the value of `emms-state' variable."
  (setq emms-state (emms-state)))

(defun emms-state-set-total-playing-time (&optional _)
  "Update the value of `emms-state-total-playing-time' variable.
Optional argument is used to be compatible with
`emms-track-updated-functions'."
  (let ((time (emms-track-get (emms-playlist-current-selected-track)
                              'info-playing-time)))
    (setq emms-state-total-playing-time
          (and time (emms-state-format-time time)))))

(defun emms-state-set-current-playing-time ()
  "Update the value of `emms-state-current-playing-time' variable."
  (setq emms-state-current-playing-time
        (unless (zerop emms-playing-time)
          (emms-state-format-time emms-playing-time))))


;;; Playing time functions for hooks

(defun emms-state-timer-start ()
  "Start timer for the current playing time."
  (unless emms-playing-time-display-timer
    (setq emms-playing-time-display-timer
          (run-at-time t 1 'emms-state-playing-time-step))))

(defun emms-state-timer-stop ()
  "Stop timer for the current playing time."
  (emms-cancel-timer emms-playing-time-display-timer)
  (setq emms-playing-time-display-timer nil)
  (emms-state-playing-time-update))

(defun emms-state-playing-time-step ()
  "Shift the current playing time by one second."
  (setq emms-playing-time (round (1+ emms-playing-time)))
  (emms-state-playing-time-update))

(defun emms-state-playing-time-update ()
  "Update the current playing time in the mode line."
  (emms-state-set-current-playing-time)
  (force-mode-line-update))

(defun emms-state-playing-time-start ()
  "Start displaying the current playing time."
  (setq emms-playing-time 0)
  (emms-state-timer-start))

(defun emms-state-playing-time-stop ()
  "Stop displaying the current playing time."
  (setq emms-playing-time 0)
  (emms-state-timer-stop))

(defun emms-state-playing-time-pause ()
  "Pause displaying the current playing time."
  (if emms-player-paused-p
      (emms-state-timer-stop)
    (emms-state-timer-start)))

(defalias 'emms-state-playing-time-seek 'emms-playing-time-seek)
(defalias 'emms-state-playing-time-set 'emms-playing-time-set)


;;; Commands

;;;###autoload
(define-minor-mode emms-state-mode
  "Minor mode for displaying some EMMS info in the mode line.

This mode is intended to be a substitution for `emms-mode-line'
and `emms-playing-time'."
  :global t
  (or global-mode-string (setq global-mode-string '("")))
  (let (hook-action activep)
    (if emms-state-mode
        ;; Turn on.
        (progn
          (setq hook-action 'add-hook
                activep t)
          (when emms-player-playing-p (emms-mode-line-alter))
          (emms-state-toggle-mode-line 1))
      ;; Turn off.
      (setq hook-action 'remove-hook
            activep nil)
      (emms-state-playing-time-stop)
      (emms-mode-line-restore-titlebar)
      (emms-state-toggle-mode-line -1))

    (force-mode-line-update)
    (setq emms-mode-line-active-p activep
          emms-playing-time-p activep
          emms-playing-time-display-p activep)

    (funcall hook-action 'emms-track-updated-functions
             'emms-mode-line-alter)
    (funcall hook-action 'emms-player-started-hook
             'emms-mode-line-alter)

    (funcall hook-action 'emms-track-updated-functions
             'emms-state-set-total-playing-time)
    (funcall hook-action 'emms-player-started-hook
             'emms-state-set-total-playing-time)

    (funcall hook-action 'emms-player-started-hook
             'emms-state-set-state)
    (funcall hook-action 'emms-player-stopped-hook
             'emms-state-set-state)
    (funcall hook-action 'emms-player-finished-hook
             'emms-state-set-state)
    (funcall hook-action 'emms-player-paused-hook
             'emms-state-set-state)

    (funcall hook-action 'emms-player-started-hook
             'emms-state-playing-time-start)
    (funcall hook-action 'emms-player-stopped-hook
             'emms-state-playing-time-stop)
    (funcall hook-action 'emms-player-finished-hook
             'emms-state-playing-time-stop)
    (funcall hook-action 'emms-player-paused-hook
             'emms-state-playing-time-pause)
    (funcall hook-action 'emms-player-seeked-functions
             'emms-state-playing-time-seek)
    (funcall hook-action 'emms-player-time-set-functions
             'emms-state-playing-time-set)))

(defun emms-state-toggle-mode-line (&optional arg)
  "Toggle displaying EMMS status info in the mode line.

With prefix argument ARG, enable status info if ARG is positive,
disable otherwise.

Unlike `emms-state-mode', this function will just remove
`emms-state-mode-line-string' from `global-mode-string'.  The
playing timer will still go on."
  (interactive "P")
  (if (or (and (null arg)
               (not (memq 'emms-state-mode-line-string
                          global-mode-string)))
          (and arg
               (> (prefix-numeric-value arg) 0)))
      (add-to-list 'global-mode-string
                   'emms-state-mode-line-string
                   'append)
    (setq global-mode-string
          (remove 'emms-state-mode-line-string
                  global-mode-string)))
  (force-mode-line-update))

(provide 'emms-state)

;;; emms-state.el ends here
