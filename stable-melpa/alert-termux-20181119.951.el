;;; alert-termux.el --- alert.el notifications on Termux  -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Gergely Polonkai

;; Author: Gergely Polonkai <gergely@polonkai.eu>
;; Keywords: terminals
;; Package-Version: 20181119.951
;; Package-Commit: 8215cf1d86392738c35a90bbc0055359265dfc4d
;; Version: 1.0
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/gergelypolonkai/alert-termux

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Alert style that uses termux-notification to send alerts.
;;
;; The the required command, termux-notification can be found in the termux-api package, and
;; requires the Termux API app to be installed alongside with Termux.

;;; Code:

(require 'alert)

(defcustom alert-termux-command (executable-find "termux-notification")
  "Path to the termux-notification command.
This is found in the termux-api package, and it requires the Termux API addon
app to be installed."
  :type 'file
  :group 'alert)

(defun alert-termux-notify (info)
  "Send INFO using termux-notification.
Handles :TITLE and :MESSAGE keywords from the INFO plist."
  (if alert-termux-command
      (let ((args (nconc
                   (when (plist-get info :title)
                     (list "-t" (alert-encode-string (plist-get info :title))))
                   (list "-c" (alert-encode-string (plist-get info :message))))))
        (apply #'call-process alert-termux-command nil
               (list (get-buffer-create " *termux-notification output*") t)
               nil args))
    (alert-message-notify info)))

(alert-define-style 'termux
                    :title "Notify using termux"
                    :notifier #'alert-termux-notify)

(provide 'alert-termux)
;;; alert-termux.el ends here
