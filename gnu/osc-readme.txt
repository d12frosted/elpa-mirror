OpenSound Control ("OSC") is a protocol for communication among
computers, sound synthesizers, and other multimedia devices that is
optimized for modern networking technology and has been used in many
application areas.

This package implements low-level functionality for OSC clients and servers.
In particular:
* `osc-make-client' and `osc-make-server' can be used to create process objects.
* `osc-send-message' encodes and sends OSC messages from a client process.
* `osc-server-set-handler' can be used to change handlers for particular
  OSC paths on a server process object on the fly.

Usage:

Client: (setq my-client (osc-make-client "127.0.0.1" 7770))
        (osc-send-message my-client "/osc/path" 1.5 1.0 5 "done")
        (delete-process my-client)

Server: (setq my-server (osc-make-server "127.0.0.1" 7770
         (lambda (path &rest args)
           (message "OSC %s: %S" path args))))