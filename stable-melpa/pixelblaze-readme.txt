Interact with a Pixelblaze LED controller using the Websocket API
(Reference: https://www.bhencke.com/pixelblaze-advanced#Websocket-API)
Set display pattern, brightness, controls and variables.
Query configuration, set of patterns, controls and variables.

Example:

(let ((pb pixelblaze-open "pixelblaze.local"))
  (pixelblaze-set-pattern pb "rainbow fonts")
  (pixelblaze-set-brightness pb 0.25)
  (pixelblaze-close pb))
