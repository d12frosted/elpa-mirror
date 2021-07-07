;;; timer-revert.el --- minor mode to revert buffer for a given time interval.

;; Copyright (C) 2015 Yagnesh Raghava Yakkala

;; Author: Yagnesh Raghava Yakkala. http://yagnesh.org
;; Maintainer: hi@yagnesh.org
;; Created: Tuesday, January 20 2015
;; Keywords: timer, revert, auto-revert.
;; Package-Version: 20150120.1128
;; Package-Commit: 31ad8d94b85807cd9f63fcba0c90c3e9a9515fa2
;; Version: 0.1
;; URL: http://github.com/yyr/timer-revert

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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
;; A minor mode to revert buffer for a given time interval.
;;
;; This is more like `auto-revert-mode` but with a specified time
;; interval. see `timer-revert-delay`, defaults to 15 seconds.
;;


;;; Code:

(defcustom timer-revert-delay 15
  "time frequency in seconds to run revert"
  :group 'timer-revert)

(defvar-local timer-revert-timer nil)

(defun timer-revert-buffer (buf)
  "revert buffer if not modified."
  (when (bufferp buf)
    (with-current-buffer buf
      (if (and (buffer-file-name)
               (file-exists-p (buffer-file-name))
               (not (verify-visited-file-modtime (current-buffer))))
          (if (buffer-modified-p)
              "buffer modified. not reverting."
            (progn
              (revert-buffer t t t)
              (message "%s refreshed buffer" (buffer-name))))
        ;;      (message "%s file has not changed outside" (buffer-name))
        ))))


(defun timer-revert-clear-all-timer ()
  (interactive)
  "Clear timer."
  (cancel-function-timers #'timer-revert-buffer)
  (setq-local timer-revert-timer nil))


(defun timer-revert-clear-timer ()
  "Clear timer."
  (when timer-revert-timer
    (cancel-timer timer-revert-timer)
    (setq-local timer-revert-timer nil)))

;;; debug
;; (setq-local timer-revert-delay 7)
;; (setq timer-revert-timer nil)

;;;###autoload
(define-minor-mode timer-revert-mode
  "revert buffer for every `timer-revert-delay'"
  :init-value nil
  :group 'timer-revert
  (cond (timer-revert-mode
         (timer-revert-clear-timer)
         (add-hook 'kill-buffer-hook 'timer-revert-clear-timer nil 'local)
         (setq-local timer-revert-timer
                     (apply 'run-at-time t timer-revert-delay
                            'timer-revert-buffer (list  (current-buffer)))))
        (t
         (timer-revert-clear-timer)
         (remove-hook 'kill-buffer-hook 'timer-revert-clear-timer 'local))))

(provide 'timer-revert)
;;; timer-revert.el ends here
