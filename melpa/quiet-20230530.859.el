;;; quiet.el --- Disconnect from the online world for a while

;; Copyright 2016 FoAM vzw
;;
;; Author: nik gaffney <nik@fo.am>
;; Created: 2016-05-05
;; Version: 0.1
;; Package-Version: 20230530.859
;; Package-Commit: 985b56606517971330c08686c49a8d06db763f3c
;; Keywords: convenience, quiet, distraction, network, detachment, offline
;; URL: https://github.com/zzkt/quiet

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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; A simple package to disconnect from the online world for a while,
;; possibly reconnecting later.  Any interruptions or distractions
;; which occur once the command is run are guaranteed to be local.
;;
;; 'M-x quiet' will disconnect from the network, optionally
;; reconnecting after a certain time.
;;
;; the function 'quiet' can be used anywhere in Emacs where a lack of
;; network access could be seen as a feature, e.g. as a mode-hook (or
;; with defadvice) to your preferred distraction free writing
;; environment.
;;
;; you may need to customize or setq quiet-disconnect and
;; quiet-connect to the appropriate shell commands to turn your
;; network (interface) on or off
;;
;;; Code:


(defcustom quiet-disconnect "networksetup -setairportpower airport off"
  "Shell command to turn off network connection(s)."
  :type  '(choice
           (string :tag "macOS" "networksetup -setairportpower airport off")
           (string :tag "GNU/Linux" "ifdown wlan0")
           (string :tag "*BSD" "ifdown wlan0")
           (string :tag "other" ""))
  :group 'quiet)

(defcustom quiet-connect "networksetup -setairportpower airport on"
  "Shell command to turn on network connection(s)."
  :type  '(choice
           (string :tag "macOS" "networksetup -setairportpower airport on")
           (string :tag "GNU/Linux" "ifup wlan0")
           (string :tag "*BSD" "ifup wlan0")
           (string :tag "other" ""))
    :group 'quiet)

(defcustom quiet-timer 0
  "Timer to reconnect network after a given time (in minutes).
A value of 0 will leave the connection off."
  :type 'integer
  :group 'quiet)

;;;###autoload
(defun quiet ()
  "Quieten network distractions for a while..."
  (interactive)
  (save-window-excursion
   (message "disconnecting...")
   (async-shell-command quiet-disconnect))
  (if (not (= quiet-timer 0))
      (progn
        (run-at-time (* quiet-timer 60) nil 'quiet-reconnect))))

;; provide a 'disconnect' alias
(fset 'disconnect 'quiet)

;;;###autoload
(defun quiet-reconnect ()
  "Reconnect to networked distractions."
  (interactive)
  (save-window-excursion
   (message "reconnecting after ~%d %s"
            quiet-timer
            (if (= quiet-timer 1) "minute" "minutes"))
   (async-shell-command quiet-connect)))

(provide 'quiet)

;;; quiet.el ends here
