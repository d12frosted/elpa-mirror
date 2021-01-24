;;; aqi.el --- Air quality data from the World Air Quality Index -*- lexical-binding: t; -*-

;; Copyright 2020 FoAM
;;
;; Author: nik gaffney <nik@fo.am>
;; Created: 2020-02-02
;; Version: 0.1
;; Package-Version: 20200215.1334
;; Package-Commit: c107a2e21cd1ac6008d8baaeeedb3fab26583d45
;; Package-Requires: ((emacs "25.1") (request "0.3") (let-alist "0.0"))
;; Keywords: air quality, AQI, pollution, weather, data
;; URL: https://github.com/zzkt/aqi

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

;; View air quality data from the World Air Quality Index.
;;
;; The simplest way to view AQI info is with 'M-x aqi-report' which
;; displays air quality info for your algorithmically derived location
;; (equivalent to the location "here") or the name of a place.  A place
;; can be the name of a city (in which case the nearest monitoring
;; station is used) or the name of specific monitoring station.
;;
;; To use the data programmatically, the functions 'aqi-report-full'
;; and 'aqi-report-brief' return the report as a string.  The function
;; 'aqi-city-aqi' will return the AQI for a given city as a number.


;;; Code:

(require 'request)
(require 'let-alist)

(defgroup aqi nil
  "Fetch and display air quality data from WAQI."
  :prefix "aqi-"
  :group 'external)

(defcustom aqi-api-key "demo"
  "A valid API key from http://aqicn.org/data-platform/token/ to access WAQI."
  :type 'string)

;; Data from WAQI can be cached, since it's usually refreshed hourly.

(defcustom aqi-use-cache nil
  "When set to 't' will use cached data, otherwise get new data on each call."
  :type 'boolean)

(defcustom aqi-cache-refresh-period 0
  "Cached data can be refreshed at a given interval (in minutes) or 'nil' to never refresh."
  :type 'number)

(defvar aqi-cached-data '(("None" . "None"))
  "Data is cached as an alist of city names and results.")


(defun aqi--city-cache-clear (&optional city)
  "Clear the cached data, optionally only for a given CITY."
  (if city
      (setq aqi-cached-data
            (assq-delete-all city aqi-cached-data))
    (setq aqi-cached-data '(("None" . "None")))))

(defun aqi--city-cache-update (city)
  "Add or update cached data for a given CITY."
  (aqi--city-cache-clear city)
  (push (cons city (aqi-request city))
        aqi-cached-data))

(defun aqi--city-cache-get (city)
  "Add or update cached data for a given CITY."
  (unless (aqi--cached-city? city)
    (aqi--city-cache-update city))
  (assoc-default city aqi-cached-data))

(defun aqi--cached-city? (city)
  "Return 't' if AQI data from CITY has been cached."
  (if (assoc-default city aqi-cached-data) t nil))


;; data munging

(defmacro aqi--make-city-raw-accessor (name aref)
  "Macro to create an accesor NAME with a 'let-alist' AREF (or function)."
  `(fset ,name
         (lambda (city)
           (aqi-request city)
           (let-alist (assoc-default city aqi-cached-data) ,aref))))

(defmacro aqi--make-city-format-accessor (name aref)
  "Macro to create an accesor NAME with a 'let-alist' AREF (or function)."
  `(fset ,name
         (lambda (city)
           (aqi-request city)
           (format "%s" (let-alist (assoc-default city aqi-cached-data) ,aref)))))

;; various accessors (added as needed...)

;; Function to return the AQI for a city (by name) as a number
(aqi--make-city-raw-accessor 'aqi-city-aqi .aqi)

;; Function to return the coordinates of a city (by name) as a string
(aqi--make-city-format-accessor 'aqi-city-lonlat
                                (format "%s, %s" (elt .city.geo 0) (elt .city.geo 1)))


;; API requests for AQI info

(defun aqi-request (city)
  "Request details for CITY from WAQI."
  (request
    (format "https://api.waqi.info/feed/%s/" city)
    :sync t
    :params `(("token" . ,aqi-api-key))
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (pcase (assoc-default 'status data)
                  ("ok" (push (cons city (assoc-default 'data data))
                              aqi-cached-data))
                  ("error" (push (cons city (format "Request error: %s" (assoc-default 'data data)))
                                 aqi-cached-data)))))
    :error (cl-function
            (lambda (&rest args &key error-thrown &allow-other-keys)
              (message "WAQI error: %s" error-thrown)))))

(defun aqi-request-geo (latitude longitude)
  "Request details by LATITUDE and LONGITUDE from WAQI."
  (request
    (format "https://api.waqi.info/feed/geo:%s;%s/" latitude longitude)
    :sync t
    :params `(("token" . ,aqi-api-key))
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (message "200: %s" data)))
    :error (cl-function
            (lambda (&rest args &key error-thrown &allow-other-keys)
              (message "WAQI error: %s" error-thrown)))))

(defun aqi-request-cached (city)
  "Request details for CITY from cached data or direct from WAQI."
  (if (aqi--cached-city? city)
      (aqi--city-cache-get city)
    (aqi-request city)))

(defun aqi-search (name)
  "Search for the nearest stations (if any) matching a given NAME."
  (request
    (format "https://api.waqi.info/search/?keyword=%s&" name)
    :sync t
    :params `(("token" . ,aqi-api-key))
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (pcase (assoc-default 'status data)
                  ("ok" (message "Search: %s" (assoc-default 'data data)))
                  ("error" (message "Search error: %s" (assoc-default 'data data))))))
    :error (cl-function
            (lambda (&rest args &key error-thrown &allow-other-keys)
              (message "WAQI error: %s" error-thrown)))))

;; printing, formatting and presenting.

;;;###autoload
(defun aqi-report-brief (&optional place)
  "General air quality info from PLACE as a string."
  (let ((city (if (and (string< "" place) place) place "here")))
    (if aqi-use-cache
        (aqi-request-cached city)
      (aqi-request city))
    (let-alist (aqi--city-cache-get city)
      (format "Air Quality Index in %s is %s and the dominant pollutant is %s%s"
              .city.name .aqi .dominentpol
              (if aqi-use-cache " (cached)" "")))))

;;;###autoload
(defun aqi-report-full (&optional place)
  "Detailed air quality info from PLACE as a string."
  (let ((city (if (and (string< "" place) place) place "here")))
    (if aqi-use-cache
        (aqi-request-cached city)
      (aqi-request city))
    (let ((data (aqi--city-cache-get city)))
      ;; simple typecheck -> error handling since semantic errors are cached as strings.
      (if (stringp data)
          (format "%s (%s)" data city)
        (let-alist data
          (format
           "Air Quality index in %s is %s as of %s (UTC%s).
\nDominant pollutant is %s
PM2.5 (fine particulate matter): %s
PM10 (respirable particulate matter): %s
NO2 (Nitrogen Dioxide): %s
CO (Carbon Monoxide): %s
\nTemperature (Celsius): %s
Humidity: %s
Air pressure: %s
Wind: %s
\nFurther details can be found at %s
\nData provided by %s and %s%s"
           .city.name
           .aqi
           .time.s
           .time.tz
           .dominentpol
           .iaqi.pm25.v
           .iaqi.pm10.v
           .iaqi.no2.v
           .iaqi.co.v
           .iaqi.t.v
           .iaqi.h.v
           .iaqi.p.v
           .iaqi.wg.v
           .city.url
           (let-alist (elt .attributions 0) .name)
           (let-alist (elt .attributions 1) .name)
           (if aqi-use-cache " (cached)" "")))))))

;;;###autoload
(defun aqi-report (&optional place type)
  "General air quality info from PLACE (or 'here' if no args are given) report TYPE can be 'brief' or 'full'."
  (interactive "sName of city or monitoring station (RET for \"here\"): ")
  (let* ((city (if (and (string< "" place) place) place "here"))
         (aqi-output (get-buffer-create (format "*Air Quality - %s*" city))))
    (with-current-buffer aqi-output
      (goto-char (point-min))
      (erase-buffer)
      (pcase type
        ('brief (insert (aqi-report-brief city)))
        ('full (insert (aqi-report-full city)))
        ('nil (insert (aqi-report-full city)))
        (other (warn "Unknown report type: '%s. Try using 'full or 'brief" other)))
      (goto-char (point-max))
      (insert ""))
    (display-buffer aqi-output))
  t)

(provide 'aqi)

;;; aqi.el ends here
