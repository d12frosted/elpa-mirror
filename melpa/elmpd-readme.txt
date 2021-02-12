"Music Player Daemon (MPD) is a flexible, powerful, server-side
application for playing music." <https://www.musicpd.org/>.
`elmpd' is a tight, ergonomic, asynchronous MPD client library in
Emacs Lisp.

See also `libmpdel' <https://gitea.petton.fr/mpdel/libmpdel>,
`libmpdee' <https://github.com/andyetitmoves/libmpdee> and the
`mpc' package which ships with Emacs beginning with version 23.2.

Create an MPD connection by calling `elmpd-connect'; this will
return an `elmpd-connection' instance immediately.  Asynchronously,
it will be parsing the MPD greeting message, perhaps sending an
initial password, and if so requested, sending the "idle" command.

There are two idioms I've seen in MPD client libraries for sending
commands while receiving notifications of server-side changes:

    1. just maintain two connections (e.g. mpdfav
       <https://github.com/vincent-petithory/mpdfav>); issue the
       "idle" command on one, send commands on the other

    2. use one connection, issue the "idle" command, and when asked
       to issue another command, send "noidle", issue the
       requested command, collect the response, and then send
       "idle" again (e.g. `libmpdel').  Note that this is not a
       race condition per
       https://www.musicpd.org/doc/html/protocol.html#idle -- any
       server-side changes that took place while processing the
       command will be saved & returned on "idle"

Since `elmpd' is a library, I do not make that choice here, but
rather support both styles.

The implementation is callback-based; each connection comes at the
cost of a single socket plus whatever memory is needed to do the
text processing in handling command responses.  In particular, I
declined to use `tq' despite the natural fit because I didn't want
to use a buffer for each connection, as well.
