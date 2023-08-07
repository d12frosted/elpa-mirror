fedi.el adapts mastodon-http.el from
<https://codeberg.org/martianh/mastodon.el> to make it easy to write
endpoint-hitting functions for JSON APIs.

It provides `fedi-request' to easily generate request functions, handles
constructing form data parameters and sending JSON payloads (for POST/PUT,
etc.).

Responses are checked with `fedi-http--triage', and processed with
`fedi-http--process-response'. If a response returns HTML, it is rendered
with `shr', otherwise the JSON is pased and returned.

Because of mastodon.el works, there is also code for handling link headers
in responses. Mastodon uses these for pagination in some cases. If your
service also des, you can handle them too.
