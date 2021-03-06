;;; dispwatch.el --- Watch displays for configuration changes -*- lexical-binding: t -*-

;; Copyright (C) 2018-2019 Mitchell Perilstein

;; Author: Mitchell Perilstein <mitchell.perilstein@gmail.com>
;; Keywords: frames
;; Package-Version: 20210305.342
;; Package-Commit: 03abbac89a9f625aaa1a808dd49ae4906f466421
;; URL: https://github.com/mnp/dispwatch
;; Version: 1
;; Package-Requires: ((emacs "24.4"))

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

;; This package watches the current display configuration (name, pixel width and height,
;; physical dimensions, and work area) and gives your hook a call if it changes.
;; Intended use case is plugging/unplugging a monitor.
;;
;; Usage
;;
;; Require or use-package this.  Make a hook function which takes one argument, a pair of
;; pixel width and height, like `(1024 . 768)`, then add your hook to
;; `dispwatch-display-change-hooks`.  You will get called when that changes, eg by removing
;; or adding a monitor.  Then call `(dispwatch-mode 1)` to get started and `(dispwatch-mode -1)`
;; to stop.  `(dispwatch-mode)` toggles.
;;
;; Example
;;
;;  (defun my-display-changed-hook (disp)
;;    (message "rejiggering for %s" disp)
;;    (cond ((equal disp '(3840 . 1080))   ; laptop + ext monitor
;;           (setq font-size-pt 10))
;;          ((equal disp '(1920 . 1080))    ; just laptop
;;           (setq font-size-pt 11))
;;          (t (message "Unknown display size %sx%s" (car disp) (cdr disp)))))
;;
;;   (use-package dispwatch
;;     :config (and
;;        (add-hook 'dispwatch-display-change-hooks #'my-display-changed-hook)
;;        (dispwatch-mode 1)))
;;
;;; Code:

;; Local variables
(defgroup dispwatch nil
  "Minor mode for watching display geometry changes."
  :prefix "dispwatch-"
  :group 'Environment)

(defcustom dispwatch-interval 2
  "Frequency to check display, in seconds.
Checking operation does not shell out of Emacs so there isn't much penalty."
  :type 'integer
  :group 'dispwatch
  :safe #'integerp)

(defvar dispwatch-display-change-hooks nil
  "List of hook functions called when a display change is detected.
Each takes one argument: a cons pair of pixel width and height.
The dimensions are determined by `frame-monitor-attributes'.
These hooks are run when a display change is detected.")

(defvar dispwatch-timer nil)

(defvar dispwatch-current-display nil)

(define-minor-mode dispwatch-mode
  "Toggle dispwatch mode.

Interactively with no argument, this command toggles the mode. A
positive prefix argument enables the mode, any other prefix
argument disables it. From Lisp, argument omitted or nil enables
the mode, `toggle' toggles the state.

When dispwatch mode is enabled, the display configuration is
checked every `dispwatch-interval' seconds and if a change is
observed, the hook functions in `dispwatch-display-change-hooks'
with the new display resolution."

  nil	      ;; The initial value.
  "dispwatch" ;; The indicator for the mode line.
  nil	      ;; The minor mode bindings.
  :group 'dispwatch
  :after-hook (if dispwatch-mode
		  (dispwatch--enable)
		  (dispwatch--disable)))

(defun dispwatch--enable ()
  "Enable display reconfiguration detection."
  (interactive)
  (setq dispwatch-current-display (dispwatch--get-display))
  (unless dispwatch-timer
    (setq dispwatch-timer (run-at-time dispwatch-interval dispwatch-interval #'dispwatch--check-display)))
  (message "dispwatch enabled"))

(defun dispwatch--disable ()
  "Disable display reconfiguration detection."
  (interactive)
  (when dispwatch-timer
    (cancel-timer dispwatch-timer)
    (setq dispwatch-timer nil)
    (message "dispwatch disabled")))

(defun dispwatch--get-display()
  "Current display configuration, to compare against future configurations."
  (let ((atts (frame-monitor-attributes)))
    (list
     (assoc 'name atts)
     (assoc 'geometry atts)
     (assoc 'mm-size atts)
     (assoc 'workarea atts))))

(defun dispwatch--check-display()
  "Did it change? Run hooks if so."
  (let ((new (dispwatch--get-display)))
    (unless (equal new dispwatch-current-display)
      (setq dispwatch-current-display new)
      (let* ((geom (assoc 'geometry new))
             (w (nth 3 geom))
             (h (nth 4 geom)))
        (run-hook-with-args 'dispwatch-display-change-hooks (cons w h))))))

(provide 'dispwatch)

;;; dispwatch.el ends here
