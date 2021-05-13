;;; nix-modeline.el --- Info about in-progress Nix evaluations on your modeline  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Jordan Mulcahey

;; Version: 1.1.0
;; Package-Version: 20210405.742
;; Package-Commit: ecda866b960321bb82deac26af45918e172ef0ba
;; Author: Jordan Mulcahey <snhjordy@gmail.com>
;; Description: Show in-progress Nix evaluations on your modeline
;; URL: https://github.com/ocelot-project/nix-modeline
;; Keywords: processes, unix, tools
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

;; Displays the number of running Nix evaluations in the modeline.
;; Runs efficiently using the filenotify built-in library to watch
;; files that Nix updates on the start and completion of each
;; operation. Useful as the missing UI for Nix asynchronous build tools
;; like `lorri'.

;;; Code:

(eval-when-compile (require 'subr-x))
(require 'filenotify)
(require 'seq)

(defgroup nix-modeline nil
  "Display running Nix builders in the modeline."
  :group 'mode-line
  :group 'tools)

(defcustom nix-modeline-default-text " λ(?) "
  "The text for nix-modeline to display before its watchers start."
  :type 'string)

(defcustom nix-modeline-idle-text " λ(✓) "
  "The text for nix-modeline to show when no builders are running."
  :type 'string)

(defcustom nix-modeline-running-text " λ⇒%s "
  "The text for nix-modeline to display when builders are running.

Note that a %s format specifier in this string will be replaced with the number
of Nix builders running."
  :type 'string)

(defcustom nix-modeline-error-text " λ(X) "
  "The text to display when nix-modeline encounters an error."
  :type 'string)

(defcustom nix-modeline-trigger-files '("/nix/var/nix/db")
  "A list of files and directories nix-modeline will monitor.

Changes to any of these files will cause nix-modeline to update, which forces a
modeline redisplay. The ideal files for this purpose should reliably be changed
only when Nix operations begin and end."
  :type '(repeat string))

(defcustom nix-modeline-users 'self
  "A symbol indicating which users' Nix builders should be tracked.

Usually, setting this variable only makes sense in multi-user Nix environments.

`self' means to track only your own builders.
`self-and-root' means your builders and those belonging to root get tracked.
`all' means to track all of the builders on the system."
  :type '(choice (const :tag "Your User" 'self)
                 (const :tag "Your User and root" 'self-and-root)
                 (const :tag "All Users" 'all)))

(defcustom nix-modeline-process-regex "\\(nix-build\\)\\|\\(nix-instantiate\\)"
  "A regex of process names that should count as Nix builders.

nix-modeline  uses the number of matching processes to report how many Nix
builders are in progress."
  :type 'regexp)

(defcustom nix-modeline-process-counter (pcase system-type
                                          ('darwin 'pgrep)
                                          (_ 'lisp))
  "The method nix-modeline should use to count Nix builders.

`lisp' is a pure Emacs Lisp process counter with no runtime dependencies.
`pgrep' starts a pgrep process on every nix-modeline event. This is useful on
platforms like macOS where `process-attributes' returns nothing useful."
  :type '(choice (const :tag "Pure Lisp" 'lisp)
                 (const :tag "pgrep" 'pgrep)))

(defcustom nix-modeline-pgrep-string "pgrep %s %s"
  "The command line used when counting processes with pgrep.

Note: the first %s in this variable gets replaced by the value of
`nix-modeline--pgrep-users', and the second %s gets replaced by the value of
`nix-modeline-process-regex'."
  :type 'string)

(defcustom nix-modeline-delay 0.1
  "The delay between when nix-modeline triggers and when it updates.

This value is in seconds. Short delays help coalesce file watcher events, and
prevent race conditions in nix-modeline during lengthy Nix builds."
  :type 'number)

(defcustom nix-modeline-hook nil
  "List of functions to be called when nix-modeline updates."
  :type 'hook)

(defface nix-modeline-idle-face
  '((t :inherit mode-line))
  "Face used when no Nix builders are running.")

(defface nix-modeline-running-face
  '((t :inherit homoglyph))
  "Face used when one or more Nix builders are running.")

(defface nix-modeline-error-face
  '((t :inherit warning))
  "Face used when nix-modeline's encounters an error.")

(defvar nix-modeline--watchers '()
  "The list of file watchers nix-modeline uses to monitor Nix.")

(defvar nix-modeline--timer nil
  "The timer configured by `nix-modeline-delay'.")

(defvar nix-modeline--status-text ""
  "The string representing the current Nix builder status.")

(defvar nix-modeline-mode)

(defun nix-modeline--error (msg)
  "Set nix-modeline to the error state and print MSG."
  (setq nix-modeline--status-text (propertize nix-modeline-error-text
                                              'face 'nix-modeline-error-face))
  (message (format "nix-modeline: %s" msg)))

(defun nix-modeline--update (num-builders)
  "Update nix-modeline's text and force redisplay all modelines.

NUM-BUILDERS is a string from the nix-modeline child process representing the
number of Nix builder processes it saw running."
  (setq nix-modeline--status-text (pcase num-builders
                                    (0 (propertize nix-modeline-idle-text
                                                   'face 'nix-modeline-idle-face))
                                    (n (propertize (format nix-modeline-running-text n)
                                                   'face 'nix-modeline-running-face))))
  (run-hooks 'nix-modeline-hook)
  (force-mode-line-update 'all))

(defun nix-modeline--pgrep-filter (process output)
  "Update nix-modeline based on the OUTPUT of its pgrep PROCESS."
  (ignore process)
  (let ((nix-procs (split-string output nil 'omit-nulls)))
        (nix-modeline--update (length nix-procs))))

(defun nix-modeline--pgrep-sentinel (process event)
  "When the pgrep PROCESS signals an EVENT, handle it.

An oddity of pgrep is that it exits with code 1 when no processes match, which
we handle here."
  (ignore process)
  (pcase event
    ("finished\n" nil)
    ("exited abnormally with code 1\n" (nix-modeline--update 0))
    (e (nix-modeline--error (format "pgrep %s" e)))))

(defun nix-modeline--pgrep-users ()
  "Convert a nix-modeline users setting into a pgrep argument."
  (pcase nix-modeline-users
    ('self (format "-U %s" (user-uid)))
    ('self-and-root (format "-U %s -U 0" (user-uid)))
    ('all "")))

(defun nix-modeline--pgrep-callback ()
  "Count Nix builder processes using pgrep."
  (let ((process-connection-type nil))
    (make-process
     :name "Nix Process Counter"
     :buffer nil
     :command (split-string (format nix-modeline-pgrep-string
                                    (nix-modeline--pgrep-users)
                                    (replace-regexp-in-string
                                     "\\\\"
                                     ""
                                     nix-modeline-process-regex))
                            nil 'omit-nulls)
     :filter 'nix-modeline--pgrep-filter
     :sentinel 'nix-modeline--pgrep-sentinel
     :noquery t)))

(defun nix-modeline--pure-callback ()
  "Count Nix builder processes using pure Emacs Lisp."
  (let ((nix-procs
         (seq-filter (lambda (p) (and (string-match-p
                                       nix-modeline-process-regex
                                       (alist-get 'comm p ""))
                                      (eq (alist-get 'euid p) (user-uid))))
                     (mapcar (lambda (pid) (process-attributes pid))
                             (list-system-processes)))))
    (nix-modeline--update (length nix-procs))))

(defun nix-modeline--callback ()
  "On a watch event, select a callback implementation."
  (when nix-modeline-mode
    (nix-modeline--start-watchers))
  (pcase nix-modeline-process-counter
    ('lisp (nix-modeline--pure-callback))
    ('pgrep (nix-modeline--pgrep-callback))))

(defun nix-modeline--start-watchers ()
  "Start watchers for the paths in `nix-modeline-trigger-files'."
  (setq nix-modeline--watchers
        (mapcar (lambda (path)
                  (file-notify-add-watch path
                                         '(change)
                                         (lambda (event)
                                           (unless (or (eq (cadr event) 'stopped)
                                                       (not (file-notify-valid-p (car event))))
                                             (nix-modeline--stop-watchers)
                                             (and (timerp nix-modeline--timer)
                                                  (cancel-timer nix-modeline--timer))
                                             (setq nix-modeline--timer (run-with-timer nix-modeline-delay
                                                                                       nil
                                                                                       #'nix-modeline--callback))))))
                nix-modeline-trigger-files)))

(defun nix-modeline--stop-watchers ()
  "Stop the watchers in `nix-modeline--watchers'."
  (dolist (watcher nix-modeline--watchers)
    (file-notify-rm-watch watcher))
  (setq nix-modeline--watchers '()))

;;;###autoload
(define-minor-mode nix-modeline-mode
  "Displays the number of running Nix builders in the modeline."
  :global t :group 'nix-modeline
  (nix-modeline--stop-watchers)
  (setq nix-modeline--status-text "")
  (or global-mode-string (setq global-mode-string '("")))
  (cond
   (nix-modeline-mode
    (add-to-list 'global-mode-string '(t (:eval nix-modeline--status-text))
                 'append)
    (setq nix-modeline--status-text (propertize nix-modeline-default-text
                                                'face 'nix-modeline-idle-face))
    (nix-modeline--callback))
   (t
    (setq global-mode-string
          (remove '(t (:eval nix-modeline--status-text)) global-mode-string)))))

(provide 'nix-modeline)
;;; nix-modeline.el ends here
