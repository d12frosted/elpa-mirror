;;; display-wttr.el --- Display wttr(weather) in the mode line -*- lexical-binding: t -*-

;; Copyright (C) 2022 Jose G Perez Taveras <josegpt27@gmail.com>

;; Author: Jose G Perez Taveras <josegpt27@gmail.com>
;; Maintainer: Jose G Perez Taveras <josegpt27@gmail.com>
;; Version: 2.1.0
;; Package-Requires: ((emacs "27.1"))
;; URL: https://github.com/josegpt/display-wttr
;; SPDX-License-Identifier: GPL-3.0-only

;;; Commentary:

;; Display-wttr package contains a minor mode that can be toggled
;; on/off.  It fetches weather information based on your
;; location or a location set in `display-wttr-locations' from
;; `https://wttr.in' and then displays it on the mode line.  The entry
;; point is`display-wttr'.

;; Heavily inspired by: `display-time'.

;;; Code:

(require 'subr-x)

(defgroup display-wttr nil
  "Display wttr(weather) in the mode line."
  :prefix "display-wttr-"
  :group 'mode-line)

(defcustom display-wttr-locations '("")
  "Display wttr location supports any combination of the `one-line output'.

Valid format values:
  Cities:
    Empty*
    Nuremberg
    Salt+Lake+City
    Nuremberg:Hamburg:Berlin
    {Nuremberg,Hamburg,Berlin}

  3-letter airport codes:
    muc
    ham
    ewr
  ~:
    ~Vostok+Station
    ~Eiffel+Tower
    ~Kilimanjaro
  @:
    @github.com
    @msu.ru

  (*If you omit the location name, you will get the report for
  your current location based on your IP address.)

  (~Add the character ~ before the name to look up that special
  location name before the weather is then retrieved:)

  (@IP-addresses (direct) or domain names (prefixed with @) to
  specify a location)

For more information on how to specify locations make sure to
check: `https://github.com/chubin/wttr.in#one-line-output'"
  :type 'list)

(defcustom display-wttr-format "4"
  "Format to be passed to wttr.
Display wttr format supports any option from thw `one-line
output' of `https://wttr.in'

Valid format values:
  Predefined format options:
    1
    2
    3
    4

  Custom format options:
    c Weather condition
    C Weather condition textual name
    x Weather condition, plain-text symbol
    h Humidity
    t Temperature (Actual)
    f Temperature (Feels Like)
    w Wind
    l Location
    m Moon phase 🌑🌒🌓🌔🌕🌖🌗🌘
    M Moon day
    p Precipitation (mm/3 hours)
    P Pressure (hPa)
    D Dawn*
    S Sunrise*
    z Zenith*
    s Sunset*
    d Dusk*
    T Current time*
    Z Local timezone.
    (*times are shown in the local timezone)

Examples:
  1: ☀️ +28°F
  2: ☀️ 🌡️+28°F 🌬️→7mph
  3: New York, New York, United States: ☀️ +28°F
  4: New York, New York, United States: ☀️ 🌡️+28°F 🌬️→7mph
  %l:+%c+%t: New York, New York, United States: ☀️ +28°F
  %C:+%t+%f+%w: Sunny: +28°F +28°F 0mph
For more information on the one-line output make sure to visit:
`https://github.com/chubin/wttr.in#one-line-output'"
  :type 'string)

(defcustom display-wttr-interval (* 60 60)
  "Seconds between updates of wttr in the mode line."
  :type 'integer)

(defcustom display-wttr-hook nil
  "List of functions to be called when the wttr is updated in the mode line."
  :type 'hook)

(defvar display-wttr-string nil
  "String used in mode line to display wttr string.
It should not be set directly, but is instead updated by the
`display-wttr' function.")
;;;###autoload(put 'display-wttr-string 'risky-local-variable t)

(defvar display-wttr-list nil
  "List of wttr unprocessed results.
This way a flash is avoided when updating `display-wttr-string'.
It should not be set directly, but is instead updated by the
`display-wttr' function.")
;;;###autoload(put 'display-wttr-list 'risky-local-variable t)

(defvar display-wttr-timer nil
  "Timer used by wttr.")
;;;###autoload(put 'display-wttr-timer 'risky-local-variable t)

(defun display-wttr--fetch-url (location)
  "Format uri for wttr to be used to fetch weather from `https://wttr.in'.
Argument LOCATION holds the location to construct the url."
  (format "https://wttr.in/%s?format=%s"
          location
          display-wttr-format))

(defun display-wttr--clean-string (string)
  "Encode to `utf-8' and remove all additional spaces from STRING."
  (decode-coding-string (string-join (split-string string) " ") 'utf-8))

(defun display-wttr--url-retrieve (location)
  "Create an asynchronous retrieval when it is done call `display-wttr-filter'.
Argument LOCATION holds the location to fetch info from."
  (url-retrieve
   (display-wttr--fetch-url location) #'display-wttr--filter nil t t))

(defun display-wttr--sentinel ()
  "Update `display-wttr-string' only when fetching all locations is finished."
  (when (= (length display-wttr-locations) (length display-wttr-list))
    (let ((wttr-string (string-join display-wttr-list " ")))
      (setq display-wttr-string
            (concat (unless (string-match (rx (: bol "Unknown location;"))
                                          wttr-string)
                      wttr-string)
                    " ")))
    (run-hooks 'display-wttr-hook)
    (force-mode-line-update 'all)))

(defun display-wttr--filter (status)
  "Update the `display-wttr' info in the mode line.
Argument STATUS status is a plist representing what happened
during the retrieval."
  (ignore status)
  (with-current-buffer (current-buffer)
    (goto-char (point-min))
    (re-search-forward "^$")
    (delete-region (1+ (point)) (point-min))
    (add-to-list 'display-wttr-list
                 (display-wttr--clean-string (buffer-string))))
  (display-wttr--sentinel))

(defun display-wttr-update-handler ()
  "Update wttr in mode line.
Calculates and sets up the timer for the next update of wttr with
the specified `display-wttr-interval'"
  (display-wttr-update)
  (let* ((current (current-time))
         (timer display-wttr-timer)
         (next-time (timer-relative-time
                     (list (aref timer 1) (aref timer 2) (aref timer 3))
                     (* 5 (aref timer 4)) 0)))
    (or (time-less-p current next-time)
        (progn
          (timer-set-time timer (timer-next-integral-multiple-of-time
                                 current display-wttr-interval)
                          (timer-activate timer))))))

(defun display-wttr-update ()
  "Create a new background process to update wttr string."
  (setq display-wttr-list nil)
  (dolist (location display-wttr-locations)
    (display-wttr--url-retrieve location)))

;;;###autoload
(defun display-wttr ()
  "Enable display of wttr in mode line.
This display updates automatically every hour.  This runs the
normal hook `display-wttr-hook' after each update."
  (interactive)
  (display-wttr-mode 1))

;;;###autoload
(define-minor-mode display-wttr-mode
  "Toggle display of wttr.
When Display Wttr mode is enabled, it updates every hour (you can
control the number of seconds between updates by customizing
`display-wttr-interval')."
  :global t
  :group 'display-wttr
  ;; Cancel timer if any is running
  (and display-wttr-timer (cancel-timer display-wttr-timer))
  (setq display-wttr-string "")
  (or global-mode-string (setq global-mode-string '("")))
  (when display-wttr-mode
    (or (memq 'display-wttr-string global-mode-string)
        (setq global-mode-string
              (append global-mode-string '(display-wttr-string))))
    ;; Set initial timer
    (setq display-wttr-timer
          (run-at-time t display-wttr-interval
                       #'display-wttr-update-handler))
    (display-wttr-update)))

(provide 'display-wttr)
;;; display-wttr.el ends here
