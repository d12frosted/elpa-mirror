
This is an elisp version of the popular node.js asynchronous
webserver toolkit.

You can define HTTP request handlers and start an HTTP server
attached to the handler.  Many HTTP servers can be started, each
must have its own TCP port.  Handlers can defer processing with a
signal (which allows comet style resource management)

See elnode-start for how to start an HTTP server.
