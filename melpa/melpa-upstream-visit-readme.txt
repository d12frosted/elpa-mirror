This package provides an interactive command to `browse-url' a
melpa-hosted package's homepage.

To (try to) visit a package's homepage, just
  M-x muv RET package-name RET
and the package's homepage (actually, its repo page) will be hopefully
opened in your browser.

The list of kludges used to guess the package's homepage is stored
in `muv:url-kludges', a variable that you can customize with your
own functions.

These functions are applied to a melpa recipe and return a string
containing the URL of the package - note that here applied refers
to `apply'.  See `muv::github-kludge' for an example.

The kludges in the list are applied in order until one of them
returns non-nil. The first non-nil result is then interpreted
as the URL to be visited.

Customization
-------------

If `muv:enable-muv-button' is non nil - the default - a
Visit Homepage button will be show in the package description.
The button can be disabled by customizing `muv:enable-muv-button',
and can be customized via the customization variables
`muv:button-face' and `muv:button-label'.

Thank yous:
-- milkypostman for melpa :-)
-- dgutov for thing-at-point integration
