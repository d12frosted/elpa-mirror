A command line paste server with Emacs highlighting in the style of
sprunge.  Pastes may be submitted to the server from the command
line using `curl' as follows.

    <command> | curl -s -F 'sprunge=<-' %s

The server will respond with the path at which the URL is
available.  To enable syntax highlighting append "?foo" to the
returned URL and the server will return the paste highlighted with
"foo-mode".

Designed to be easily run with `make start'.  When run with make
following environment may be used to customize the server's
behavior.

  EMACS ---- change the Emacs executable used to run the server
  PORT ----- port on which the server will listen for connections
  SERVER --- server name
  THEME ---- Emacs color theme used for fontified pastes
  DOCROOT -- directory in which to store pastes

Requires htmlize [1] and the Emacs web-server [2].

  [1] http://fly.srk.fer.hr/~hniksic/emacs/htmlize.el.cgi
  [2] https://github.com/eschulte/emacs-web-server
