;;; insecure-lock.el --- Extensible screen lock framework  -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Qiantan Hong

;; Author: Qiantan Hong <qhong@alum.mit.edu>
;; Maintainer: Qiantan Hong <qhong@alum.mit.edu>
;; URL: https://github.com/BlueFlo0d/insecure-lock
;; Package-Version: 20230426.53
;; Package-Commit: 33b2cf4ecf80d948cf0942aa8bc1787d44c99941
;; Package-Requires: ((emacs "28.1"))
;; Keywords: unix screensaver security
;; Version: 0.0.0

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
;; This package provides an extensible screen lock framework.
;;
;; It is implemented within Emacs itself rather than interfacing with
;; underlying window system, so it is best used together with EXWM as
;; a screen locker.  Otherwise, it can be used as a screen saver.

;;; Code:

;;; Core

(defgroup insecure-lock nil "Screen lock within Emacs."
  :prefix "insecure-lock-" :group 'applications)
(defcustom insecure-lock-require-password t
  "If set, intercept input events and require login password to unlock.
Otherwise unlock with any key stroke, acting more like a screen saver."
  :type 'boolean :group 'insecure-lock)

(defvar insecure-lock--saved-local-map nil)
(defvar insecure-lock--saved-global-map nil)
(defvar insecure-lock-map
  (let ((map (make-keymap))
        (f (if (fboundp 'keymap-substitute)
               'keymap-substitute
             (lambda (map olddef newdef oldmap)
               (substitute-key-definition olddef newdef map oldmap)))))
    (funcall f map 'self-insert-command 'self-insert-command global-map)
    (funcall f map 'delete-backward-char 'delete-backward-char global-map)
    (funcall f map 'exit-minibuffer 'exit-minibuffer minibuffer-mode-map)
    map))
(defun insecure-lock-lock-keys ()
  "Start intercepting input events."
  (when (or insecure-lock--saved-global-map insecure-lock--saved-local-map)
    (error "Already locked keys"))
  (setq insecure-lock--saved-global-map (current-global-map)
        insecure-lock--saved-local-map (current-local-map))
  (use-global-map (make-sparse-keymap))
  (use-local-map (make-sparse-keymap)))
(defun insecure-lock-unlock-keys ()
  "Stop intercepting input events."
  (use-global-map insecure-lock--saved-global-map)
  (use-local-map insecure-lock--saved-local-map)
  (setq insecure-lock--saved-global-map nil
        insecure-lock--saved-local-map nil))

(defvar insecure-lock-update-timer nil)
(defvar insecure-lock-update-functions nil)
(defcustom insecure-lock-update-timer-interval 1
  "Interval to run `insecure-lock-update-functions'."
  :type 'number :group 'insecure-lock)
(defun insecure-lock-run-update-timer ()
  (when insecure-lock-update-timer
    (cancel-timer insecure-lock-update-timer))
  (setq insecure-lock-update-timer
        (run-at-time t insecure-lock-update-timer-interval
                     (lambda () (run-hooks 'insecure-lock-update-functions)))))
(defun insecure-lock-stop-update-timer ()
  (when insecure-lock-update-timer
    (cancel-timer insecure-lock-update-timer)
    (setq insecure-lock-update-timer nil)))

(defvar insecure-lock-idle-timer nil)
(defun insecure-lock-run-idle (seconds)
  "Start idle timer to lock screen after SECONDS.

If SECONDS is nil or non-positive, disable idle timer."
  (interactive (list (read-number "Lock screen after idle seconds, enter 0 to disable: " 300)))
  (when insecure-lock-idle-timer
    (cancel-timer insecure-lock-idle-timer)
    (setq insecure-lock-idle-timer nil))
  (when (and seconds (> seconds 0))
    (setq insecure-lock-idle-timer
          (run-with-idle-timer seconds t #'insecure-lock-enter))))

(defvar insecure-lock-mode-hook '(insecure-lock-blank-screen)
  "You can turn on screen lock \"modules\" by adding functions to this variable.

The order of modules matters! For example, usually you want to
put `insecure-lock-posframe' after the rest so that the posframe
doesn't get blanked/redacted.")
(define-minor-mode insecure-lock-mode
  "Global minor mode for screen lock."
  :global t :require 'insecure-lock)

(defvar insecure-lock-last-incorrect-attempts 0)

(defun insecure-lock--authenticate (password)
  "Use `su' to authenticate PASSWORD for current user.

Return non-nil if PASSWORD is correct."
  (message "Authenticating...")
  (let* (retval
         (proc (make-process
                :sentinel
                (lambda (_ message)
                  (setq retval message))
                :filter
                (lambda (proc _)
                  (process-send-string proc password)
                  (process-send-string proc "\n"))
                :name "su"
                :command (list "su" (user-login-name) "-c" "true")
                :connection-type 'pty)))
    (while (not retval) (accept-process-output proc))
    (equal retval "finished\n")))

;;;###autoload
(defun insecure-lock-enter ()
  "Toggle on screen lock."
  (interactive)
  (unless insecure-lock-mode
    (setq insecure-lock-update-functions nil)
    (insecure-lock-mode)
    (when insecure-lock-update-functions
      (insecure-lock-run-update-timer))
    (if insecure-lock-require-password
        (progn
          (insecure-lock-lock-keys)
          (setq insecure-lock-last-incorrect-attempts 0)
          (while (not (insecure-lock--authenticate
                       (let ((read-passwd-map insecure-lock-map))
                         (read-passwd
                          (if (> insecure-lock-last-incorrect-attempts 0)
                              (format "%s incorrect attempts. Password: " insecure-lock-last-incorrect-attempts)
                            "Password: ")))))
            (cl-incf insecure-lock-last-incorrect-attempts))
          (insecure-lock-unlock-keys)
          (message "%s incorrect attempts" insecure-lock-last-incorrect-attempts))
      (read-key))
    (insecure-lock-stop-update-timer)
    (insecure-lock-mode -1)))

;;; Screen Lock Modules

(defvar insecure-lock--saved-window-configuration nil)

(defun insecure-lock--display-buffer-full-frame (buffer alist)
  "Compatibility function for `display-buffer-full-frame'.

Display BUFFER in the current frame, taking the entire frame.
ALIST is an association list of action symbols and values.  See
Info node `(elisp) Buffer Display Action Alists' for details of
such alists.

This is an action function for buffer display, see Info
node `(elisp) Buffer Display Action Functions'.  It should be
called only by `display-buffer' or a function directly or
indirectly called by the latter."
  (when-let ((window (or (display-buffer-reuse-window buffer alist)
                         (display-buffer-same-window buffer alist)
                         (display-buffer-pop-up-window buffer alist)
                         (display-buffer-use-some-window buffer alist))))
    (delete-other-windows window)
    window))

(defface insecure-lock-blank-screen-face '((default :inherit default))
  "Blank screen remap default face to this face.

Useful for setting a background color.")
(defun insecure-lock-blank-screen ()
  "`insecure-lock' module that blanks screen.

Display a blank buffer without modeline in place of any
displaying buffers/windows."
  (if insecure-lock-mode
      (progn
        (when insecure-lock--saved-window-configuration (error "Already blanked screen"))
        (setq insecure-lock--saved-window-configuration (current-window-configuration))
        (push '(default . insecure-lock-blank-screen-face) face-remapping-alist)
        (push '(fringe . insecure-lock-blank-screen-face) face-remapping-alist)
        (with-current-buffer (get-buffer-create " *Insecure Lock Blank Screen*")
          (setq-local mode-line-format nil cursor-type nil)
          (dolist (frame (frame-list))
            (with-selected-frame frame
              (funcall (if (fboundp 'display-buffer-full-frame)
                           'display-buffer-full-frame
                         'insecure-lock--display-buffer-full-frame)
                       (current-buffer) nil)))))
    (set-window-configuration insecure-lock--saved-window-configuration)
    (setq insecure-lock--saved-window-configuration nil)
    (setq face-remapping-alist
          (delete '(fringe . insecure-lock-blank-screen-face)
           (delete '(default . insecure-lock-blank-screen-face) face-remapping-alist)))))

(declare-function redacted-mode redacted)
(defvar-local insecure-lock--saved-mode-line-format nil)
(defun insecure-lock-redact ()
  "`insecure-lock' module that redacts buffers.

Turn on `redacted-mode' and disable mode line on any displaying buffer."
  (unless (require 'redacted nil t) (user-error "Package `redacted' not available"))
  (if insecure-lock-mode
      (progn
        (dolist (frame (frame-list))
          (dolist (window (window-list frame))
            (with-current-buffer (window-buffer window)
              (redacted-mode)
              (when (local-variable-p 'mode-line-format)
                (setq-local insecure-lock--saved-mode-line-format mode-line-format
                            mode-line-format " ")))))
        (setq-default insecure-lock--saved-mode-line-format mode-line-format
                      mode-line-format " "))
    (dolist (frame (frame-list))
      (dolist (window (window-list frame))
        (with-current-buffer (window-buffer window)
          (redacted-mode -1)
          (when (local-variable-p 'mode-line-format)
            (setq-local  mode-line-format insecure-lock--saved-mode-line-format
                         insecure-lock--saved-mode-line-format nil)))))
    (setq-default mode-line-format insecure-lock--saved-mode-line-format
                  insecure-lock--saved-mode-line-format nil)))

(require 'shr)
(declare-function posframe-show posframe)
(declare-function posframe-delete posframe)
(defvar insecure-lock-posframe-parameters
  '(:position (0 . 0) ;; workaround posframe bug
    :poshandler posframe-poshandler-frame-center :internal-border-width 3)
  "Parameters to the posframe shown by `insecure-lock-posframe'.")
(defun insecure-lock-posframe-default-update-function ()
  "Default function for `insecure-lock-posframe-update-function'.

Shows current time and date in two lines, padded and centered."
  (unless (require 'posframe nil t) (user-error "Package `posframe' not available"))
  (with-current-buffer " *Insecure Lock Screensaver*"
    (delete-region (point-min) (point-max))
    (let ((line1 (propertize (concat " " (format-time-string "%-I:%M:%S %p") " ")
                             'face '(:height 10.0)))
          (line2 (propertize (format-time-string "%a %m/%d/%Y")
                             'face '(:height 5.0))))
      (insert line1 "\n"
              (propertize " " 'display
                          `(space :width (,(/ (- (shr-string-pixel-width line1)
                                                 (shr-string-pixel-width line2))
                                              2))))
              line2))
    (apply #'posframe-show (current-buffer) insecure-lock-posframe-parameters)))
(defvar insecure-lock-posframe-update-function 'insecure-lock-posframe-default-update-function
  "Function to populate the posframe shown by `insecure-lock-posframe'.")
(defun insecure-lock-posframe ()
  "`insecure-lock' module that display a posframe."
  (if insecure-lock-mode
      (progn
        (get-buffer-create " *Insecure Lock Screensaver*")
        (add-hook 'insecure-lock-update-functions insecure-lock-posframe-update-function)
        (funcall insecure-lock-posframe-update-function))
    (posframe-delete " *Insecure Lock Screensaver*")))

(provide 'insecure-lock)
;;; insecure-lock.el ends here
