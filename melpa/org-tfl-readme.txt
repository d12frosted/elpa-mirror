Use the Transport For London API in Emacs, powered by org-mode.
For ambiguous results, `completing-read' is now used instead of helm.

Commands:

Below are complete command list:

 `org-tfl-jp'
   Plan a journey and view the result in a buffer.
 `org-tfl-jp-org'
   Plan a journey and insert a subheading with a special link.
   The content is the journey result.  Open the link to update it.
   Use the scheduling function of org mode to change the date.
   All other options are set via properties.

Customizable Options:

Below are customizable option list:

 `org-tfl-api-id'
   Your Application ID for the TfL API.  You don't need one
   for personal use.  It's IP locked anyway.
 `org-tfl-api-key'
   Your Application KEY for the TfL API.  You don't need one
   for personal use.  It's IP locked anyway.
 `org-tfl-map-width'
   The width in pixels of static maps.
 `org-tfl-map-height'
   The height in pixels of static maps.
 `org-tfl-map-type'
   The map type.  E.g. "roadmap", "terrain", "satellite", "hybrid".
 `org-tfl-map-path-color'
   The color of the path of static maps.
 `org-tfl-map-path-weight'
   The storke weight of paths of static maps.
 `org-tfl-map-start-marker-color'
   The path color of static maps.
 `org-tfl-map-start-marker-color'
   The start marker color of static maps.
 `org-tfl-map-end-marker-color'
   The end marker color of static maps.
 `org-tfl-time-format-string'
   The format string to display time.
 `org-tfl-date-format-string'
   The format string to display dates.

Installation:

Add the following to your Emacs init file:

(require 'org-tfl)
