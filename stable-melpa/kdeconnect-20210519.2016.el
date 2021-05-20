;;; kdeconnect.el --- An interface for KDE Connect

;; Copyright (C) 2016-2020 Carl Lieberman

;; Author: Carl Lieberman <dev@carl.ac>
;; Keywords: kdeconnect, android
;; Package-Version: 20210519.2016
;; Package-Commit: 4977af8cb5fdc21da770f3ee43ad7823f2937da3
;; Version: 1.2.2

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

;; This package provides helper functions to use the command line
;; version of KDE Connect, a bridge between Android devices and
;; computers, without leaving the comfort of Emacs.  It requires KDE
;; Connect on your computer(s) and Android device(s).  KDE Connect
;; currently requires Linux on the desktop, but does not require
;; KDE.

;;; Code:

(defvar kdeconnect-active-device nil
  "The ID of the active device.")

(defvar kdeconnect-devices nil
  "The IDs of your available devices.")

;;;###autoload
(defun kdeconnect-get-active-device ()
  "Display the ID of the active device."
  (interactive)
  (message kdeconnect-active-device))

;;;###autoload
(defun kdeconnect-list-devices ()
  "Display all visible devices, even unavailable ones."
  (interactive)
  (shell-command "kdeconnect-cli -l"))

;;;###autoload
(defun kdeconnect-ping ()
  "Ping the active device."
  (interactive)
  (shell-command
   (mapconcat 'identity
              (list "kdeconnect-cli" "-d"
                    (shell-quote-argument kdeconnect-active-device)
                    "--ping") " ")))

;;;###autoload
(defun kdeconnect-ping-msg (message)
  "Ping the active device with MESSAGE."
  (interactive "MEnter message: ")
  (shell-command
   (mapconcat 'identity
              (list "kdeconnect-cli" "-d"
                    (shell-quote-argument kdeconnect-active-device)
                    "--ping-msg" (shell-quote-argument message)) " ")))

;;;###autoload
(defun kdeconnect-refresh ()
  "Refresh connections."
  (interactive)
  (shell-command "kdeconnect-cli --refresh"))

;;;###autoload
(defun kdeconnect-ring ()
  "Ring the active device."
  (interactive)
  (shell-command
   (mapconcat 'identity
              (list "kdeconnect-cli" "-d"
                    (shell-quote-argument kdeconnect-active-device)
                    "--ring") " ")))

;;;###autoload
(defun kdeconnect-send-file (path)
  "Send the file at PATH to the active device."
  (interactive "fSelect file: ")
  (shell-command
   (mapconcat 'identity
              (list "kdeconnect-cli" "-d"
                    (shell-quote-argument kdeconnect-active-device)
                    "--share" (shell-quote-argument
                               (expand-file-name path))) " ")))

;;;###autoload
(defun kdeconnect-send-text (text)
  "Send TEXT to the active device."
  (interactive "MEnter a text to share: ")
  (shell-command
   (mapconcat 'identity
              (list "kdeconnect-cli" "-d"
                    (shell-quote-argument kdeconnect-active-device)
                    "--share-text" (shell-quote-argument text)) " ")))

;;;###autoload
(defun kdeconnect-send-text-region-or-prompt ()
  "Send text to the active device interactively.
If the REGION is active send that text, otherwise prompt for what to send"
  (interactive )
  (if (use-region-p)
      (kdeconnect-send-text (buffer-substring (region-beginning) (region-end)))
    (call-interactively 'kdeconnect-send-text)))

;;;###autoload
(defun kdeconnect-select-active-device (name)
  "Set the active device to NAME."
  (interactive
   (list (completing-read
          "Select a device: "
          (split-string kdeconnect-devices "," t)
          nil t "")))
  (setq kdeconnect-active-device name))

;;;###autoload
(defun kdeconnect-send-sms (message destination)
  (interactive "MEnter message: \nnEnter destination: ")
  (shell-command
   (mapconcat 'identity
              (list "kdeconnect-cli" "-d"
                    (shell-quote-argument kdeconnect-active-device)
                    "--destination" (number-to-string destination)
                    "--send-sms" (shell-quote-argument message)) " ")))

(provide 'kdeconnect)
;;; kdeconnect.el ends here
