
docker-cli provides mode for running commands within Docker
containers in Emacs buffer.  Package comes with few predefined
commands for running PostgreSQL, Redis and MySQL clients.  Package
can easily be extended with new commands by adding elements to
`docker-cli-commands-alist'.  Command is ran with interactive
function `docker-cli-run-cmd` which, after selecting command and
container from the list, executes given command in the target
Docker container.
