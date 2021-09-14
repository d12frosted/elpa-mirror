This mode enables interaction with a Home Assistant instance from within Emacs.

--------------------
Configuration

Both `hass-url' and `hass-apikey' must be set to use this package.

(setq hass-url "https://192.168.1.10:8123"
      hass-apikey "APIKEY-GOES-IN-HERE"
(hass-setup)

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

Watching entities:

To react to changes in entity states, enable `hass-watch-mode' This mode will periodically poll
the Home Assistant instance to get the state of entities listed in `hass-watch-entities'.

(setq hass-watch-entities '("switch.bedroom_light" "switch.bedroom_fan"))
(hass-watch-mode 1)

Use the function hook `hass-entity-state-updated-functions' to react to changes in entity state:

(add-hook 'hass-entity-state-updated-functions
  (lambda (entity-id)
    (message "The entity %s state has changed to %s." entity-id (hass-state-of entity-id))))

See README.org for more information.

Homepage: https://github.com/purplg/hass
