slime-docker provides an easy bridge between SLIME and Lisps running in
Docker containers.  It can launch a container from an image, start a Lisp,
connect to it using SLIME, and set up filename translations (if the
slime-tramp contrib is enabled).

To get started, describe the Lisp implementations and Docker images you want
to use in the variable `slime-docker-implementations'.  Then, run
`slime-docker' and away you go.

The default image used by this package is clfoundation/cl-devel:latest
(https://hub.docker.com/r/clfoundation/cl-devel/)

SLIME is hard to use directly with Docker containers because its
initialization routine is not very flexible.  It requires that both Lisp and
Emacs have access to the same filesystem (so the port Swank is listening on
can be shared) and that the port Swank listens on is the same port to which
SLIME has to connect.  Neither of these are necessarily true with Docker.

This works around this by watching the stdout of the Lisp process to figure
out when Swank is ready to accept connections.  It also queries the Docker
daemon to determine which port 4005 has been forwarded to.
