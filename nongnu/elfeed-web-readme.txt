                         ━━━━━━━━━━━━━━━━━━━━━━
                          ELFEED WEB INTERFACE
                         ━━━━━━━━━━━━━━━━━━━━━━


This is a demonstration/toy web interface for Elfeed remote network
access. It's a single-page web application that follows the database
live as new entries arrive. It's packaged separately as `elfeed-web'. To
fire it up, run `M-x elfeed-web-start' and visit
<http://localhost:8080/elfeed/> (check your `httpd-port') with a
browser. See the `elfeed-web.el' header for endpoint documentation if
you'd like to access the Elfeed database through the web API.

It's rough and unfinished – no keyboard shortcuts, read-only, no
authentication, and a narrow entry viewer. This is basically Elfeed's
"mobile" interface. Patches welcome.
