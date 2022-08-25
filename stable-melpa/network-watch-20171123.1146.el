;;; network-watch.el --- Support for intermittent network connectivity
;; Copyright (C) 2010-2017 Juan Amiguet Vercher

;; Author: Juan Amiguet Vercher <jamiguet@gmail.com>
;; Created: 17 Oct 2017
;; Version: 1.0
;; Package-Commit: d80b38dbec79f813c3949a8df8fb5f58d48b60ee
;; Package-Version: 20171123.1146
;; Package-X-Original-Version: 1.0
;; Keywords: unix tools hardware lisp
;; Homepage: https://github.com/jamiguet/network-watch
;; Package-Requires: ((emacs "24.3"))

;; This file is not part of GNU Emacs.

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

;; Global minor mode for handling intermitent network access.  It provides
;; two hooks `network-watch-up-hook' and `network-watch-down-hook' every
;; `network-watch-time-interval' the network status is checked if
;; nothing changed since the previous time no hooks are invoked.  If
;; access to a network is possible then the `network-watch-up-hook' is run.
;; Conversely when network connectivity is lost the `network-watch-down-hook'
;; is run.
;;
;; Install via elpa then enable `network-watch-mode'.  You can also
;; adapt the `network-watch-update-time-interval' to your liking.
;;
;; Besides the two hooks the library also provides a `network-watch-active-p'
;; function which returns not nil when a listed interface is up.
;;
;; In this example `gmail-notifier' is configured with the help of
;; network-watch - it is automatically started and stopped when the network
;; is up or down respectively:
;;
;; 	(require 'network-watch)
;; 	(require 'gmail-notifier)
;;
;; 	(setq gmail-notifier-username "jamiguet")
;; 	(setq gmail-notifier-password ja-password)
;;
;;      (add-hook 'network-watch-up-hook 'gmail-notifier-start)
;; 	(add-hook 'network-watch-down-hook 'gmail-notifier-stop)
;;

;;; Code:
(require 'cl-lib)

(defvar network-watch-timer)
(defvar network-watch-last-state)


(defgroup network-watch nil
  "Watch and respond to the availability of network interfaces."
  :group 'Communication)


(defcustom network-watch-time-interval 120
  "Refresh rate for network status."
  :type 'integer)

(defcustom network-watch-up-hook ()
  "Hook called when a watched interface becomes available."
  :type 'hook)

(defcustom network-watch-down-hook ()
  "Hook called when a watched interface stops being available."
  :type 'hook)


(defun network-watch-update-lighter()
  "Return a mode lighter reflecting the current network state."
  (concat " N(" (if (network-watch-active-p) "+" "-") ")"))


(defun network-watch-active-p ()
  "Return nil if loopback is the only active interface."
  (cl-remove-if #'(lambda (it) (equal (cdr it) [127 0 0 1 0])) (network-interface-list)))


(defun network-watch-update-system-state ()
  "Internal method update the network state variable."
  (setq network-watch-last-state (network-watch-active-p)))


(defun network-watch-update-state ()
  "Run hooks only on network status change."
  (interactive)
  (if (cl-set-exclusive-or
       (if (listp (network-watch-active-p))
	   (network-watch-active-p)
	 (list (network-watch-active-p)))
       (if (listp network-watch-last-state)
	   network-watch-last-state
	 (list network-watch-last-state)))
      (progn
        (run-hooks (if (network-watch-active-p) 'network-watch-up-hook 'network-watch-down-hook))
	(network-watch-update-system-state)))
  (setq network-watch-timer (run-with-timer network-watch-time-interval  nil 'network-watch-update-state)))


;;;###autoload
(define-minor-mode network-watch-mode
  "Network is automatically on when there is a valid network interface active."
  :init-value t
  :lighter (:eval (network-watch-update-lighter))
  :global t
  :require 'network-watch
  (if network-watch-mode
      (progn
        (network-watch-update-system-state)
        (setq network-watch-timer (run-with-timer network-watch-time-interval  nil 'network-watch-update-state))
        (if (network-watch-active-p) (run-hooks 'network-watch-up-hook))
        (message "Network init"))
    (cancel-timer network-watch-timer)))

(provide 'network-watch)
;;; network-watch.el ends here
