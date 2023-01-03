;;; noaa.el --- Get NOAA weather data -*- lexical-binding: t -*-

;; Copyright (C) 2017 - 2022 David Thompson
;; Author: David Thompson
;; Version: 0.1
;; Keywords: calendar
;; Homepage: https://github.com/thomp/noaa
;; URL: https://github.com/thomp/noaa
;; Package-Requires: ((emacs "27.1") (kv "0.0.19") (request "0.2.0") (s "1.12.0"))

;;; Commentary:

;; This package provides a way to view an NOAA weather forecast for a
;; specific geographic location.

;; The API is publicly available, with examples:
;;   https://weather-gov.github.io/api/general-faqs
;;   https://www.ncdc.noaa.gov/cdo-web/webservices/v2#locationCategories


;;; Code:

(require 'cl-lib)
(require 'cl-extra)   ; cl-concatenate
(require 'json)
(require 'parse-time) ; parse-iso8601-time-string
(require 'request)
(require 's)          ; s-truncate
(require 'solar)      ; calendar-latitude, calendar-longitude
(require 'subr-x)     ; string-blank-p
(require 'url-http)   ; url-http-user-agent-string

(defgroup noaa ()
  "View an NOAA weather forecast for a specific geographic location."
  :group 'external)

(defcustom noaa-location (if (stringp calendar-location-name)
                           calendar-location-name
                          "Fresno, California")
  "A location descriptor for the default location of interest."
  :group 'noaa
  :type 'string)

(defcustom noaa-latitude (or calendar-latitude 36.7478)
  "The latitude for the default location of interest."
  :group 'noaa
  :type 'number)

(defcustom noaa-longitude (or calendar-longitude -119.771)
  "The latitude for the default location of interest."
  :group 'noaa
  :type 'number)

(defvar noaa-buffer-spec "*noaa.el*"
  "Buffer or buffer name.")

(defvar noaa-header-line
  (format "%%s (style: %%s) (%s)ext-style, (%s)ourly, (%s)aily, (%s)hange location, (%s)uit"
          (propertize "n" 'face 'bold)
          (propertize "h" 'face 'bold)
          (propertize "d" 'face 'bold)
          (propertize "c" 'face 'bold)
          (propertize "q" 'face 'bold))
  "Line to appear at top of `noaa-mode' buffers.
It should be appropriate as a first argument to function `format'
and account for two possible strings: location and display-style.")

(defvar-local noaa--daily-current-style 0
  "Index into variable `noa-daily-styles'.")

;; (defvar-local noaa-display-hourly-styles '(extended terse)
(defvar-local noaa--hourly-current-style 0
  "Index into variable `noa-hourly-styles'.")

(defface noaa-face-date '((t (:foreground "#30c2ba")))
  "Face used for date.")

(defface noaa-face-short-forecast '((t (:foreground "grey")))
  "Face used for short forecast text.")

(defface noaa-face-temp '((t (:foreground "#cfd400")))
  "Face used for temperature.")

;; Forecast data for a specified time range
(cl-defstruct noaa-forecast
  start-time
  end-time
  day-number
  detailed-forecast
  short-forecast
  name
  temp
  temp-trend
  temp-unit
  wind-speed
  wind-direction)

(defvar noaa-forecast-urls nil
  "Cache of forecast URLs based on the NOAA gridpoints API.")

;; FORECASTS is a list of noaa-forecast structs. TYPE is a keyword (e.g., :daily, :hourly) providing guidance on how to treat the forecasts in the FORECAST-SET slot.
(cl-defstruct noaa-forecast-set
  forecasts
  type)

(defvar noaa-last-forecast-set
  nil
  "A NOAA-FORECAST-SET struct describing the last forecast retrieved.")

(defvar noaa-last-forecast-raw
  nil
  "The server response associated with the last forecast request.")

(defvar noaa-last-response nil
  "Last response from the NOAA API.")

(defvar noaa--osm-api
  "https://nominatim.openstreetmap.org/search?q=%s&limit=1&format=json"
  "Query format to retreive latitude and longitude data.
This is a query to a server at `openstreetmap.org' that accepts a
single location string as a parameter.")

;;;###autoload
(defun noaa ()
  (interactive)
  (if current-prefix-arg
      (cl-multiple-value-bind (loc lat lon)
	  (noaa-prompt-user-for-location)
	(cond ((not loc)
	       (setq noaa-latitude  lat
		     noaa-longitude lon)
	       (setq noaa-location nil)	; Once responses from queries to points API are handled better, this should be set appropriately
	       (noaa--once-lat-lon-set lat lon))
	      (loc
	       (setq noaa-location loc)
	       (noaa-osm-query loc
			       (function noaa--osm-callback)))))
    (noaa--once-lat-lon-set noaa-latitude noaa-longitude)))
(defalias 'noaa-daily 'noaa "Retrieve and display the hourly forecast.")

(defvar noaa-api-weather-gov--status-map
  '(
    (404 . noaa--api-weather-gov--4nn-callback)
    (500 . (lambda (&rest x)
	     (message "%S" x)
	     (message "Got 500 -- the server seems unhappy")))
    (503 . (lambda (&rest x)
	     (message "%s" "Service Unavailable (503)")))
    )
  "Maps HTTP response status codes to callbacks")

(cl-defun noaa--api-weather-gov--4nn-callback
    (&key data error-thrown response symbol-status
	  &allow-other-keys)
  (let ((result (json-parse-string data :object-type 'alist :array-type 'list)))
    (setf noaa-last-response result)
    (let ((title (noaa-aval result 'title))
	  (detail (noaa-aval result 'detail)))
      (cond ((and title detail)
	     (message "%s" title)
	     (message "%s" detail))
	    (t
	     (noaa-http-error-callback :data data
				       :error-thrown error-thrown
				       :response response
				       :symbol-status symbol-status))))))

(defun noaa-new-location ()
  "Get weather for a different location.
Shortcut for M-x `noaa' with a prefix argument."
  (interactive)
  (setq current-prefix-arg t)
  (call-interactively 'noaa nil))

(defsubst noaa--four-digit-precision (num)
  "Return NUM, limited to four digit precision.
NUM is a string representation of a floating point number."
  (replace-regexp-in-string "\\.\\(....\\).*" ".\\1" num))

(cl-defun noaa--osm-callback (&key data _response _error-thrown &allow-other-keys)
  (unless data
    (error "No data returned from openstreetmap.org"))
  (let (lat
	lon
	(error-msg "Failed to retrieve coordinates from openstreetmap.org"))
    (condition-case nil
	(let ((result (car (json-parse-string data
					      :object-type 'alist
					      :array-type 'list))))
	  (setq lat
		(string-to-number (noaa--four-digit-precision (cdr (assq 'lat result)))))
	  (setq lon
		(string-to-number (noaa--four-digit-precision (cdr (assq 'lon result))))))
      (error
       (error error-msg)))
    (cond ((and lat lon)
	   (setq noaa-latitude  lat
		 noaa-longitude lon)
	   (noaa--once-lat-lon-set lat lon))
	  (t (error error-msg)))))

(defun noaa-aval (alist key)
  "Utility function to retrieve value associated with key KEY in alist ALIST."
  (let ((pair (assoc key alist)))
    (if pair
	(cdr pair)
      nil)))

(defun noaa-display-last-forecast ()
  "Clear the buffer and display the forecast described by the value of
NOAA-LAST-FORECAST-SET."
  (interactive)
  (let ((inhibit-read-only t))
    (erase-buffer)
    (cond ((eq (noaa-forecast-set-type noaa-last-forecast-set) :hourly)
  	   (noaa-display-as-hourly noaa-last-forecast-set))
  	  (t
  	   ;; if not hourly, assume daily
  	   (noaa-display-last-forecast-as-daily)))
    (goto-char (point-min))))

(defun noaa-display-last-forecast-as-daily ()
  "A helper function for NOAA-DISPLAY-LAST-FORECAST."
  (let (
	;; LAST-DAY-NUMBER is used for aesthetics --> separate data by day
	(last-day-number -1)
	(forecast-length (length (noaa-forecast-set-forecasts noaa-last-forecast-set))))
    (dotimes (index forecast-length)
      (let ((day-forecast (elt (noaa-forecast-set-forecasts noaa-last-forecast-set) index)))
	(noaa-insert-day-forecast
	 day-forecast
	 (and (noaa-forecast-day-number day-forecast)
	      last-day-number
	      (= (noaa-forecast-day-number day-forecast)
		 last-day-number)))
	(setq last-day-number (noaa-forecast-day-number day-forecast))))))

(defun noaa-display-as-hourly (forecast-set)
  "Insert the hourly forecast described by FORECAST-SET into the current buffer. A helper function for NOAA-DISPLAY-LAST-FORECAST."
  (let ((forecast-length (length (noaa-forecast-set-forecasts forecast-set)))
	;; Desirable to identify days
	;; - but name may not be defined for points in an hourly forecast (name field may be "")
	(name nil)
	;; - can try tracking using calendar day
	)
    (dotimes (index forecast-length)
      (let ((forecast (elt (noaa-forecast-set-forecasts forecast-set) index)))
	(let ((this-forecast-name (noaa-forecast-name forecast)))
	  ;; dtk-empty-sequence-p
	  (when (or (not this-forecast-name)
		    (= 0 (length this-forecast-name)))
	    (setf this-forecast-name (noaa-iso8601-to-day-name (noaa-forecast-start-time forecast))))
	  (noaa-insert-hour-forecast
	   forecast
	   (cond ((not (cl-equalp name this-forecast-name))
		  ;; day changed
		  (setf name this-forecast-name)
		  ;; ensure name is set in the forecast struct
		  (setf (noaa-forecast-name (elt (noaa-forecast-set-forecasts forecast-set) index))
			this-forecast-name)
		  t)
		 (t nil))))))))

(defun noaa-unless-point-in-cache (callback)
  "Unless the forecast URL is already established for the location
  specified by NOAA-LATITUDE and NOAA-LONGITUDE, query the NOAA API
  for the forecast URL and execute callback CALLBACK upon successful
  completion of the query. Return NIL if the forecast URL is already
  established in NOAA-POINTS; otherwise, return a raw HTTP response
  buffer."
  (if (and noaa-latitude noaa-longitude)
      (cl-destructuring-bind (found-point i)
	  (noaa-find-point noaa-latitude noaa-longitude)
	(if found-point
	    nil
	  (noaa-url-retrieve (noaa-points-url noaa-latitude noaa-longitude)
			     callback)))
    (error "Set NOAA-LATITUDE and NOAA-LONGITUDE first.")))

(defun noaa-forecast-range (forecast)
  "Return difference, in sec, between earliest start time and latest end time in the set of forecast structs described by FORECAST."
  (- (apply 'max (noaa-forecast-ends forecast))
     (apply 'min (noaa-forecast-starts forecast))))
(defun noaa-forecast-ends (forecast)
  "Return a list of end times corresponding to points in FORECAST."
  (mapcar #'(lambda (forecast-point)
	      (noaa-iso8601-to-seconds (noaa-forecast-end-time forecast-point)))
	  forecast))
(defun noaa-forecast-starts (forecast)
  "Return a list of start times corresponding to points in FORECAST."
  (mapcar #'(lambda (forecast-point)
	      (noaa-iso8601-to-seconds (noaa-forecast-start-time forecast-point)))
	  forecast))

(defun noaa-forecast-url (&optional hourlyp)
  "Return, if cached, the forecast URL for the location specified by
NOAA-LATITUDE and NOAA-LONGITUDE."
  (cl-destructuring-bind (found-point i)
      (noaa-find-point noaa-latitude noaa-longitude)
    (if found-point
	(let ((forecast-url (noaa-point-forecast-url found-point)))
	  (if forecast-url
	      (if hourlyp
		  (cl-concatenate 'string forecast-url "/hourly")
		forecast-url))))))

(defun noaa-hourly ()
  "Retrieve and display the hourly forecast."
  (interactive)
  (let ((forecast-url (noaa-forecast-url t)))
    (if forecast-url
	(noaa-url-retrieve forecast-url
			   (function noaa-http-callback-hourly))
      (message "NOAA-FORECAST-URLS does not contain a URL for lat,lon pair %s"
	       (list noaa-latitude noaa-longitude)))))

;; TODO: Make this a defcustom
(defvar noaa-daily-styles
  '((terse .
     (lambda (day last)
       (unless last
         (insert (propertize (format "%s " (s-truncate 3 (noaa-forecast-name day) ""))
                             'face 'noaa-face-date)))
       (insert (propertize (format "%s " (noaa-forecast-temp day))
                           'face 'noaa-face-temp))))
    (default .
     (lambda (day last)
       (let ((day-field-width 16)
             (temp-field-width 5))
         ;; simple output w/some alignment
         (unless last (insert "\n"))
         (insert
           (propertize (format "%s" (noaa-forecast-name day))
                       'face 'noaa-face-date))
         (move-to-column day-field-width t)
         (insert (propertize (format "% s" (noaa-forecast-temp day))
                             'face 'noaa-face-temp))
         (move-to-column (+ day-field-width temp-field-width) t)
         (insert (propertize (format "%s" (noaa-forecast-short-forecast day))
                             'face 'noaa-face-short-forecast)
                 "\n"))))
    (extended .
     (lambda (day last)
      (let ((day-field-width 16)
            (temp-field-width 5))
        (insert (propertize (format "%s" (noaa-forecast-name day))
                            'face 'noaa-face-date))
        (move-to-column day-field-width t)
        (insert (propertize (format "% s" (noaa-forecast-temp day))
                            'face 'noaa-face-temp))
        (newline 2)
        (insert (propertize (format "%s" (noaa-forecast-detailed-forecast day))
                            'face 'noaa-face-short-forecast))
        (newline 2)))))
 "Definitions of display formats for DAILY forecasts.
This is a list of CONS. Each CAR is a symbol name for the format,
and each CDR is a function which takes two argument:
NOAA-FORECAST and LAST-DAY-P and inserts data into the current
buffer based upon them.")

(defun noaa-insert-day-forecast (noaa-forecast last-day-p)
  "Insert NOAA-FORECAST text into current buffer.
This is a helper function for NOAA-DISPLAY-LAST-FORECAST-AS-DAILY.
LAST-DAY-P is a boolean indicating whether NOAA-FORECAST is the
final one of the current GET request."
  (let ((style (nth noaa--daily-current-style noaa-daily-styles)))
    (apply (cdr style) (list noaa-forecast last-day-p))
    (setq header-line-format
      (format noaa-header-line
              (propertize (or noaa-location "") 'face 'bold)
              (car style)))))

;; TODO: Make this a defcustom
(defvar noaa-hourly-styles
  '((terse .
     (lambda (hour with-day)
       (insert
         (propertize (noaa-iso8601-to-hour-min (noaa-forecast-start-time hour))
                    'face 'noaa-face-date)
         " -" ?\x0020
         (propertize (format "%s " (noaa-forecast-temp hour))
                     'face 'noaa-face-temp)
         "\n")))
    (extended . noaa-insert-hour-forecast-default))
 "Definitions of display formats for DAILY forecasts.
This is a list of CONS. Each CAR is a symbol name for the format,
and each CDR is a function which takes two argument:
NOAA-FORECAST and LAST-DAY-P and inserts data into the current
buffer based upon them.")


;; If WITH-DAY-P is true, depending on style, provide an indication of the day (e.g., name of day or calendar date).
(defun noaa-insert-hour-forecast (noaa-forecast with-day-p)
  "Insert the forecast described by NOAA-FORECAST into the current buffer. A helper function for NOAA-DISPLAY-AS-HOURLY."
  (when with-day-p
    (newline)
    (insert
     (propertize (noaa-forecast-name noaa-forecast)
		 'face 'noaa-face-date))
    (newline))
  (let ((style (nth noaa--hourly-current-style noaa-hourly-styles)))
    (apply (cdr style) (list noaa-forecast with-day-p))
    (setq header-line-format
      (format noaa-header-line
              (propertize (or noaa-location "") 'face 'bold)
              (car style)))))

(defun noaa-insert-hour-forecast-default (noaa-forecast _with-day-p)
  (let ((hour-field-end-col 7)
	(temp-field-end-col 12))
    (insert ?\x0020)
    (insert (propertize (noaa-iso8601-to-hour-min (noaa-forecast-start-time noaa-forecast)) 'face 'noaa-face-date))
    (move-to-column hour-field-end-col t)
    (insert (propertize (format "% s" (noaa-forecast-temp noaa-forecast)) 'face 'noaa-face-temp))
    (move-to-column temp-field-end-col t)
    (insert (propertize (format "%s" (noaa-forecast-short-forecast noaa-forecast)) 'face 'noaa-face-short-forecast))
    (newline)))

(defun noaa-handle-noaa-result (result)
  "Handle the data described by RESULT (presumably the result of an HTTP request for NOAA forecast data). Return a list of periods."
  (switch-to-buffer noaa-buffer-spec)
  ;; retrieve-fn accepts two arguments: a key-value store and a key
  ;; retrieve-fn returns the corresponding value
  (let ((retrieve-fn 'noaa-aval))
    (let ((properties (funcall retrieve-fn result 'properties)))
      (if (not properties)
	  (message "Couldn't find properties. The NOAA API spec may have changed.")
	(funcall retrieve-fn properties 'periods)))))

(defun noaa-iso8601-to-hour-min (iso8601-string)
  "Return a string representing the time as HH:MM as specified by ISO8601-STRING. For example, invocation with 2018-12-24T18:00:00-08:00 should return 18:00."
  (format-time-string "%H:%M" (parse-iso8601-time-string iso8601-string)))

(defun noaa-iso8601-to-day (iso8601-string)
  "Return an integer representing the day as specified by ISO8601-STRING. For example, invocation with 2018-12-24T18:00:00-08:00 should return 24."
  (string-to-number (format-time-string "%d" (parse-iso8601-time-string iso8601-string))))

(defun noaa-iso8601-to-day-name (iso8601-string)
  "Return a string representing the name of a day of the week where the value is that specified by ISO8601-STRING. For example, invocation with `2018-12-12T01:00:00-08:00' should return `Wednesday'."
  (format-time-string "%A" (parse-iso8601-time-string iso8601-string)))

(defun noaa-iso8601-to-seconds (iso8601-string)
  "Return an integer representing the number of seconds since since 1970-01-01 00:00:00 UTC as indicated by the ISO 8601 time indicated by ISO8601-STRING. For example, invocation with `2018-12-24T18:00:00-08:00' should return 1545703200."
  (string-to-number (format-time-string "%s" (parse-iso8601-time-string iso8601-string))))

(defun noaa--once-lat-lon-set (lat lon)
  "Given latitude LAT and longitude LON, ensure the needed metadata is
on hand in order to make a request, for forecast data, to the NOAA
National Weather Service API, then query the NOAA server for the
actual forecast, and, finally, handle the server response and display
the corresponding forecast."
  (let ((g (lambda ()
	     ;; Anticipate the possibility that the forecast URL was not established
	     (cl-destructuring-bind (found-point i)
		 (noaa-find-point lat lon)
	       (cond (found-point
		      (setf noaa-last-point-index i)
		      (noaa-url-retrieve (noaa-point-forecast-url found-point)
					 (function noaa-http-callback-daily)))
		     (t
		      (message "NOAA-POINTS does not contain a URL for lat,lon pair %s" (list noaa-latitude noaa-longitude))))))))
    (let ((f (cl-function (lambda (&key data response error-thrown
					&allow-other-keys)
			    (setf noaa-last-response data)
			    (noaa-http-callback--establish-forecast-url :data data
									:response response
									:error-thrown error-thrown)
			    (funcall g)))))
      (unless (noaa-unless-point-in-cache f)
	(funcall g)))))

(defun noaa-osm-query (location callback)
  "Execute an OpenStreetMap search query, using LOCATION as the string
value corresponding to the query Q key. CALLBACK specified the
function which should be called upon successful completion of the
query."
  (request (format noaa--osm-api location)
    :parser 'buffer-string
    :error (function noaa-http-error-callback)
    :status-code '((500 . (lambda (&rest _)
			    (message "500: from openstreetmap"))))
    :success callback))

;; metadata for an NOAA gridpoint
(cl-defstruct noaa-point
  forecast-url				; string - e.g., "https://api.weather.gov/gridpoints/VEF/47,56/forecast"
  grid-id				; forecast office 3-letter code - e.g., "HNX"
  grid-x				; integer
  grid-y				; integer
  query-lat				; latitude value used with query
  query-lon				; longitude value used with query
  relative-location-city			; string
  relative-location-state 			; string (US two-letter state abbreviation)
  )

;; make struct from api response
(defun noaa-point-metadata-from-point-response (json lat lon)
  "Return a NOAA-POINT-METADATA structure based on data in JSON, the
parsed response data from the NOAA /gridpoints/{wfo}/{x},{y}/forecast
API endpoint. LAT and LON are the latitude and longitude used in the
query."
  (make-noaa-point
   :forecast-url (kvdotassoc 'properties.forecast noaa-last-response)
   :grid-id (kvdotassoc 'properties.gridId noaa-last-response)
   :grid-x (kvdotassoc 'properties.gridX noaa-last-response)
   :grid-y (kvdotassoc 'properties.gridY noaa-last-response)
   :query-lat lat
   :query-lon lon
   :relative-location-city (kvdotassoc 'properties.relativeLocation.properties.city noaa-last-response)
   :relative-location-state (kvdotassoc 'properties.relativeLocation.properties.state noaa-last-response)
   ))

(defvar noaa-points nil "A set of noaa-point structs.")

(defun noaa-find-point (lat lon)
  "If an NOAA-POINT struct corresponding to LAT and LON is present in
NOAA-POINTS, return a list where the first member is the point and the
second member is the index of the point."
  (let ((i (cl-position-if (lambda (point)
			     (and (= (noaa-point-query-lat point) lat)
				  (= (noaa-point-query-lon point) lon)))
			   noaa-points)))
    (if i
	(list (elt noaa-points i) i)
      (list nil nil))))

(defun noaa-points-add-or-update (point)
  "Ensure the point POINT is present in NOAA-POINTS. Return the index
of POINT in NOAA-POINTS."
  (cl-destructuring-bind (found-point i)
      (noaa-find-point (noaa-point-query-lat point)
		       (noaa-point-query-lon point))
    (cond (i
	   (setf (elt noaa-points i) point))
	  (point
	   (push point noaa-points)
	   (setf i 0)))
    i))

(defun noaa-prompt-user-for-location ()
  (let ((location nil)
        (latitude nil)
        (longitude nil))
    ;; TODO: It would be nice to have a list of locations in order to provide
    ;;       completion candidates, but that would be a tremendous list.
    (setq location
	  (read-string "Location (RET to enter coordinates instead): "))
    (when (string-blank-p (or location ""))
      (setq location nil)
      (setq latitude
	    (read-number
	     "Enter latitude (decimal fraction; + north, - south): "))
      (setq longitude
	    (read-number
	     "Enter longitude (decimal fraction; + east, - west): ")))
    (cl-values location latitude longitude)))

(defun noaa-query-gridpoints-api (lat lon callback)
  "Query the NOAA gridpoints API for forecast data using a cached URL
and calling callback CALLBACK upon successful completion of the query.
The cached URL, a member of NOAA-FORECAST-URLS, is referenced by LAT
and LON values."
  (let ((forecast-url (cdr (assoc (cons lat lon)
				  noaa-forecast-urls
				  'equal))))
    (if forecast-url
	(noaa-url-retrieve forecast-url callback)
      (error "Expected a match in NOAA-FORECAST-URLS"))))

;;;###autoload
(defun noaa-quit ()
  "Leave the buffer specified by ‘noaa-buffer-spec’."
  (interactive)
  (kill-buffer noaa-buffer-spec))

(defun noaa-clear-forecast-set (forecast-set)
  "Set the slots in the forecast-set struct FORECAST-SET to NIL."
  (setf (noaa-forecast-set-forecasts forecast-set)
	nil)
  (setf (noaa-forecast-set-type forecast-set)
	nil))

(defun noaa-points-url (latitude longitude)
  "Return a NOAA API HTTP GET request string. LATITUDE and LONGITUDE
should be numbers."
  (format "https://api.weather.gov/points/%s,%s" latitude longitude))

(defun noaa-populate-forecasts (periods forecast-set)
  "Populate the forecasts slot of the forecast-set struct FORECAST-SET using PERIODS."
  ;; retrieve-fn accepts two arguments: a key-value store and a key
  ;; retrieve-fn returns the corresponding value
  (let ((retrieve-fn 'noaa-aval)
	(number-of-periods (length periods)))
    (setf (noaa-forecast-set-forecasts forecast-set)
	  (make-list (length periods) nil))
    (dotimes (i number-of-periods)
      (let ((period (elt periods i)))
	(let ((start-time (funcall retrieve-fn period 'startTime)))
	  (let ((day-number (noaa-iso8601-to-day start-time))
		(detailed-forecast (funcall retrieve-fn period 'detailedForecast))
		(end-time (funcall retrieve-fn period 'endTime))
		;; NAME is descriptive. It is not always the name of a week day. Exaples of valid values include "This Afternoon", "Thanksgiving Day", or "Wednesday Night". For an hourly forecast, it may simply be the empty string.
		(name (funcall retrieve-fn period 'name))
		(temp (funcall retrieve-fn period 'temperature))
		(short-forecast (funcall retrieve-fn period 'shortForecast)))
	    (setf (elt (noaa-forecast-set-forecasts forecast-set) i)
		  (make-noaa-forecast :start-time start-time :end-time end-time :day-number day-number :name name :temp temp :detailed-forecast detailed-forecast :short-forecast short-forecast))))))))

(defun noaa-url-retrieve (url &optional http-callback)
  "Return a raw HTTP response buffer.
This is a buffer containing only the 'raw' body of the HTTP
response associated with a GET request to URL. If URL is NIL, the
GET request is made to the URL described by `(noaa-url
noaa-latitude noaa-longitude)'. Call HTTP-CALLBACK with the
buffer as a single argument."
  (noaa-url-retrieve-tkf-emacs-request url
				       http-callback
				       nil
				       noaa-api-weather-gov--status-map))

;; async version relying on tfk emacs-request library
(defun noaa-url-retrieve-tkf-emacs-request (&optional url http-callback http-error-callback http-status-code)
  (request url
    :headers (list '("Upgrade-Insecure-Requests" . "1")
		   (cons "User-Agent" (string-trim (url-http-user-agent-string))))
    :parser 'buffer-string
    :error
    (or http-error-callback
	(function noaa-http-error-callback))
    :status-code http-status-code
    :success http-callback))

(cl-defun noaa-http-callback-daily (&key data response error-thrown &allow-other-keys)
  ;; currently: callback populates noaa-last-forecast-set and then calls (noaa-display-last-forecast) and (noaa-mode)
  (noaa-http-callback :data data :response response :error-thrown error-thrown)
  (setf (noaa-forecast-set-type noaa-last-forecast-set) :daily)
  (noaa-display-last-forecast)
  (noaa-mode))

(cl-defun noaa-http-error-callback (&key data error-thrown response symbol-status
					 &allow-other-keys)
  (message "data: %S " data)
  (message "symbol-status: %S " symbol-status)
  (message "E Error response: %S " error-thrown)
  (message "response: %S " response))

(cl-defun noaa-http-callback-hourly (&key data response error-thrown &allow-other-keys)
  (noaa-http-callback :data data :response response :error-thrown error-thrown)
  (setf (noaa-forecast-set-type noaa-last-forecast-set) :hourly)
  (noaa-display-last-forecast)
  (noaa-mode))

(defun noaa--get-buffer ()
  "Switch to, and activate NOAA-MODE in, the buffer specified by
NOAA-BUFFER-SPEC. Return value undefined."
  (let ((buffer-is-new (buffer-live-p noaa-buffer-spec)))
    (switch-to-buffer (get-buffer-create noaa-buffer-spec))
    (when buffer-is-new
      (noaa-mode))))

(cl-defun noaa-http-callback (&key data _response error-thrown &allow-other-keys)
  (noaa--get-buffer)
  (let ((inhibit-read-only t))
    (erase-buffer)
    (and error-thrown (message (error-message-string error-thrown))))
  (let ((result (json-read-from-string data)))
    (setf noaa-last-forecast-raw result)
    (let ((periods (noaa-handle-noaa-result result)))
      (unless (noaa-forecast-set-p noaa-last-forecast-set)
        (setf noaa-last-forecast-set (make-noaa-forecast-set :forecasts nil :type nil)))
       (noaa-populate-forecasts periods noaa-last-forecast-set))))

(cl-defun noaa-http-callback--establish-forecast-url (&key data _response error-thrown &allow-other-keys)
  (setf noaa-last-response nil)
  (noaa-http-callback--handle-json :data data :_response _response :error-thrown error-thrown)
  ;; Setting POINT establishes forecast URL (forecast-url) and
  ;; forecast office ID (grid-id)
  (let ((point (noaa-point-metadata-from-point-response noaa-last-response
							noaa-latitude
							noaa-longitude)))
    (setf noaa-last-point-index
	  (noaa-points-add-or-update point))))

;; generic callback
(cl-defun noaa-http-callback--handle-json (&key data _response error-thrown &allow-other-keys)
  (setf noaa-last-response (json-read-from-string data)))

(defun noaa-insert (x)
  "Insert X into the buffer specified by ‘noaa-buffer-spec’."
  (switch-to-buffer noaa-buffer-spec)
  (let ((inhibit-read-only t))
    (insert x)))

(defun noaa-next-style ()
  "Transition to the next display style.
See variables `noaa--daily-current-style' and `noaa--hourly-current-style'."
  (interactive)
  ;; wouldn't hurt to add this to other (interactive) fns that should
  ;; only operate within noaa-mode
  (unless (eq (current-buffer) (get-buffer noaa-buffer-spec))
    (display-warning :warning (format "Not in %s buffer" noaa-buffer-spec)))
  (if (eq (noaa-forecast-set-type noaa-last-forecast-set) :hourly)
    (setq noaa--hourly-current-style
      (mod (1+ noaa--hourly-current-style)
           (length noaa-hourly-styles)))
   (setq noaa--daily-current-style
     (mod (1+ noaa--daily-current-style)
          (length noaa-daily-styles))))
  (noaa-display-last-forecast))

;;
;; noaa mode
;;

;;;###autoload
(define-derived-mode noaa-mode fundamental-mode "noaa"
  "Major mode for displaying NOAA weather data
\\{noaa-mode-map}
"
  (setq header-line-format
    (format noaa-header-line
            (propertize (or noaa-location "") 'face 'bold)
            (car (nth noaa--daily-current-style noaa-daily-styles))))
  (visual-line-mode)
  (read-only-mode))

(defvar noaa-mode-map (make-sparse-keymap)
  "Keymap for `noaa-mode'.")

(define-key noaa-mode-map (kbd "h") 'noaa-hourly)
(define-key noaa-mode-map (kbd "d") 'noaa-daily)
(define-key noaa-mode-map (kbd "q") 'noaa-quit)
(define-key noaa-mode-map (kbd "n") 'noaa-next-style)
(define-key noaa-mode-map (kbd "c") 'noaa-new-location)

(provide 'noaa)
;;; noaa.el ends here
