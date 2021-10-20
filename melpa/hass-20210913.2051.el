;;; hass.el --- Interact with Home Assistant -*- lexical-binding: t; -*-

;; Package-Requires: ((emacs "25.1") (request "0.3.3"))
;; Package-Version: 20210913.2051
;; Package-Commit: f7a24c34631aa09fb7bc5bd13e8e4037e256730a
;; Version: 1.2.1
;; Author: Ben Whitley
;; SPDX-License-Identifier: MIT
;;; Commentary:

;; This mode enables interaction with a Home Assistant instance from within Emacs.

;; --------------------
;; Configuration

;; Both `hass-url' and `hass-apikey' must be set to use this package.

;; (setq hass-url "https://192.168.1.10:8123"
;;       hass-apikey "APIKEY-GOES-IN-HERE"
;; (hass-setup)

;; Getting an API Key:
;; Ensure that your Home Assistant instance is configured to support API calls by following the
;; instructions here: `https://www.home-assistant.io/integrations/api/'.

;; Retrieve your API key a.k.a. /Long-Lived Access Token/ by logging into your Home Assistant
;; instance and going to your profile by selecting your username in the lower-left corner or going
;; to this URL: `http://HOME-ASSISTANT-URL:8123/profile'.  You can generate an API token at the very
;; bottom of this page.

;; --------------------
;; Usage

;; Use `hass-call-service' to make service calls on the configured Home Assistant instance:

;; (hass-call-service "switch.bedroom_light" "switch.toggle")

;; Or use `hass-call-service-with-payload' to customize the payload:
;; (hass-call-service-with-payload
;;  "mqtt.publish"
;;  (json-encode '(("payload" . "PERFORM")
;;                 ("topic" . "valetudo/vacuum/LocateCapability/locate/set"))))

;; Watching entities:

;; To react to changes in entity states, enable `hass-watch-mode' This mode will periodically poll
;; the Home Assistant instance to get the state of entities listed in `hass-watch-entities'.

;; (setq hass-watch-entities '("switch.bedroom_light" "switch.bedroom_fan"))
;; (hass-watch-mode 1)

;; Use the function hook `hass-entity-state-updated-functions' to react to changes in entity state:

;; (add-hook 'hass-entity-state-updated-functions
;;   (lambda (entity-id)
;;     (message "The entity %s state has changed to %s." entity-id (hass-state-of entity-id))))

;; See README.org for more information.
;;
;; Homepage: https://github.com/purplg/hass

;;; Code:
(require 'json)
(require 'request)

(defgroup hass '()
  "Minor mode for hass."
  :group 'hass
  :prefix "hass-")


;; Customizable
(defvar hass-watch-mode-map (make-sparse-keymap)
  "Keymap for hass mode.")

(defcustom hass-url nil
  "The URL of the Home Assistant instance.
Set this to the URL of the Home Assistant instance you want to
control.  (e.g. https://192.168.1.10:8123)"
  :group 'hass
  :type 'string)

(defcustom hass-apikey nil
  "API key used for Home Assistant queries.
The key generated from the Home Assistant instance used to authorize API
requests"
  :group 'hass
  :type 'string)

(defcustom hass-watch-entities nil
  "A list of tracked Home Assistant entities.
Set this to a list of Home Assistant entity ID strings.  An entity ID looks
something like *switch.bedroom_light*."

  :group 'hass
  :type '(repeat string))

(defcustom hass-watch-frequency 60
  "Amount of seconds between watching HASS-ENTITIES."
  :group 'hass
  :type 'integer)


;; Hooks
(defvar hass-entity-state-updated-functions nil
 "List of functions called when an entity state changes.
Each function is called with one arguments: the ENTITY-ID of the
entity whose state changed.")

(defvar hass-entity-state-refreshed-hook nil
 "Hook called after an entity state data was received.")

(defvar hass-service-called-hook nil
 "Hook called after a service has been called.")


;; Internal state
(defvar hass--states '()
  "An alist of entity ids to their last queried states.")

(defvar hass--user-agent "Emacs hass.el"
  "The user-agent sent in API requests to Home Assistant.")

(defvar hass--timer nil
  "Stores a reference to the timer used to periodically update entity state.")

(defvar hass--available-entities nil
  "The entities retrieved from the Home Assistant instance.")

(defvar hass--available-services nil
  "The services retrieved from the Home Assistant instance.")


;; Helper functions
(defun hass--apikey ()
  "Return the effective apikey.
If HASS-APIKEY is a function, execute it to get value.  Otherwise
return HASS-APIKEY as is."
  (if (functionp hass-apikey)
      (funcall hass-apikey)
      hass-apikey))

(defun hass--entity-url (entity-id)
  "Generate entity state endpoint URLs.
ENTITY-ID is a string of the entities ID."
  (format "%s/%s/%s" hass-url "api/states" entity-id))

(defun hass--service-url (service)
  "Generate service endpoint URL.
SERVICE is a string of the service to call."
  (let* ((parts (split-string service "\\."))
         (domain (pop parts))
         (service (pop parts)))
    (format "%s/api/services/%s/%s" hass-url domain service)))

(defun hass--domain-of-entity (entity-id)
  "Convert an ENTITY-ID to its respective domain."
  (car (split-string entity-id "\\.")))

(defun hass--services-for-entity (entity-id)
  "Return the services available for an ENTITY-ID."
  (cdr (assoc (hass--domain-of-entity entity-id) hass--available-services)))

(defun hass-state-of (entity-id)
  "Return the last known state of ENTITY-ID."
  (cdr (assoc entity-id hass--states)))


;; API parsing
(defun hass--parse-all-entities (entities)
  "Convert entity state data into a list of available entities.
ENTITIES is the data returned from the `/api/states' endpoint."
  (delq nil (mapcar (lambda (entity) (hass--parse-entity entity))
                    entities)))

(defun hass--parse-entity (entity-state)
  "Convert an entity's state data into its entity-id.
ENTITY-STATE is an individual entity state data return from the
`/api/states' endpoint.

Only returns entities that have callable services available."
  (let ((entity-id (cdr (car entity-state))))
    (when (hass--services-for-entity entity-id)
      entity-id)))

(defun hass--parse-all-domains (domains)
  "Collect DOMAINS into an alist of their associated services.
DOMAINS is the data returned from the `/api/services' endpoint."
  (mapcar #'hass--parse-domain domains))

(defun hass--parse-domain (domain)
  "Convert DOMAIN into cons cell of its available list of services.
DOMAIN is a single domain return from the `/api/services'
endpoint."
  (cons (cdr (assoc 'domain domain))
        (hass--parse-services (cdr (assoc 'services domain)))))
  
(defun hass--parse-services (services)
  "Flattens the SERVICES return from `/api/services' endpoint to just the service name."
  (mapcar (lambda (service) (car service))
          services))


;; Request Callbacks
(defun hass--get-entities-result (entities)
  "Callback when states of all ENTITIES is received from API."
  (setq hass--available-entities (hass--parse-all-entities entities)))

(defun hass--get-available-services-result (domains)
  "Callback when all service information is received from API.
DOMAINS is the response from the `/api/services' endpoint which
returns a list of domains and their available services."
  (setq hass--available-services (hass--parse-all-domains domains)))

(defun hass--query-entity-result (entity-id state)
  "Callback when an entity state data is received from API.
ENTITY-ID is the id of the entity that has STATE."
  (let ((previous-state (hass-state-of entity-id)))
    (setf (alist-get entity-id hass--states nil nil 'string-match-p) state)
    (unless (equal previous-state state)
      (run-hook-with-args 'hass-entity-state-updated-functions entity-id)))
  (run-hooks 'hass-entity-state-refreshed-hook))

(defun hass--call-service-result (entity-id state)
  "Callback when a successful service request is received from API.
ENTITY-ID is the id of the entity that was affected and now has STATE."
  (setf (alist-get entity-id hass--states nil nil 'string-match-p) state)
  (run-hooks 'hass-service-called-hook))

(cl-defun hass--request-error (&key error-thrown &allow-other-keys)
  "Error handler for invalid requests.
ERROR-THROWN is the error thrown from the request.el request."
  (let ((error (cdr error-thrown)))
    (cond ((string= error "exited abnormally with code 7\n")
           (user-error "Hass: No Home Assistant instance detected at url: %s" hass-url))
          ((string= error "exited abnormally with code 35\n")
           (user-error "Hass: Did you mean to use HTTP instead of HTTPS for url %s?" hass-url))
          ((error "Hass: unknown error: %S" error-thrown)))))


;; Requests
(defun hass--request (type url &optional success payload)
  "Function to reduce a lot of boilerplate when making a request.
TYPE is a string of the type of request to make.  For example, `\"GET\"'.

URL is a string of URL of the request.

SUCCESS is a callback function for when the request successful
completed.

PAYLOAD is contents the body of the request."
  (request url
       :sync nil
       :type type
       :headers `(("User-Agent" . hass--user-agent)
                  ("Authorization" . ,(concat "Bearer " (hass--apikey)))
                  ("Content-Type" . "application/json"))
       :data payload
       :parser #'json-read
       :error #'hass--request-error
       :success success))

(defun hass--get-available-entities (&optional callback)
  "Retrieve the available entities from the Home Assistant instance.
Makes a request to `/api/states' but drops everything except an
list of entity-ids.
Optional argument CALLBACK ran after entities are received."
  (hass--request "GET" (concat hass-url "/api/states")
     (cl-function
       (lambda (&key response &allow-other-keys)
         (let ((data (request-response-data response)))
           (hass--get-entities-result data))
         (when callback (funcall callback))))))

(defun hass--get-available-services (&optional callback)
  "Retrieve the available services from the Home Assistant instance.
Optional argument CALLBACK ran after services are received."
  (hass--request "GET" (concat hass-url "/api/services")
     (cl-function
       (lambda (&key response &allow-other-keys)
         (let ((data (request-response-data response)))
           (hass--get-available-services-result data))
         (when callback (funcall callback))))))

(defun hass--get-entity-state (entity-id)
  "Retrieve the current state of ENTITY-ID from the Home Assistant server."
  (hass--request "GET" (hass--entity-url entity-id)
    (cl-function
      (lambda (&key response &allow-other-keys)
        (let ((data (request-response-data response)))
          (hass--query-entity-result entity-id (cdr (assoc 'state data))))))))

(defun hass--call-service (service payload &optional success-callback)
  "Call service SERVICE for ENTITY-ID on the Home Assistant server.

SERVICE is a string of the Home Assistant service to be called.

PAYLOAD is a JSON-encoded string of the payload to be sent with SERVICE.

SUCCESS-CALLBACK is a function to be called with a successful request response."
  (hass--request "POST"
                 (hass--service-url service)
                 success-callback
                 payload))

(defun hass-call-service (entity-id service)
  "Call service for an entity on Home Assistant.
If called interactively, prompt the user for an ENTITY-ID and
SERVICE to call.

This will send an API request to the url configure in `hass-url'.

ENTITY-ID is a string of the entity id in Home Assistant you want
to call the service on.  (e.g. `\"switch.kitchen_light\"').

SERVICE is the service you want to call on ENTITY-ID.  (e.g. `\"turn_off\"')"
  (interactive
    (let ((entity (completing-read "Entity: " hass--available-entities nil t)))
      (list entity
            (format "%s.%s"
                    (hass--domain-of-entity entity)
                    (completing-read (format "%s: " entity) (hass--services-for-entity entity) nil t)))))
  (hass-call-service-with-payload
   service
   (format "{\"entity_id\": \"%s\"}" entity-id)
   (lambda (&rest _) (hass--get-entity-state entity-id))))

(defun hass-call-service-with-payload (service payload &optional success-callback)
  "Call service with a custom payload on Home Assistant.
This will send an API request to the url configure in `hass-url'.

SERVICE is a string of the Home Assistant service to be called.

PAYLOAD is a JSON-encoded string of the payload to be sent with SERVICE.

SUCCESS-CALLBACK is a function to be called with a successful request response."
  (hass--call-service
   service
   payload
   (lambda (&rest _)
     (run-hooks 'hass-service-called-hook)
     (when success-callback (funcall success-callback)))))


;; Watching
;;;###autoload
(define-minor-mode hass-watch-mode
  "Toggle mode for querying Home Assistant periodically.
Watching is a way to periodically query the state of entities you
want to hook into to capture when their state changes.

Use the variable `hass-watch-frequency' to change how
frequently (in seconds) the Home Assistant instance should be
queried.

Use the variable `hass-watch-entities' to set which entities you want
to query automatically."
  :lighter nil
  :group 'hass
  :global t
  (when hass--timer (hass-watch--cancel-timer))
  (when hass-watch-mode
    (hass--get-available-services 'hass--get-available-entities)
    (when hass--timer (hass-watch--cancel-timer))
    (setq hass--timer (run-with-timer
                       nil
                       hass-watch-frequency
                       'hass-watch--query-entities))))

(defun hass-watch--cancel-timer ()
  "Cancel watch without disabling it."
  (when hass--timer
    (cancel-timer hass--timer)
    (setq hass--timer nil)))

(defun hass-watch--query-entities ()
  "Update the current state all of the registered entities."
  (dolist (entity hass-watch-entities)
    (hass--get-entity-state entity)))


;;;###autoload
(defun hass-setup ()
  "Run before using any hass features.
Check whether necessary variables are set and then query the Home
Assistant instance for available services and entities."
  (cond ((not (equal (type-of (hass--apikey)) 'string))
         (user-error "HASS-APIKEY must be set to use hass"))
        ((not (equal (type-of hass-url) 'string))
         (user-error "HASS-URL must be set to use hass"))
        ((hass--get-available-services 'hass--get-available-entities))))

(provide 'hass)

;;; hass.el ends here
