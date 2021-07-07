;;; theme-changer.el --- Sunrise/Sunset Theme Changer for Emacs

;; Copyright (C) 2011-2013 Joshua B. Griffith

;; Author: Joshua B. Griffith <josh.griffith@gmail.com>
;; Contributors: Joe Snikeris, Mike Fisher, Göktuğ Kayaalp
;; URL: https://github.com/hadronzoo/theme-changer
;; Package-Version: 20130726.212
;; Package-Commit: d3d9c9f62a138958262ac5dd61837df427268611
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
;; whether it is day or night. It will continue to change themes at
;; sunrise and sunset. To install:

;; Set the location:
;;     (setq calendar-location-name "Dallas, TX") 
;;     (setq calendar-latitude 32.85)
;;     (setq calendar-longitude -96.85)

;; Specify the day and night themes:
;;     (require 'theme-changer)
;;     (change-theme 'solarized-light 'solarized-dark)

;; One can also pass nil as either of parameters to change-theme, with the
;; effect of not using a theme (or using the default Emacs them) during that
;; period of the day. For example:

;;     (change-theme nil 'solarized-dark)

;; shall result in setting the default Emacs theme during the day, and
;; solarized-dark during the night.

;; You may need to add this file path to your loadpath. For example:
;;     (add-to-list 'load-path "~/.emacs.d/elisp/theme-changer")

;; If you want to use the color-theme package instead of the Emacs 24 color
;; theme facility:
;;     (setq theme-changer-mode "color-theme")
;;     (change-theme 'color-theme-solarized-light 'color-theme-solarized-dark)

;;; Code:

(require 'cl)
(require 'solar)

(defvar theme-changer-mode "deftheme"
  "Specify the theme change mode: \"color-theme\" or Emacs 24's
\"deftheme\".")

(defun hour-fraction-to-time (date hour-fraction)
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


(defun sunrise-sunset-times (date)
  (let*
      ((l (solar-sunrise-sunset date))
       (sunrise-time (hour-fraction-to-time date (caar l)))
       (sunset-time (hour-fraction-to-time date (caadr l))))
    (list sunrise-time sunset-time)))

(defun daytime-p (sunrise-time sunset-time)
  (let* ((now (current-time)))
    (and (time-less-p sunrise-time now)
	 (time-less-p now sunset-time))))

(defun today () (calendar-current-date))

(defun tomorrow ()
  (calendar-gregorian-from-absolute
   (+ 1 (calendar-absolute-from-gregorian (today)))))

(defun +second (time)
  (time-add time (seconds-to-time 1)))

(defun switch-theme (old new)
  "Change the theme from OLD to NEW, using Emacs 24's built-in
theme facility (\"deftheme\") or color-theme.

If NEW is set to nil, shall switch to default Emacs theme."
  (if (string= theme-changer-mode "deftheme")
      (progn
        (disable-theme old)
        (if new
            (load-theme new t)))
    (if new
        (apply (symbol-function new) '()))))

(defun change-theme (day-theme night-theme)
  (let*
      ((now (current-time))
       
       (today-times    (sunrise-sunset-times (today)))
       (tomorrow-times (sunrise-sunset-times (tomorrow)))
       
       (sunrise-today (first today-times))
       (sunset-today (second today-times))
       (sunrise-tomorrow (first tomorrow-times)))
    
    (if (daytime-p sunrise-today sunset-today)
	(progn
	  (switch-theme night-theme day-theme)
	  (run-at-time (+second sunset-today) nil
		       'change-theme day-theme night-theme))

      (switch-theme day-theme night-theme)
      (if (time-less-p now sunrise-today)
	  (run-at-time (+second sunrise-today) nil
		       'change-theme day-theme night-theme)
	(run-at-time (+second sunrise-tomorrow) nil
		     'change-theme day-theme night-theme)))))

(provide 'theme-changer)

;;; theme-changer.el ends here
