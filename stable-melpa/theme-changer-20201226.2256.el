;;; theme-changer.el --- Sunrise/Sunset Theme Changer for Emacs

;; Copyright (C) 2011-2013 Joshua B. Griffith

;; Author: Joshua B. Griffith <josh.griffith@gmail.com>
;; Contributors: Joe Snikeris, Mike Fisher, Göktuğ Kayaalp
;; URL: https://github.com/hadronzoo/theme-changer
;; Package-Version: 20201226.2256
;; Package-Commit: 57b8c579f134374a45bec9043feff6b29bb4f108
;; Created: 20 Jun 2011
;; Version: 2.1.0
;; Keywords: color-theme, deftheme, solar, sunrise, sunset

;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; Given a location and day/night color themes, this file provides a
;; `change-theme` function that selects the appropriate theme based on
;; whether it is day or night.  It will continue to change themes at
;; sunrise and sunset.  To install:

;; Set the location:
;;     (setq calendar-location-name "Dallas, TX")
;;     (setq calendar-latitude 32.85)
;;     (setq calendar-longitude -96.85)

;; Specify the day and night themes:
;;     (require 'theme-changer)
;;     (change-theme 'solarized-light 'solarized-dark)

;; If you specify a list of themes, a random one will be chosen at
;; each change:
;;     (change-theme '(solarized-light sanityinc-tomorrow-day)
;;                   '(solarized-dark sanityinc-tomorrow-night))

;; You can also pass nil as either of parameters to change-theme, with the
;; effect of not using a theme (or using the default Emacs theme) during that
;; period of the day.  For example:

;;     (change-theme nil 'solarized-dark)

;; will result in setting the default Emacs theme during the day, and
;; solarized-dark during the night.

;; You may need to add this file path to your loadpath.  For example:
;;     (add-to-list 'load-path "~/.emacs.d/elisp/theme-changer")

;; If you want to use the color-theme package instead of the Emacs 24 color
;; theme facility:
;;     (setq theme-changer-mode "color-theme")
;;     (change-theme 'color-theme-solarized-light 'color-theme-solarized-dark)

;;; Code:

(eval-when-compile
  (require 'cl))
(require 'solar)

(defvar theme-changer-mode "deftheme"
  "Specify the theme change mode: \"color-theme\" or Emacs 24's \"deftheme\".")

(defcustom theme-changer-delay-seconds 0
  "Specify the delay seconds when switch themes at sunrise and sunset."
  :type 'integer)

(defvar theme-changer-pre-change-functions (list)
  "Functions to run before changing themes.  Takes one argument of theme name being disabled.")

(defvar theme-changer-post-change-functions (list)
  "Functions to run after changing themes.  Takes one argument of theme name being enabled.")

(defun theme-changer-hour-fraction-to-time (date hour-fraction)
  (let*
      ((now (decode-time (current-time)))

       (month (first   date))
       (day   (second  date))
       (year  (third   date))
       (zone  (ninth   now))

       (frac-hour (cl-truncate hour-fraction))
       (hour (first frac-hour))

       (frac-minutes (cl-truncate (* (second frac-hour) 60)))
       (minute (first frac-minutes))

       (frac-seconds (cl-truncate (* (second frac-minutes) 60)))
       (sec (first frac-seconds)))
    (encode-time sec minute hour day month year zone)))


(defun theme-changer-sunrise-sunset-times (date)
  (let*
      ((l (solar-sunrise-sunset date))
       (sunrise-time (time-add (theme-changer-hour-fraction-to-time date (caar l))
                               (seconds-to-time theme-changer-delay-seconds)))
       (sunset-time (time-add (theme-changer-hour-fraction-to-time date (caadr l))
                              (seconds-to-time theme-changer-delay-seconds))))
    (when (> emacs-major-version 26)
      (setq sunrise-time (encode-time (decode-time sunrise-time)))
      (setq sunset-time (encode-time (decode-time sunset-time))))
    (list sunrise-time sunset-time)))

(defun theme-changer-today () (calendar-current-date))

(defun theme-changer-tomorrow ()
  (calendar-gregorian-from-absolute
   (+ 1 (calendar-absolute-from-gregorian (theme-changer-today)))))

(defun theme-changer-add-second (time)
  (let ((newtime (time-add time (seconds-to-time 1))))
    (if (> emacs-major-version 26)
        (encode-time (decode-time newtime))
      newtime)))

(defun theme-changer-switch-theme (old new)
  "Change the theme from OLD to NEW.

Uses Emacs 24's built-in theme facility (\"deftheme\") or
color-theme, depending on THEME-CHANGER-MODE.

NEW may be a list of themes, in which case a random theme is
chosen from that list.

If NEW is set to nil, shall switch to default Emacs theme.

Returns the theme that was enabled."
  (let ((new (if (listp new)
                 (elt new (random (length new)))
               new))
        (enable (if (not (string= theme-changer-mode "deftheme"))
                    (lambda () (apply (symbol-function new) '()))
                  (lambda () (load-theme new t)))))
    (run-hook-with-args 'theme-changer-pre-change-functions old)
    (disable-theme old)
    (if new (funcall enable))
    (run-hook-with-args 'theme-changer-post-change-functions new)
    new))

(defun change-theme (day-theme night-theme &optional old-theme)
  "Setup the DAY-THEME and NIGHT-THEME for time sensitive theme swapping.

Either or both may be a symbol or a list of symbols referencing
themes.  OLD-THEME specifies the theme prior to setting up
switching, if any."
  (let* ((now (current-time))
         (sunrise-tomorrow (first (theme-changer-sunrise-sunset-times
                                   (theme-changer-tomorrow)))))
    (destructuring-bind (sunrise-today sunset-today)
        (theme-changer-sunrise-sunset-times (theme-changer-today))
      (destructuring-bind (next-change . theme)
          (cond ((time-less-p now sunrise-today)
                 (cons sunrise-today night-theme))
                ((time-less-p now sunset-today)
                 (cons sunset-today day-theme))
                (t (cons sunrise-tomorrow night-theme)))
        (let ((old-theme (theme-changer-switch-theme old-theme theme)))
          (run-at-time (theme-changer-add-second next-change) nil
                       'change-theme day-theme night-theme old-theme))))))

(provide 'theme-changer)

;;; theme-changer.el ends here
