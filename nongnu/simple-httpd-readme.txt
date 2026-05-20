                             ━━━━━━━━━━━━━━
                              SIMPLE-HTTPD
                             ━━━━━━━━━━━━━━


A simple Emacs web server.

This used to be `httpd.el' but there are already several of these out
there already of varying usefulness. The server can serve files,
directory listings and custom servlets. Client requests are sanitized,
but the server is vulnerable to denial of service attacks, so it should
only be used for local development or automation. We make no guarantees
regarding security.

This package is available on [MELPA] and [ELPA].


[MELPA] <https://melpa.org/>

[ELPA] <https://nongnu.elpa.org/>


1 Usage
═══════

  Once loaded, there are only two interactive functions to worry about:
  `httpd-start' and `httpd-stop'. By default, files are served from
  `httpd-root' on port `httpd-port'. To disable, set `httpd-serve-files'
  to `nil'. Directory listings are enabled by default but can be
  disabled by setting `httpd-listings' to `nil'.

  ┌────
  │ (require 'simple-httpd)
  │ (setq httpd-root "/var/www")
  │ (httpd-start)
  └────


2 Servlets
══════════

  Servlets can be defined with `httpd-servlet'. They are enabled by
  default but can be disabled by setting `httpd-servlets' to `nil'. This
  one creates at servlet at `/hello-world' that says hello.

  ┌────
  │ (httpd-servlet hello-world text/plain (path)
  │   (insert "hello, " (file-name-nondirectory path)))
  └────

  Another example at `/greeting/<name>' with optional parameter
  `?greeting=<greeting>'.

  ┌────
  │ (httpd-servlet* greeting/:name text/plain ((greeting "hi" greeting-p))
  │   (insert (format "%s, %s (provided: %s)" greeting name greeting-p)))
  └────

  See the comment header in `simple-httpd.el' for full details.


3 Unit tests
════════════

  The unit tests can be run with `make test'. The tests do some mocking
  to avoid using network code during testing.


4 Related packages
══════════════════

  Packages built on simple-httpd:

  • [skewer-mode]
  • [impatient-mode]
  • [airplay]
  • [elfeed-web]


[skewer-mode] <https://github.com/skeeto/skewer-mode>

[impatient-mode] <https://github.com/netguy204/imp.el>

[airplay] <https://github.com/gongo/airplay-el>

[elfeed-web] <https://github.com/skeeto/elfeed>
