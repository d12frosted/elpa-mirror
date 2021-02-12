A web server in Emacs running handlers written in Emacs Lisp.

Full support for GET and POST requests including URL-encoded
parameters and multipart/form data.  Supports web sockets.

See the examples/ directory for examples demonstrating the usage of
the Emacs Web Server.  The following launches a simple "hello
world" server.

    (ws-start
     '(((lambda (_) t) .                         ; match every request
        (lambda (request)                        ; reply with "hello world"
          (with-slots (process) request
            (ws-response-header process 200 '("Content-type" . "text/plain"))
            (process-send-string process "hello world")))))
     9000)
