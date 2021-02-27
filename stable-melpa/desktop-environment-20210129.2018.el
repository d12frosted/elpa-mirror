;;; desktop-environment.el --- Helps you control your GNU/Linux computer  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Damien Cassou

;; Author: Damien Cassou <damien@cassou.me>, Nicolas Petton <nicolas@petton.fr>
;; Url: https://gitlab.petton.fr/DamienCassou/desktop-environment
;; Package-requires: ((emacs "25.1"))
;; Version: 0.5.0

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

;; This package helps you control your GNU/Linux desktop from Emacs.
;; With desktop-environment, you can control the brightness and volume
;; as well as take screenshots and lock your screen.  The package
;; depends on the availability of shell commands to do the hard work
;; for us.  These commands can be changed by customizing the
;; appropriate variables.

;; The global minor mode `desktop-environment-mode' binds standard
;; keys to provided commands: e.g., <XF86AudioRaiseVolume> to raise
;; the volume, <print> to take a screenshot, and <s-l> to lock the
;; screen.

;;; Code:

(require 'dbus)

(defgroup desktop-environment nil
  "Configure desktop-environment."
  :group 'environment)


;;; Customization - keyboard backlight
(defcustom desktop-environment-keyboard-backlight-normal-increment 1
  "Normal keyboard increment value."
  :type 'integer)

(defcustom desktop-environment-keyboard-backlight-normal-decrement -1
  "Normal keyboard decrement value."
  :type 'integer)


;;; Customization - brightness

(defcustom desktop-environment-brightness-normal-increment "10%+"
  "Normal brightness increment value."
  :type 'string)

(defcustom desktop-environment-brightness-normal-decrement "10%-"
  "Normal brightness decrement value."
  :type 'string)

(defcustom desktop-environment-brightness-small-increment "5%+"
  "Small brightness increment value."
  :type 'string)

(defcustom desktop-environment-brightness-small-decrement "5%-"
  "Small brightness decrement value."
  :type 'string)

(defcustom desktop-environment-brightness-get-command "brightnessctl"
  "Shell command getting current screen brightness level.
If you change this variable, you might want to change
`desktop-environment-brightness-get-regexp' as well."
  :type 'string)

(defcustom desktop-environment-brightness-get-regexp "\\([0-9]+%\\)"
  "Regular expression matching brightness value.

This regular expression will be tested against the result of
`desktop-environment-brightness-get-command' and group 1 must
match the current brightness level."
  :type 'regexp)

(defcustom desktop-environment-brightness-set-command "brightnessctl set %s"
  "Shell command setting the brightness level.
The value must contain 1 occurrence of '%s' that will be
replaced by the desired new brightness level."
  :type 'string)


;;; Customization - volume

(defcustom desktop-environment-volume-normal-increment "5%+"
  "Normal volume increment value."
  :type 'string)

(defcustom desktop-environment-volume-normal-decrement "5%-"
  "Normal volume decrement value."
  :type 'string)

(defcustom desktop-environment-volume-small-increment "1%+"
  "Small volume increment value."
  :type 'string)

(defcustom desktop-environment-volume-small-decrement "1%-"
  "Small volume decrement value."
  :type 'string)

(defcustom desktop-environment-volume-get-command "amixer get Master"
  "Shell command getting current volume level.
If you change this variable, you might want to change
`desktop-environment-volume-get-regexp' as well."
  :type 'string)

(defcustom desktop-environment-volume-get-regexp "\\([0-9]+%\\)"
  "Regular expression matching volume value.

This regular expression will be tested against the result of
`desktop-environment-volume-get-command' and group 1 must
match the current volume level."
  :type 'regexp)

(defcustom desktop-environment-volume-set-command "amixer set Master %s"
  "Shell command setting the volume level.
The value must contain 1 occurrence of '%s' that will be
replaced by the desired new volume level."
  :type 'string)

(defcustom desktop-environment-volume-toggle-command "amixer set Master toggle"
  "Shell command toggling between muted and working."
  :type 'string)

(defcustom desktop-environment-volume-toggle-microphone-command "amixer set Capture toggle"
  "Shell command toggling microphone between muted and working."
  :type 'string)


;;; Customization - screenshots

(defcustom desktop-environment-screenshot-command "scrot"
  "Shell command taking a screenshot in the current working directory.

In order to support taking delayed screenshots, ensure that the
argument specified in `desktop-environment-screenshot-delay-argument' is
compatible with this command."
  :type 'string)

(defcustom desktop-environment-screenshot-partial-command "scrot -s"
  "Shell command taking a partial screenshot in the current working directory.

The shell command should let the user interactively select the
portion of the screen.

In order to support taking delayed screenshots, ensure that the
argument specified in `desktop-environment-screenshot-delay-argument'
is compatible with this command."
  :type 'string)

(defcustom desktop-environment-screenshot-delay-argument "--delay %d"
  "Argument to append to the screenshot shell command to delay the screenshot.

When one of the screenshot
functions (`desktop-environment-screenshot' or
`desktop-environment-screenshot-part') is called with a positive
integer as its first (prefix) argument, this string will be
appended to either `desktop-environment-screenshot-command' or
`desktop-environment-screenshot-partial-command' respectively,
replacing the placeholder %d with the prefix argument."
  :type 'string)

(defcustom desktop-environment-screenshot-directory "~/Pictures"
  "Directory where to save screenshots."
  :type 'directory)


;;; Customization - screen locking

(defcustom desktop-environment-screenlock-command "slock"
  "Shell command locking the screen."
  :type 'string)


;;; Customization - wifi

(defcustom desktop-environment-wifi-command "wifi toggle"
  "Shell command toggling WiFi."
  :type 'string)

;;; Customization - bluetooth

(defcustom desktop-environment-bluetooth-command "bluetooth toggle"
  "Shell command toggling Bluetooth."
  :type 'string)


;;; Customization - music

(defcustom desktop-environment-music-toggle-command "playerctl play-pause"
  "Shell command toggling the music player."
  :type 'string)

(defcustom desktop-environment-music-previous-command "playerctl previous"
  "Shell command for going to previous song."
  :type 'string)

(defcustom desktop-environment-music-next-command "playerctl next"
  "Shell command for going to next song."
  :type 'string)

(defcustom desktop-environment-music-stop-command "playerctl stop"
  "Shell command for stopping the music player instance."
  :type 'string)


;;; Customization - EXWM keybindings

(defcustom desktop-environment-update-exwm-global-keys :global
  "Determines interacting with EXWM bindings when enabling/disabling the mode."
  :type '(radio
          (const :tag "Global" :doc "Use `exwm-input-set-key' on mode activation to set bindings." :global)
          (const :tag "Prefix" :doc "Add/Remove keys to `exwm-input-prefix-keys' when enabling/disabling the mode." :prefix)
          (const :tag "Off" :doc "Do not touch EXWM key bindings." nil)))

;;; Helper functions - desktop-environment--shell-command-to-string

(defun desktop-environment--shell-command-to-string (command)
  "Execute shell command COMMAND locally and return its output as a string."
   (let ((default-directory temporary-file-directory))
      (shell-command-to-string command)))

;;; Helper functions - brightness

(defun desktop-environment-brightness-get ()
  "Return a string representing current brightness level."
  (let ((output (desktop-environment--shell-command-to-string desktop-environment-brightness-get-command)))
    (save-match-data
      (string-match desktop-environment-brightness-get-regexp output)
      (match-string 1 output))))

(defun desktop-environment-brightness-set (value)
  "Set brightness to VALUE."
  (desktop-environment--shell-command-to-string (format desktop-environment-brightness-set-command value))
  (message "New brightness value: %s" (desktop-environment-brightness-get)))


;;; Helper functions - volume

(defun desktop-environment-volume-get ()
  "Return a string representing current volume level."
  (let ((output (desktop-environment--shell-command-to-string desktop-environment-volume-get-command)))
    (save-match-data
      (string-match desktop-environment-volume-get-regexp output)
      (match-string 1 output))))

(defun desktop-environment-volume-set (value)
  "Set volume to VALUE."
  (desktop-environment--shell-command-to-string (format desktop-environment-volume-set-command value))
  (message "New volume value: %s" (desktop-environment-volume-get)))


;;; Helper functions - keyboard backlight
(defun desktop-environment-keyboard-backlight-percent ()
  "Return the new keyboard backlight value as a % of maximum backlight."
  (let ((backlight-level (desktop-environment-keyboard-backlight-get)))
    (if (eq backlight-level 0)
        "0.0"
      (*
       (/ (* backlight-level 1.0)
          (* (desktop-environment-keyboard-backlight-get-max) 1.0))
       100))))

(defun desktop-environment-keyboard-backlight-get ()
  "Return a number representing keyboard backlight current level."
  (dbus-call-method :system
                    "org.freedesktop.UPower"
                    "/org/freedesktop/UPower/KbdBacklight"
                    "org.freedesktop.UPower.KbdBacklight"
                    "GetBrightness"))

(defun desktop-environment-keyboard-backlight-get-max ()
  "Return a number representing keyboard backlight maximum level."
  (dbus-call-method :system
                    "org.freedesktop.UPower"
                    "/org/freedesktop/UPower/KbdBacklight"
                    "org.freedesktop.UPower.KbdBacklight"
                    "GetMaxBrightness"))

(defun desktop-environment-keyboard-backlight-set (value)
  "Set keyboard backlight to VALUE."
  (dbus-call-method :system
                    "org.freedesktop.UPower"
                    "/org/freedesktop/UPower/KbdBacklight"
                    "org.freedesktop.UPower.KbdBacklight"
                    "SetBrightness"
                    :int32 value)
  (message "New keyboard value: %s%%" (desktop-environment-keyboard-backlight-percent)))


;;; Commands - brightness

;;;###autoload
(defun desktop-environment-brightness-increment ()
  "Increment brightness by `desktop-environment-brightness-normal-increment'."
  (interactive)
  (desktop-environment-brightness-set desktop-environment-brightness-normal-increment))

;;;###autoload
(defun desktop-environment-brightness-decrement ()
  "Decrement brightness by `desktop-environment-brightness-normal-decrement'."
  (interactive)
  (desktop-environment-brightness-set desktop-environment-brightness-normal-decrement))

;;;###autoload
(defun desktop-environment-brightness-increment-slowly ()
  "Increment brightness by `desktop-environment-brightness-small-increment'."
  (interactive)
  (desktop-environment-brightness-set desktop-environment-brightness-small-increment))

;;;###autoload
(defun desktop-environment-brightness-decrement-slowly ()
  "Decrement brightness by `desktop-environment-brightness-small-decrement'."
  (interactive)
  (desktop-environment-brightness-set desktop-environment-brightness-small-decrement))


;;; Commands - volume

;;;###autoload
(defun desktop-environment-volume-increment ()
  "Increment volume by `desktop-environment-volume-normal-increment'."
  (interactive)
  (desktop-environment-volume-set desktop-environment-volume-normal-increment))

;;;###autoload
(defun desktop-environment-volume-decrement ()
  "Decrement volume by `desktop-environment-volume-normal-decrement'."
  (interactive)
  (desktop-environment-volume-set desktop-environment-volume-normal-decrement))

;;;###autoload
(defun desktop-environment-volume-increment-slowly ()
  "Increment volume by `desktop-environment-volume-small-increment'."
  (interactive)
  (desktop-environment-volume-set desktop-environment-volume-small-increment))

;;;###autoload
(defun desktop-environment-volume-decrement-slowly ()
  "Decrement volume by `desktop-environment-volume-small-decrement'."
  (interactive)
  (desktop-environment-volume-set desktop-environment-volume-small-decrement))

;;;###autoload
(defun desktop-environment-toggle-mute ()
  "Toggle between muted and un-muted."
  (interactive)
  (message "%s"
           (desktop-environment--shell-command-to-string desktop-environment-volume-toggle-command)))

;;;###autoload
(defun desktop-environment-toggle-microphone-mute ()
  "Toggle microphone between muted and un-muted."
  (interactive)
  (message "%s"
           (desktop-environment--shell-command-to-string desktop-environment-volume-toggle-microphone-command)))


;;; Commands - keyboard backlight
;;;###autoload
(defun desktop-environment-keyboard-backlight-increment ()
  "Increment keyboard backlight by `desktop-environment-keyboard-backlight-normal-increment'."
  (interactive)
  (desktop-environment-keyboard-backlight-set
   (+ desktop-environment-keyboard-backlight-normal-increment
      (desktop-environment-keyboard-backlight-get))))

(defun desktop-environment-keyboard-backlight-decrement ()
  "Decrement keyboard backlight by `desktop-environment-keyboard-backlight-normal-decrement'."
  (interactive)
  (desktop-environment-keyboard-backlight-set
   (+ desktop-environment-keyboard-backlight-normal-decrement
      (desktop-environment-keyboard-backlight-get))))


;;; Commands - screenshots

;;;###autoload
(defun desktop-environment-screenshot (&optional delay)
  "Take a screenshot of the screen.

Screenshots are stored in the directory
`desktop-environment-screenshot-directory'.

When DELAY is a positive integer, delay taking the screenshot by
DELAY seconds.  When the function is called interactively, DELAY
is the provided prefix argument.

In order to delay the screenshot,
`desktop-environment-screenshot-delay-argument' is appended to
the command `desktop-environment-screenshot-command'."
  (interactive "P")
  (let ((default-directory (expand-file-name desktop-environment-screenshot-directory))
        (command (if (and delay
                          (numberp delay)
                          (> delay 0))
                     (concat desktop-environment-screenshot-command
                             " "
                             (format desktop-environment-screenshot-delay-argument delay))
                   desktop-environment-screenshot-command)))
    (start-process-shell-command "desktop-environment-screenshot" nil command)))

;;;###autoload
(defun desktop-environment-screenshot-part (&optional delay)
  "Take a screenshot of part of the screen.

Screenshots are stored in the directory
`desktop-environment-screenshot-directory'.

The command asks the user to interactively select a portion of
the screen.

When DELAY is a positive integer, delay taking the screenshot by
DELAY seconds.  When the function is called interactively, DELAY
is the provided prefix argument.

In order to delay the screenshot,
`desktop-environment-screenshot-delay-argument' is appended to
the command `desktop-environment-screenshot-partial-command'."
  (interactive "P")
  (let ((default-directory (expand-file-name desktop-environment-screenshot-directory))
        (command (if (and delay
                          (numberp delay)
                          (> delay 0))
                     (concat desktop-environment-screenshot-partial-command
                             " "
                             (format desktop-environment-screenshot-delay-argument delay))
                   desktop-environment-screenshot-partial-command)))
    (message "Please select the part of your screen to shoot.")
    (start-process-shell-command "desktop-environment-screenshot" nil command)))


;;; Commands - screen locking

;;;###autoload
(defun desktop-environment-lock-screen ()
  "Lock the screen, preventing anyone without a password from using the system."
  (interactive)
  ;; Run command asynchronously so that Emacs does not wait in the background.
  (start-process-shell-command "lock" nil desktop-environment-screenlock-command))


;;; Commands - wifi

;;;###autoload
(defun desktop-environment-toggle-wifi ()
  "Toggle WiFi adapter on and off."
  (interactive)
  (let ((async-shell-command-buffer 'new-buffer))
    (async-shell-command desktop-environment-wifi-command)))

;;; Commands - bluetooth

;;;###autoload
(defun desktop-environment-toggle-bluetooth ()
  "Toggle Bluetooth on and off."
  (interactive)
  (let ((async-shell-command-buffer 'new-buffer))
    (async-shell-command desktop-environment-bluetooth-command)))


;;; Commands - music

(defun desktop-environment-toggle-music ()
  "Play/pause the music player."
  (interactive)
  (message "%s"
           (desktop-environment--shell-command-to-string desktop-environment-music-toggle-command)))

(defun desktop-environment-music-previous ()
  "Play the previous song."
  (interactive)
  (message "%s"
           (desktop-environment--shell-command-to-string desktop-environment-music-previous-command)))

(defun desktop-environment-music-next()
  "Play the next song."
  (interactive)
  (message "%s"
           (desktop-environment--shell-command-to-string desktop-environment-music-next-command)))

(defun desktop-environment-music-stop ()
  "Stop music player instance."
  (interactive)
  (message "%s"
           (desktop-environment--shell-command-to-string desktop-environment-music-stop-command)))

;;; Minor mode

(defvar desktop-environment-mode-map
  (let ((desktop-environment--keybindings
         `(;; Brightness
           (,(kbd "<XF86MonBrightnessUp>") . ,(function desktop-environment-brightness-increment))
           (,(kbd "<XF86MonBrightnessDown>") . ,(function desktop-environment-brightness-decrement))
           (,(kbd "S-<XF86MonBrightnessUp>") . ,(function desktop-environment-brightness-increment-slowly))
           (,(kbd "S-<XF86MonBrightnessDown>") . ,(function desktop-environment-brightness-decrement-slowly))
           ;; Volume
           (,(kbd "<XF86AudioRaiseVolume>") . ,(function desktop-environment-volume-increment))
           (,(kbd "<XF86AudioLowerVolume>") . ,(function desktop-environment-volume-decrement))
           (,(kbd "S-<XF86AudioRaiseVolume>") . ,(function desktop-environment-volume-increment-slowly))
           (,(kbd "S-<XF86AudioLowerVolume>") . ,(function desktop-environment-volume-decrement-slowly))
           (,(kbd "<XF86AudioMute>") . ,(function desktop-environment-toggle-mute))
           (,(kbd "<XF86AudioMicMute>") . ,(function desktop-environment-toggle-microphone-mute))
           ;; Screenshot
           (,(kbd "S-<print>") . ,(function desktop-environment-screenshot-part))
           (,(kbd "<print>") . ,(function desktop-environment-screenshot))
           ;; Screen locking
           (,(kbd "s-l") . ,(function desktop-environment-lock-screen))
           (,(kbd "<XF86ScreenSaver>") . ,(function desktop-environment-lock-screen))
           ;; Wifi controls
           (,(kbd "<XF86WLAN>") . ,(function desktop-environment-toggle-wifi))
           ;; Bluetooth controls
           (,(kbd "<XF86Bluetooth>") . ,(function desktop-environment-toggle-bluetooth))
           ;; Music controls
           (,(kbd "<XF86AudioPlay>") . ,(function desktop-environment-toggle-music))
           (,(kbd "<XF86AudioPrev>") . ,(function desktop-environment-music-previous))
           (,(kbd "<XF86AudioNext>") . ,(function desktop-environment-music-next))
           (,(kbd "<XF86AudioStop>") . ,(function desktop-environment-music-stop))))
        (map (make-sparse-keymap)))
    (dolist (keybinding desktop-environment--keybindings)
      (define-key map (car keybinding) (cdr keybinding)))
    map)
  "Keymap for `desktop-environment-mode'.")

(declare-function exwm-input-set-key "ext:exwm-input")

(defun desktop-environment-exwm-set-global-keybindings (enable)
  "When using EXWM, add `desktop-environment-mode-map' to global keys.

When ENABLE is non-nil, the bindings will be installed depending
on the value of `desktop-environment-update-exwm-global-keys'.
If set to `:prefix', the bindings will be disabled when ENABLE is
nil."
  (when (featurep 'exwm-input)
    (cl-case desktop-environment-update-exwm-global-keys
      (:global
       (when enable
         (map-keymap (lambda (event definition)
                       (exwm-input-set-key (vector event) definition))
                     desktop-environment-mode-map)))
      (:prefix
       (when (boundp 'exwm-input-prefix-keys)
         (map-keymap (lambda (event definition)
                       (ignore definition)
                       (setq exwm-input-prefix-keys (if enable
                                                        (cons event exwm-input-prefix-keys)
                                                      (delq event exwm-input-prefix-keys))))
                     desktop-environment-mode-map)))
      ((nil) nil)
      (t
       (message "Ignoring unknown value %s for `desktop-environment-update-exwm-global-keys'"
                desktop-environment-update-exwm-global-keys)))))

;;;###autoload
(define-minor-mode desktop-environment-mode
  "Activate keybindings to control your desktop environment.

\\{desktop-environment-mode-map}"
  :global t
  :require 'desktop-environment
  :lighter " DE"
  (desktop-environment-exwm-set-global-keybindings desktop-environment-mode))

(provide 'desktop-environment)
;;; desktop-environment.el ends here

; LocalWords:  backlight
