A bridge from ical to calfw.
The API and interfaces have not been confirmed yet.

; Installation:

Here is a minimum sample code:
(require 'calfw-ical)
To open a calendar buffer, execute the following function.
(cfw:open-ical-calendar "http://www.google.com/calendar/ical/.../basic.ics")

Executing the following command, this program clears caches to refresh the ICS data.
(cfw:ical-data-cache-clear-all)
