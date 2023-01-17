This mode enables interaction with a Home Assistant instance from within Emacs.

--------------------
Configuration

Both `hass-host' and `hass-apikey' must be set to use this package.

(setq hass-host "192.168.1.10") ; Required
(setq hass-insecure t) ; If using HTTP and not HTTPS
(setq hass-port 8123) ; If using a different port other than the default 8123
(setq hass-apikey "APIKEY-GOES-IN-HERE") ; Required.  See below.

Getting an API Key:
Ensure that your Home Assistant instance is configured to support API calls by following the
instructions here: `https://www.home-assistant.io/integrations/api/'.

Retrieve your API key a.k.a. /Long-Lived Access Token/ by logging into your Home Assistant
instance and going to your profile by selecting your username in the lower-left corner or going
to this URL: `http://HOME-ASSISTANT-URL:8123/profile'.  You can generate an API token at the very
bottom of this page.

--------------------
Usage

Use `hass-call-service' to make service calls on the configured Home Assistant instance:

(hass-call-service "switch.bedroom_light" "switch.toggle")

Or use `hass-call-service-with-payload' to customize the payload:
(hass-call-service-with-payload
 "mqtt.publish"
 (json-encode '(("payload" . "PERFORM")
                ("topic" . "valetudo/vacuum/LocateCapability/locate/set"))))

See README.org for more information.
