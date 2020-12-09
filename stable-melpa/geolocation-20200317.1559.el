;;; geolocation.el --- Get your location on Earth -*- lexical-binding: t -*-

;; Author: Neil Okamoto <neil.okamoto+melpa@gmail.com>
;; Copyright (C) 2020  Neil Okamoto
;; Keywords: hardware
;; Package-Version: 20200317.1559
;; Package-Commit: bc7848832eb0352e3a71f4b9d89d917fe12d18be
;; Package-Requires: ((request-deferred "0.3.2") (deferred "0.5.1") (emacs "25.1"))
;; URL: https://github.com/gonewest818/geolocation.el
;; Version: 0.2.0

;; This file is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation; either version 2, or (at your option) any
;; later version.

;; This file is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to the Free
;; Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.

;;; Commentary:

;; This package obtains your current location by obtaining the MAC
;; addresses of nearby wifi access points and then submitting that
;; list to third-party geolocation APIs.  Those geolocation services
;; use the known locations of the wifi access points and the relative
;; strength of each signal to triangulate your latitude and longitude.

;; The main entry point is:

;; - 'geolocation-update-position' which calls 'geolocation-get-position'
;;   on a regular interval, and sets 'geolocation-location' with the
;;   result.  The 'geolocation-update-hook' functions are called after
;;   each update.  Customize the hook functions if you want to
;;   invoke functions based on your position, and customize the
;;   'geolocation-update-interval' with the time granularity you need,
;;   keeping in mind the underlying positioning APIs may have rate
;;   limits and/or costs associated with high frequency querying.

;;   The variable 'geolocation-location' will contain nil or an alist:
;;   - latitude  - latitude of the current position
;;   - longitude - longitude of the current position
;;   - accuracy  - an error radius, in meters
;;   - timestamp - timestamp via 'float-time'

;; Other potentially useful functions include:

;; - 'geolocation-get-position' which retrieves your estimated position
;;   once and invokes a callback with the position data.  The callback
;;   receives an alist with the same format as 'geolocation-location.'

;; - 'geolocation-scan-wifi' which scans asynchronously for nearby wifi
;;   access points using available system utilities, and invokes a callback
;;   with the wifi data.  The callback receives a list of alists containing:
;;   - bssid   - mac address that uniquely identifies the AP
;;   - signal  - relative signal strength, or RSSI
;;   - channel - transmission channel

;; - 'geolocation-update-calendar' stores the latest position in
;;   'calendar-latitude' and 'calendar-longitude'.  This function works
;;   as a 'geolocation-update-hook'.

;;   At present, wifi scanning is supported on Mac OSX and Windows.
;;   Linux support is planned but not yet implemented.

;; You have a choice of third party services to use for the positioning:

;; - Google Maps Geolocation API
;;   https://developers.google.com/maps/documentation/geolocation/intro

;; - HERE Technologies Positioning API
;;   https://developer.here.com/develop/rest-apis

;; - Unwired Labs Location API
;;   https://unwiredlabs.com/home

;; This package offers a set of customizable variables you can use to
;; select which service is used, declare your API access token, choose
;; the nearest API endpoint, and so on.  Those settings can be found in
;; 'M-x customize', then browse for "Environment", then "hardware", and
;; then "Geolocation".

;; By default, access tokens are expected to be accessed via the built-in
;; 'auth-source' package.  You can configure any backend, as this package
;; only requires the token to be searchable via
;; 'auth-source-pick-first-password'.

;; Rate Limits and Costs:

;; Each of these services requires you to create your own account, and
;; potentially provide billing information as well.  You will be agreeing
;; to the vendor's end-user agreements including such things as
;; acceptable usage policies and privacy terms, when you create your
;; account.

;; Care has been taken to choose services that include either a free
;; tier, or equivalently, an allowance of a certain amount of usage per
;; day or per month.  It's your responsibility to set up your account
;; with those services, obtain and protect your token, and manage your
;; usage of those APIs because there can be associated costs if your
;; usage exceeds the usage terms of the subscription or plan you choose.

;; WARNING: THIS PACKAGE COLLECTS INFORMATION THAT IMPLIES YOUR PHYSICAL
;; LOCATION.  THAT DATA WILL BE SENT TO THIRD-PARTY GEOLOCATION SERVICES
;; WHICH CAN PINPOINT YOUR LOCATION TYPICALLY WITHIN 100 METERS OR LESS.
;; WHILE THIS PACKAGE DOES NOT ITSELF STORE YOUR LOCATION, WE CANNOT
;; GUARANTEE WHAT A GIVEN THIRD-PARTY SERVICE MAY DO WITH THE DATA IT
;; RECEIVES IN THESE API TRANSACTIONS.  RATHER, YOU UNDERSTAND AND AGREE
;; TO THE PRIVACY AGREEMENTS AND END USER AGREEMENTS OF EACH OF THE
;; INDIVIDUAL GEOLOCATION APIS YOU USE.

;;; Code:

(require 'auth-source)
(require 'json)
(require 'deferred)
(require 'request-deferred)
(require 'subr-x)

(defgroup geolocation nil
  "Get your location on Earth"
  :prefix "geolocation-"
  :group 'hardware
  :link '(url-link
          :tag "Github" "https://github.com/gonewest818/geolocation.el"))

(defcustom geolocation-api-vendor :google
  "Select which third party geolocation API will be called."
  :type '(radio (const :tag "Google Maps Geolocation API" :google)
                (const :tag "HERE Technologies Positioning API" :here)
                (const :tag "Unwired Labs Location API" :unwiredlabs))
  :group 'geolocation)

(defcustom geolocation-update-interval 300
  "Set the interval (in seconds) how often location is updated.
This setting has effect only when `geolocation-update-position'
has been called."
  :type '(integer)
  :group 'geolocation)

(defcustom geolocation-update-hook nil
  "Hook functions to run when the location is updated.

Each hook is a function taking no arguments.  When the hook is
called, the value in `geolocation-location' will have been
updated recently.  Note, we make no attempt to track movement or
distance from the last position.  To get movement, the hook
itself will need to have saved the previous coordinates and
compute the distance between the previous and new."
  :type '(repeat symbol)
  :group 'geolocation)

(defvar geolocation-location nil
  "The most recently scanned location.

Value is nil if the position is unknown.  Otherwise the value is
an alist with the following keys:
  latitude  : latitude of the current position
  longitude : longitude of the current position
  accuracy  : accuracy of the estimate in meters
  timestamp : timestamp when this position was obtained")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Utilities

(defvar geolocation-debug-messages 0
  "Control debug output to *Messages* buffer.
Set 0 to disable all output, 1 for basic output, or a larger
integer for more verbosity.")

(defun geolocation--dbg (v fmt &rest args)
  "Print debug message at verbosity V, filling format string FMT with ARGS."
  (when (>= geolocation-debug-messages v)
    (apply #'message fmt args)))

(defun geolocation--shell-command-async (command parser &optional callback)
  "Invoke COMMAND in a shell, run PARSER, and optionally pass to CALLBACK.
The command and parser will run in a deferred chain that does not
block the calling thread.  This function returns a deferred
object suitable for further chaining.

Within the deferred chain the PARSER will be invoked with a
single argument which is the buffer containing the output of
COMMAND.  It is the responsibility of PARSER to delete the buffer
when done.

If a CALLBACK is provided, it will be invoked with the output of
the PARSER.  It is the responsibility of the CALLBACK to return
the value it was passed, so that further callbacks can be added
to the chain."
  (deferred:$
    (deferred:next
      (lambda ()
        (geolocation--dbg 1 "geolocation--shell-command-async:start")))
    (deferred:process-shell-buffer command)
    (deferred:nextc it parser)
    (deferred:nextc it
      (lambda (x)                       ; sorted by strength
        (sort x (lambda (i j)
                  (> (alist-get 'signal i)
                     (alist-get 'signal j))))))
    (deferred:error it                  ; catch error and return nil
      (lambda (err)
        (geolocation--dbg 0 "geolocation--shell-command-async:error: %s" err)
        nil))
    (deferred:nextc it
      (lambda (x)
        (if (and x callback)            ; e.g. to save wifi data
            (funcall callback x)
          x)))
    (deferred:nextc it
      (lambda (x)
        (geolocation--dbg 1 "geolocation--shell-command-async:end")
        x))))

(defun geolocation--timestamp (location)
  "Append a timestamp to the alist stored in LOCATION."
  (cons (cons 'timestamp (float-time)) location))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Macintosh

;; Note: OSX provides a core location framework that is used for
;; Apple's own applications. It is possible to write native code, or
;; possibly AppleScript code to interact with those frameworks, and
;; other packages exist to do that. We've chosen geolocation via wifi
;; because it's more broadly applicable to many operating systems.

(defgroup geolocation-system-osx nil
  "Mac OSX specific settings for the geolocation library"
  :prefix "geolocation-system-osx-"
  :group 'geolocation)

(defcustom geolocation-system-osx-airport-path
  (concat "/System/Library/PrivateFrameworks/"
          "Apple80211.framework/Versions/Current/Resources/")
  "Path to the Apple 'airport' binary on Mac OSX.

We need to specify this because the utility is not in a standard
location.  It's unlikely users need to customize this, unless
Apple changes the location of the utility."
  :type '(string)
  :group 'geolocation-system-osx)

(defcustom geolocation-system-osx-airport-command
  "airport --scan | cut -c 34-63 | tail -n +2"
  "Command line with arguments needed to invoke airport."
  :type '(string)
  :group 'geolocation-system-osx)

(defun geolocation--osx-parse-wifi (buffer)
  "Parse output from the airport command in BUFFER."
  (let ((result nil))
    (with-current-buffer buffer
      (goto-char (point-min))
      (while (not (eobp))
        ;; airport output can be split on whitespace, and
        ;; then this lambda builds cons pairs for each field
        (push (cl-mapcar (lambda (c k v)
                           (cons k (if (eq c 'int) (string-to-number v) v)))
                         '(str int str)
                         '(bssid signal channel)
                         (split-string (buffer-substring (point)
                                                         (point-at-eol))))
              result)
        (beginning-of-line 2)))
    (kill-buffer buffer)
    result))

(defun geolocation--osx-scan-wifi (&optional callback)
  "Scan wifi asynchronously, and optionally call CALLBACK with result.
Return a deferred object for chaining further operations."
  (geolocation--shell-command-async
   (concat geolocation-system-osx-airport-path
           geolocation-system-osx-airport-command)
   #'geolocation--osx-parse-wifi
   callback))

;; The OSX "airport" utility also outputs a property list in XML format
;; which in principle should be more reliable to parse, and contains
;; more interesting information than the human readable output.
;; However as of 2/1/2020 the "airport" utility truncates output when
;; devices advertise themselves with names containing unprintable
;; characters. The truncation bug cannot be worked around by the
;; caller.  Hide this implementation until/unless the underlying bug
;; is fixed.

;; (require 'osx-plist)

;; (setq geolocation--osx-airport-command-xml
;;       (concat geolocation--osx-airport-path
;;               "airport --scan --xml"))

;; (defun geolocation--osx-parse-access-point (ap)
;;   "Select relevant fields from the access point record AP.

;; The result is an alist containing at least the following keys:
;;   bssid   : BSSID / MAC address of the access point
;;   signal  : signal strength or RSSI from that access point
;;   channel : channel on which that access point is operating"
;;   (list (cons 'bssid (gethash "BSSID" ap))
;;         (cons 'signal (gethash "RSSI" ap))
;;         (cons 'channel (gethash "CHANNEL" ap))))

;; (defun geolocation--osx-call-airport-xml ()
;;   "Run the \"airport\" utility and parse the xml output."
;;   (with-temp-buffer
;;     (let ((coding-system-for-read 'utf-8))
;;       (shell-command geolocation--osx-airport-command-xml t nil))
;;     (mapcar #'geolocation--osx-parse-access-point (osx-plist-parse-buffer))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Windows

(defgroup geolocation-system-windows nil
  "Windows-specific settings for the geolocation library"
  :prefix "geolocation-system-windows-"
  :group 'geolocation)

(defcustom geolocation-system-windows-netsh-command
  "netsh wlan show networks mode=bssid"
  "Command line with arguments needed to invoke netsh."
  :type '(string)
  :group 'geolocation-system-windows)

(defun geolocation--windows-bssid ()
  "Search via regexp for the next BSSID."
  (when (re-search-forward
         "\\s-*BSSID\\s-[0-9]+\\s-*:\\s-\\([a-f0-9:]+\\)" nil t)
    (match-string-no-properties 1)))

(defun geolocation--windows-signal ()
  "Search via regexp for the next Signal value."
  (when (re-search-forward "\\s-*Signal\\s-*:\\s-\\([0-9:]+\\)" nil t)
    (let ((sig (match-string-no-properties 1)))
      (- (/ (string-to-number sig) 2.0) 100))))

(defun geolocation--windows-channel ()
  "Search via regexp for the next Channel number."
  (when (re-search-forward "\\s-*Channel\\s-*:\\s-\\([0-9:]+\\)" nil t)
    (match-string-no-properties 1)))

(defun geolocation--windows-parse-wifi (buffer)
  "Parse output from the netsh command in BUFFER."
  (let ((result nil))
    (with-current-buffer buffer
      (goto-char (point-min))
      (while (not (eobp))
        (let* ((bssid (geolocation--windows-bssid))
               (sig (geolocation--windows-signal))
               (chan (geolocation--windows-channel)))
          (if (and bssid sig chan)
              (push (list (cons 'bssid bssid)
                          (cons 'signal sig)
                          (cons 'channel chan))
                    result)
            (goto-char (point-max))))))
    (kill-buffer buffer)
    result))

(defun geolocation--windows-scan-wifi (&optional callback)
  "Scan wifi asynchronously, and optionally call CALLBACK with result.
Return a deferred object for chaining further operations."
  (geolocation--shell-command-async
   geolocation-system-windows-netsh-command
   #'geolocation--windows-parse-wifi
   callback))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Linux

(defgroup geolocation-system-linux nil
  "Linux-specific settings for the geolocation library"
  :prefix "geolocation-system-linux-"
  :group 'geolocation)

(defcustom geolocation-system-linux-dbus-command
  "echo not implemented"
  "Command line with arguments needed to query dbus to scan wifi."
  :type '(string)
  :group 'geolocation-system-linux)

(defun geolocation--linux-scan-wifi (&optional _callback)
  "Wifi scanning on Linux not yet implemented."
  (error "Wifi scanning on Linux not yet implemented"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Google geolocation api

(defgroup geolocation-api-google nil
  "Configuration needed to call the Google Maps Geolocation API"
  :prefix "geolocation-api-google-"
  :group 'geolocation)

(defcustom geolocation-api-google-url
  "https://www.googleapis.com/geolocation/v1/geolocate"
  "URL for the Google Maps Geolocation API."
  :type '(string)
  :group 'geolocation-api-google)

(defcustom geolocation-api-google-token nil
  "Authorization token for the Google Geolocation API.

IMPORTANT NOTE: This customization is offered for the convenience
of people who want to quickly set up and test this package.
However you are strongly discouraged from leaving authorization
tokens (which are like passwords) in your Emacs configurations as
plainly readable text.  Setting this variable to nil will cause
the library to retrieve your token via `auth-source' instead."
  :type '(choice (const :tag "Retrieve token from `auth-source'" nil)
                 (string :tag "Google API token"))
  :group 'geolocation-api-google)

(defcustom geolocation-api-google-auth-source-host "googleapis.com"
  "The host name used for lookups in `auth-source'."
  :type '(string)
  :group 'geolocation-api-google)

(defcustom geolocation-api-google-auth-source-user "geolocation.el"
  "The user name used for lookups in `auth-source'."
  :type '(string)
  :group 'geolocation-api-google)

(defun geolocation--google-xform-wifi (wifi)
  "Transform WIFI list into the format needed for Google's API.

In particular Google wants the json payload to contain keys
\"macAddress\", \"signalStrength\" and \"channel\" whereas the
wifi scanning functions in the library produce different keys for
those fields."
  (mapcar (lambda (x)
            (list (cons 'macAddress     (alist-get 'bssid x))
                  (cons 'signalStrength (alist-get 'signal x))
                  (cons 'channel        (alist-get 'channel x))))
          wifi))

(defun geolocation--google-xform-location (response)
  "Transform the Google API response RESPONSE into the format needed."
  (let* ((r (request-response-data response))
         (loc (alist-get 'location r))
         (lat (alist-get 'lat loc))
         (lng (alist-get 'lng loc))
         (acc (alist-get 'accuracy r)))
    (list (cons 'latitude lat)
          (cons 'longitude lng)
          (cons 'accuracy acc))))

(defun geolocation--google-get-token ()
  "Resolve the Google API token.

If `geolocation-google-token' is non-nil, then use that.
Otherwise, retrieve the token via `auth-source-search' under the
hostname `geolocation-api-google-auth-source-host' and username
`geolocation-api-google-auth-source-user'."
  (or geolocation-api-google-token
      (auth-source-pick-first-password
       :host geolocation-api-google-auth-source-host
       :user geolocation-api-google-auth-source-user)))

(defun geolocation--call-google-api (wd callback)
  "Request location from Google API using wifi data in the deferred WD.
Send results to a CALLBACK which is expected to store the
resulting location data.  Return a deferred object.

The implementation is a chain of deferreds with the following
steps executing on a separate thread:
  - transform wifi into the format Google wants
  - call the Google API with that wifi data
  - transform the Google response into the alist object we need
  - attach a timestamp to the alist
  - invoke the callback with the alist"
  (let ((token (geolocation--google-get-token)))
    (deferred:$
      (deferred:nextc wd                ; chaining steps onto "wd"
        (lambda (wifi)
          (geolocation--google-xform-wifi wifi)))
      (deferred:nextc it
        (lambda (wifi)
          (geolocation--dbg 1 "geolocation--call-google-api:request")
          (request-deferred
           geolocation-api-google-url
           :type "POST"
           :params (list (cons "key" token))
           :data (json-encode (list (cons "wifiAccessPoints" wifi)))
           :parser #'json-read
           :timeout 15)))
      (deferred:nextc it
        (lambda (response)
          (if (= 200 (request-response-status-code response))
              (geolocation--google-xform-location response)
            (geolocation--dbg 0 "geolocation--call-google-api:error-thrown: %s"
                              (request-response-error-thrown response))
            (geolocation--dbg 0 "geolocation--call-google-api:status-code: %s"
                              (request-response-status-code response))
            nil)))
      (deferred:nextc it
        (lambda (location)
          (and location (geolocation--timestamp location))))
      (deferred:nextc it
        (lambda (location)
          (and location (funcall callback location)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HERE Technologies positioning api

(defgroup geolocation-api-here nil
  "Configuration needed to call the HERE Technologies Positioning API"
  :prefix "geolocation-api-here-"
  :group 'geolocation)

(defcustom geolocation-api-here-url
  "https://pos.ls.hereapi.com/positioning/v1/locate"
  "URL for the HERE Technologies Positioning API."
  :type '(string)
  :group 'geolocation-api-here)

(defcustom geolocation-api-here-token nil
  "Authorization token for the HERE Technologies Positioning API.

IMPORTANT NOTE: This customization is offered for the convenience
of people who want to quickly set up and test this package.
However you are strongly discouraged from leaving authorization
tokens (which are like passwords) in your Emacs configurations as
plainly readable text.  Setting this variable to nil will cause
the library to retrieve your token via `auth-source' instead."
  :type '(choice (const :tag "Retrieve token from `auth-source'" nil)
                 (string :tag "HERE Technologies API token"))
  :group 'geolocation-api-here)

(defcustom geolocation-api-here-auth-source-host "pos.ls.hereapi.com"
  "The host name used for lookups in `auth-source'."
  :type '(string)
  :group 'geolocation-api-here)

(defcustom geolocation-api-here-auth-source-user "geolocation.el"
  "The user name used for lookups in `auth-source'."
  :type '(string)
  :group 'geolocation-api-here)

(defun geolocation--here-xform-wifi (wifi)
  "Transform WIFI list into the format needed for HERE's API.

In particular HERE wants the json payload to contain just the
\"mac\" address, and \"powrx\" or signal strength."
  (mapcar (lambda (x)
            (list (cons 'mac   (alist-get 'bssid x))
                  (cons 'powrx (alist-get 'signal x))))
          wifi))

(defun geolocation--here-xform-location (response)
  "Transform HERE's API response RESPONSE into the format needed."
  (let* ((r (request-response-data response))
         (loc (alist-get 'location r))
         (lat (alist-get 'lat loc))
         (lng (alist-get 'lng loc))
         (acc (alist-get 'accuracy loc)))
    (list (cons 'latitude lat)
          (cons 'longitude lng)
          (cons 'accuracy acc))))

(defun geolocation--here-get-token ()
  "Resolve the HERE Technologies API token.

If `geolocation-here-token' is non-nil, then use that.
Otherwise, retrieve the token via `auth-source-search' under the
hostname `geolocation-api-here-auth-source-host' and username
`geolocation-api-here-auth-source-user'."
  (or geolocation-api-here-token
      (auth-source-pick-first-password
       :host geolocation-api-here-auth-source-host
       :user geolocation-api-here-auth-source-user)))

(defun geolocation--call-here-api (wd callback)
  "Request location from HERE API using wifi data in the deferred WD.
Send results to a CALLBACK which is expected to store the
resulting location data.  Return a deferred object.

The implementation is a chain of deferreds with the following
steps executing on a separate thread:
  - transform wifi into the format HERE wants
  - call the HERE API with that wifi data
  - transform the HERE response into the alist object we need
  - attach a timestamp to the alist
  - invoke the callback with the alist"
  (let ((token (geolocation--here-get-token)))
    (deferred:$
      (deferred:nextc wd                ; chaining steps onto "wd"
        (lambda (wifi)
          (geolocation--here-xform-wifi wifi)))
      (deferred:nextc it
        (lambda (wifi)
          (geolocation--dbg 1 "geolocation--call-here-api:request")
          (request-deferred
           geolocation-api-here-url
           :type "POST"
           :params (list (cons "apiKey" token))
           :headers '(("Content-Type" . "application/json"))
           :data (json-encode (list (cons "wlan" wifi)))
           :parser #'json-read
           :timeout 15)))
      (deferred:nextc it
        (lambda (response)
          (if (= 200 (request-response-status-code response))
              (geolocation--here-xform-location response)
            (geolocation--dbg 0 "geolocation--call-here-api:error-thrown: %s"
                              (request-response-error-thrown response))
            (geolocation--dbg 0 "geolocation--call-here-api:status-code: %s"
                              (request-response-status-code response))
            nil)))
      (deferred:nextc it
        (lambda (location)
          (and location (geolocation--timestamp location))))
      (deferred:nextc it
        (lambda (location)
          (and location (funcall callback location)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unwired Labs geolocation api

(defgroup geolocation-api-unwiredlabs nil
  "Configuration needed to call the Unwired Labs Geolocation API."
  :prefix "geolocation-api-unwiredlabs-"
  :group 'geolocation)

(defcustom geolocation-api-unwiredlabs-url
  "https://us2.unwiredlabs.com/v2/process.php"
  "URL for the Unwired Labs Geolocation API."
  :type '(choice (const :tag "US Virginia"
                        "https://us1.unwiredlabs.com/v2/process.php")
                 (const :tag "US San Francisco"
                        "https://us2.unwiredlabs.com/v2/process.php")
                 (const :tag "EU France"
                        "https://eu1.unwiredlabs.com/v2/process.php")
                 (const :tag "AP Singapore"
                        "https://ap1.unwiredlabs.com/v2/process.php")
                 (string :tag "Other"))
  :group 'geolocation-api-unwiredlabs)

(defcustom geolocation-api-unwiredlabs-token nil
  "Authorization token for the Unwired Labs Geolocation API.

IMPORTANT NOTE: This customization is offered for the convenience
of people who want to quickly set up and test this package.
However you are strongly discouraged from leaving authorization
tokens (which are like passwords) in your Emacs configurations as
plainly readable text.  Setting this variable to nil will cause
the library to retrieve your token via `auth-source' instead."
  :type '(choice (const :tag "Retrieve token from `auth-source'" nil)
                 (string :tag "Unwired Labs API token"))
  :group 'geolocation-api-unwiredlabs)

(defcustom geolocation-api-unwiredlabs-auth-source-host "unwiredlabs.com"
  "The host name used for lookups in `auth-source'."
  :type '(string)
  :group 'geolocation-api-unwiredlabs)

(defcustom geolocation-api-unwiredlabs-auth-source-user "geolocation.el"
  "The user name used for lookups in `auth-source'."
  :type '(string)
  :group 'geolocation-api-unwiredlabs)

(defun geolocation--unwiredlabs-xform-location (response)
  "Transform Unwired Labs's API response RESPONSE into the format needed."
  (let* ((r (request-response-data response))
         (lat (alist-get 'lat r))
         (lng (alist-get 'lon r))
         (acc (alist-get 'accuracy r)))
    (list (cons 'latitude lat)
          (cons 'longitude lng)
          (cons 'accuracy acc))))

(defun geolocation--unwiredlabs-get-token ()
  "Resolve the Unwired Labs API token.

If `geolocation-api-unwiredlabs-token' is non-nil, then use that.
Otherwise, retrieve the token via `auth-source-search' under the
hostname `geolocation--unwiredlabs-auth-source-host' and username
`geolocation--unwiredlabs-auth-source-user'."
  (or geolocation-api-unwiredlabs-token
      (auth-source-pick-first-password
       :host geolocation-api-unwiredlabs-auth-source-host
       :user geolocation-api-unwiredlabs-auth-source-user)))

(defun geolocation--call-unwiredlabs-api (wd callback)
  "Request location from Unwired Labs API using wifi data in the deferred WD.
Send results to a CALLBACK which is expected to store the
resulting location data.  Return a deferred object.

The implementation is a chain of deferreds with the following steps
executing on a separate thread:
  - (unlike other APIs, no need to transform the wifi data)
  - call the Unwired API with the supplied wifi data
  - transform the Unwired response into the alist object we need
  - attach a timestamp to the alist
  - invoke the callback with the alist"
  (let ((token (geolocation--unwiredlabs-get-token)))
    (deferred:$
      (deferred:nextc wd                ; chaining steps onto "wd"
        (lambda (wifi)
          (geolocation--dbg 1 "geolocation--call-unwiredlabs-api:request")
          (request-deferred
           geolocation-api-unwiredlabs-url
           :type "POST"
           :data (json-encode
                  `(("token" . ,token)
                    ("wifi" . ,wifi)))
           :parser #'json-read
           :timeout 15)))
      (deferred:nextc it
        (lambda (response)
          (if (= 200 (request-response-status-code response))
              (geolocation--unwiredlabs-xform-location response)
            (geolocation--dbg 0 "geolocation--call-unwiredlabs-api:error-thrown: %s"
                              (request-response-error-thrown response))
            (geolocation--dbg 0 "geolocation--call-unwiredlabs-api:status-code: %s"
                              (request-response-status-code response))
            nil)))
      (deferred:nextc it
        (lambda (location)
          (and location (geolocation--timestamp location))))
      (deferred:nextc it
        (lambda (location)
          (and location (funcall callback location)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Public API

;;;###autoload
(defun geolocation-scan-wifi (&optional callback)
  "Scan wifi asynchronously and call (optional) CALLBACK with result.
Return a deferred object for chaining further operations."
  (cond
   ((string-equal system-type "darwin")
    (geolocation--osx-scan-wifi callback))
   ((string-equal system-type "windows-nt")
    (geolocation--windows-scan-wifi callback))
   ((string-equal system-type "gnu/linux")
    (geolocation--linux-scan-wifi callback))))

;;;###autoload
(defun geolocation-get-position (&optional callback)
  "Get a position in terms of latitude and longitude.
Return a deferred object for chaining further operations.  The
position is sent to CALLBACK as an alist with a structure
identical to `geolocation-location':
  latitude  : latitude of the current position
  longitude : longitude of the current position
  accuracy  : accuracy of the estimate in meters
  timestamp : timestamp when this position was found"
  (let ((wd (geolocation-scan-wifi)))
    (cond ((eq :google geolocation-api-vendor)
           (geolocation--call-google-api wd callback))
          ((eq :here geolocation-api-vendor)
           (geolocation--call-here-api wd callback))
          ((eq :unwiredlabs geolocation-api-vendor)
           (geolocation--call-unwiredlabs-api wd callback)))))

(defun geolocation-update-calendar ()
  "Update `calendar-latitude' and `calendar-longitude'.
This function is intended to be a `geolocation-update-hook'."
  (with-no-warnings
    (setq calendar-latitude (alist-get 'latitude geolocation-location))
    (setq calendar-longitude (alist-get 'longitude geolocation-location))))

(defun geolocation--update-position-callback (p)
  "Update `geolocation-location' to position P.
Then call the `geolocation-update-hook' functions."
  (setq geolocation-location p)
  (geolocation--dbg 1 "geolocation-location: %s" geolocation-location)
  (dolist (hook geolocation-update-hook)
    (funcall hook)))

(defvar geolocation--update-active nil
  "Controls the `geolocation--update-position-loop' iteration.
This var is managed by `geolocation-update-position' and need not
be set directly.")

(defun geolocation--update-position-loop ()
  "Call `geolocation-get-position' in a loop.
After each update store the result in `geolocation-location' and
run the `geolocation-update-hook' functions.  The loop interval
is controlled by `geolocation-update-interval', which can be
updated on the fly without stopping and restarting this loop."
  (deferred:$
    (deferred:call
      #'geolocation-get-position
      #'geolocation--update-position-callback)
    (deferred:wait (* geolocation-update-interval 1000))
    (deferred:nextc it
      (lambda ()
        (when geolocation--update-active
          (geolocation--update-position-loop))))))

;;;###autoload
(defun geolocation-update-position (&optional arg)
  "Start polling and updating the current position.
With a prefix argument ARG, stop after the next update."
  (interactive "P")
  (let ((start (not arg)))
    (cond ((and start geolocation--update-active) t) ; already running
          (start (setq geolocation--update-active t) ; start loop
                 (geolocation--update-position-loop)
                 t)
          (t (setq geolocation--update-active nil))))) ; else, stop loop

(provide 'geolocation)
;;; geolocation.el ends here
