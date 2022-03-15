;;; display-wttr.el --- Display wttr(weather) in the mode line -*- lexical-binding: t -*-

;; Copyright (C) 2022 Jose G Perez Taveras <josegpt27@gmail.com>

;; Author: Jose G Perez Taveras <josegpt27@gmail.com>
;; Maintainer: Jose G Perez Taveras <josegpt27@gmail.com>
;; Version: 1.0.0
;; Package-Version: 20220314.1400
;; Package-Commit: ce097ffae30c2697bd037317338437bdea151fc0
;; Package-Requires: ((emacs "27.1"))
;; URL: https://github.com/josegpt/display-wttr
;; SPDX-License-Identifier: GPL-3.0-only

;;; Commentary:

;; Display-wttr package contains a minor mode that can be toggled
;; on/off.  It fetches weather information based on your
;; location or a location set in `display-wttr-location' from
;; `https://wttr.in' and then displays it on the mode line.  The entry
;; point is`display-wttr'.

;; Heavily inspired by: `display-time'.

;;; Code:

(require 'subr-x)

(defgroup display-wttr nil
  "Display wttr(weather) in the mode line."
  :prefix "display-wttr-"
  :group 'mode-line)

(defvar display-wttr-curl-executable (executable-find "curl")
  "Curl executable to be used by wttr to fetch information.")
;;;###autoload(put 'display-wttr-curl-executable 'risky-local-variable t)

(unless display-wttr-curl-executable
  (user-error "Display-wttr: curl must be installed"))

(defcustom display-wttr-curl-options "-s"
  "Options to be passed to the fetch executable used by wttr."
  :type 'string)

(defcustom display-wttr-location ""
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
  :type 'string)

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
    c Weather condition,
    C Weather condition textual name,
    x Weather condition, plain-text symbol,
    h Humidity,
    t Temperature (Actual),
    f Temperature (Feels Like),
    w Wind,
    l Location,
    m Moon phase 🌑🌒🌓🌔🌕🌖🌗🌘,
    M Moon day,
    p Precipitation (mm/3 hours),
    P Pressure (hPa),
    D Dawn*,
    S Sunrise*,
    z Zenith*,
    s Sunset*,
    d Dusk*,
    T Current time*,
    Z Local timezone.
    (*times are shown in the local timezone)

Examples:
  1: ☀️ +28°F
  2: ☀️ 🌡️+28°F 🌬️→7mph
  3: New York, New York, United States: ☀️ +28°F
  4: New York, New York, United States: ☀️ 🌡️+28°F 🌬️→7mph
  %l:+%c+%t\n: New York, New York, United States: ☀️ +28°F
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

(defun display-wttr-fetch-url ()
  "Format uri for wttr to be used to fetch weather from `https://wttr.in'."
  (format "https://wttr.in/%s?format=%s"
          display-wttr-location
          display-wttr-format))

(defun display-wttr-sentinel (process event)
  "Update `display-wttr-string' only when the fetcher is finished.
Argument PROCESS holds the process to which this function is
running.
Argument EVENT passes the status of the PROCESS."
  (ignore process)
  (when (string= "finished\n" event)
    (setq display-wttr-string
          (concat (string-join display-wttr-list " ") " "))
    (run-hooks 'display-wttr-hook))
  (force-mode-line-update 'all))

(defun display-wttr-filter (process string)
  "Update the `display-wttr' info in the mode line.
Argument PROCESS holds the process to which this function is
running.
Argument STRING holds each line of stdin or stderr of
the currently running process."
  (ignore process)
  (add-to-list 'display-wttr-list
               (string-join (split-string string) " ") t))

(defun display-wttr-update-handler ()
  "Update wttr in mode line.
Calcalutes and sets up the timer for the next update of wttr with
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
  (make-process
   :name "display-wttr"
   :command `("sh" "-c"
              ,(format "%s %s %s"
                       display-wttr-curl-executable
                       display-wttr-curl-options
                       (display-wttr-fetch-url)))
   :filter 'display-wttr-filter
   :sentinel 'display-wttr-sentinel ))

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
