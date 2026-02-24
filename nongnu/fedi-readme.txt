1 fedi.el
═════════

  A library to make writing clients for APIs easier.

  It uses code originally ported from [mastodon.el] to make it easy to
  write requests for JSON APIs and build client interfaces.


[mastodon.el] <https://codeberg.org/martianh/mastodon.el>


2 http layer
════════════

  The example macro `fedi-request' allows you to quickly create HTTP
  requests to API endpoints, with parameters automatically constructed
  and sent as form data or JSON payloads (for POST, PUT, DELETE, and
  PATCH). You should write your own similar macro in your package. For a
  working example, see the [lem-request] macro. That way you can handle
  package-specific parameters such as authentication.

  Responses are checked with `fedi-http--triage', and processed with
  `fedi-http--process-response'. If a response returns HTML (i.e. for a
  404), it is rendered with `shr', otherwise the JSON is parsed and
  returned.

  Because of how `mastodon.el' works, there is also code for handling
  link headers in responses. Mastodon uses these for pagination in some
  cases. If your service also does, you can handle them too.


[lem-request]
<https://codeberg.org/martianh/lem.el/src/commit/25def6d187caa2bfac238469de81dbaecef757ec/lisp/lem-request.el#L36>


3 utilities
═══════════

  `fedi.el' contains functions for:

  • setting up a new view buffer
  • navigating between items
  • displaying icons
  • completing-read action functions
  • handling action responses
  • updating item display after action
  • rendering propertized links for special items (user handles,
    hashtags, etc.)
  • formatting headings
  • webfinger lookup of URLs
  • and live-updating, human-readable timestamps.


4 posting
═════════

  `fedi-post.el' contains functions for rich composing of posts. It
  supports:

  • pretty display of available bindings
  • toggling post flags like NSFW
  • completion of items like handles and tags.


5 transient menus
═════════════════

  If you want to create transient menus to POST, PUT or PATCH complex
  data to a server, take a look at `tp.el'.


6 clients using `fedi.el'
═════════════════════════

  • [lem.el] (Lemmy client)
  • [fj.el] (Forgejo client)


[lem.el] <https://codeberg.org/martianh/lem.el>

[fj.el] <https://codeberg.org/martianh/fj.el>


7 contributing
══════════════

  If you're making an Emacs client for a fediverse (or similar API)
  service and interested in using this library, don't hesitate to get in
  touch. It's easy to adapt for the sake of other needs.
