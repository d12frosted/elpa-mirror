1 fedi.el
═════════

  A library to make writing clients for APIs easier.

  It uses code from my [mastodon.el] to make it easy to write
  endpoint-hitting functions for JSON APIs, and to easily build
  interfaces.


[mastodon.el] <https://codeberg.org/martianh/mastodon.el>


2 http layer
════════════

  The example macro `fedi-request' allows you to quickly create HTTP
  request commands to API endpoints, with parameters automatically
  constructed and sent as form data or JSON payloads (for POST, PUT,
  DELETE, and probably PATCH). You should write your own similar macro
  in your package. See my `lem.el' for a working example. That way you
  can handle package-specific parameters such as authentication.

  Responses are checked with `fedi-http--triage', and processed with
  `fedi-http--process-response'. If a response returns HTML (i.e. for a
  404), it is rendered with `shr', otherwise the JSON is parsed and
  returned.

  Because of how `mastodon.el' works, there is also code for handling
  link headers in responses. Mastodon uses these for pagination in some
  cases. If your service also does, you can handle them too.

  For an example of using this library, see my [lem.el] repo.


[lem.el] <https://codeberg.org/martianh/lem.el>


3 utilities
═══════════

  `fedi.el' contains functions for:

  • setting up a new client buffer
  • navigating between items
  • displaying icons
  • completing-read action functions
  • handling action responses
  • updating item display after action
  • formatting headings
  • webfinger lookup of URLs
  • and live-updating timestamps.


4 posting
═════════

  `fedi-post.el' contains functions for rich composing of posts. It
  supports pretty display of available bindings, toggling post flags
  like NSFW, and completion of items like handles and tags.


5 contributing
══════════════

  If you're making an Emacs to a fediverse (or similar) service and
  interested in using this library, don't hesitate to get in touch. The
  library was only created to port code from `mastodon.el' to `lem.el',
  but could happily be further adapted to accommodate other projects.
