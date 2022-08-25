;;; dark-souls.el --- Prepare to die

;; Copyright (C) 2013 Tom Jakubowski

;; Author: Tom Jakubowski <tom@crystae.net>
;; URL: http://github.com/tomjakubowski/dark-souls.el
;; Package-Version: 20140314.1128
;; Package-Commit: 2c9437265b52f966b2fb13a410a12f3b1e167cb7
;; Version: 1.0
;; Keywords: games

;; This file is not part of GNU Emacs.

;; This file is in the public domain. Do whatever you want with it!

;;; Commentary:

;; dark-souls is a port of the popular game Dark Souls to Emacs.  Run
;; `dark-souls-mode' in any writable buffer to start.  Pause the game
;; by running `dark-souls-mode' again.

;;; Code:

(require 'timer)

(defvar dark-souls-timer nil
  "Timer used by Dark Souls Mode.")
(make-variable-buffer-local 'dark-souls-timer)

(defun dark-souls-you-died ()
  (interactive)
  (insert "YOU DIED\n"))

(defun dark-souls-handler (buf)
  (when (buffer-live-p buf)
    (with-current-buffer buf
      (dark-souls-you-died))))

(defun dark-souls-toggle-timer (buf)
  (with-current-buffer buf
    (if (not (timerp dark-souls-timer))
        (setq dark-souls-timer (run-with-timer 1 1 'dark-souls-handler buf))
      (cancel-timer dark-souls-timer)
      (setq dark-souls-timer nil))))

;;;###autoload
(define-minor-mode dark-souls-mode
  "Prepare to die."
  :lighter " SOULS"
  (dark-souls-toggle-timer (current-buffer)))

(provide 'dark-souls)

;;; dark-souls.el ends here
