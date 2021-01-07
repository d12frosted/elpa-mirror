;;; kaleidoscope.el --- Controlling Kaleidoscope-powered devices.
;;
;; Copyright (c) 2017 Gergely Nagy
;;
;; Author: Gergely Nagy
;; URL: https://github.com/algernon/kaleidoscope.el
;; Package-Version: 20170808.817
;; Package-Commit: af4034dcace867c4ede0bce744d5cb888c318f23
;; Version: 0.1.0
;; Package-Requires: ((s "1.11.0"))
;;
;; This file is NOT part of GNU Emacs.
;;
;;; Commentary:
;;
;; This is a small library to talk to Kaleidoscope-powered devices - such as the
;; Keyboardio Model 01 - from within Emacs. It provides low-level functions that
;; aid in communication.
;;
;;; License: GPLv3+

;;; Code:

;;;; Settings

(defgroup kaleidoscope nil
  "Customization group for 'kaleidoscope'."
  :group 'comm)

(defcustom kaleidoscope-device-port "/dev/ttyACM0"
  "Serial port the device is connected to."
  :group 'kaleidoscope
  :type 'string)

;;;; Helpers

(defun kaleidoscope-send-command (command &optional args)
  "Send a COMMAND with (optional) arguments ARGS to the device.
The command must be a keyword, and the arguments a pre-formatted
string."
  (process-send-string "kaleidoscope"
                       (s-join " "
                               (list (s-chop-prefix ":" (s-replace "/" "." (symbol-name command)))
                                     (format "%s" args) "\n"))))

(defun kaleidoscope-color-to-rgb (color)
  "Convert a COLOR name or hexadecimal RGB representation to a string."
  (mapconcat (lambda (c) (format "%d" (round (* 255 c))))
             (color-name-to-rgb color)
             " "))

;;;; Main entry point

;;;###autoload
(defun kaleidoscope-start ()
  "Connect to the device on 'kaleidoscope-device-port'."
  (interactive)

  (make-serial-process :port kaleidoscope-device-port
                       :speed 9600
                       :name "kaleidoscope"
                       :buffer "*kaleidoscope*"))

;;;###autoload
(defun kaleidoscope-quit ()
  "Disconnect from the device."
  (interactive)

  (delete-process "kaleidoscope")
  (kill-buffer "*kaleidoscope*"))

(provide 'kaleidoscope)

;;; kaleidoscope.el ends here
