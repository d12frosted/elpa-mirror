This is an attempt to optimize Tramp remote editing with slow
connection by building higher level core lisp functions as Tramp
operations.  The idea is to reduce round trips by doing more on the
server in one request.  It applies only to shell-based remote
connections, as declared in tramp-sh.el and tramp-container.el.

In order to enable it, call \\[tramp-hlo-setup].