Some functions, classes and methods to make it easier to create
transient menus that send complex POST, PUT, or PATCH requests to JSON
APIs.

A typical use-case is where you have a single endpoint that takes many
different parameters. It's handy for a user to be able to set all the
options, then make a single request to change all the settings on the
server. It's also expected that they'll be able to view all the current
settings on the server, and make modifications to them for sending.

The classes and methods define some transient behaviours that make
sense for dealing with APIs:

- We handle fetching and saving current server settings, and initialize
our transients with the values fetched
- We compare the state of a current transient option against the server
values
- We distinguish the formatting of server settings and current transient
setting
- When reading a string from the user, we provide the server setting as
default input
- We can seemlessly handle making requests with arrays, i.e. =source[key]=,
or =field[1][name]= parameters
- We can easily fetch an infix's allowed values for =completing-read=
- We (ususally) only send changed values to the server.
