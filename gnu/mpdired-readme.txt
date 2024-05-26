This a client for the Music Player Daemon (mpd) with interactions
inspired from Dired.  It features two views packed into the same
interactive buffer: the browser view and the queue view.

In those views, most of the interactions are mimic after Dired mode
with marks and action on them.  For example, in the queue view, you
could flag songs for removal with `d' and then issue the deletion
from the queue with `x'.  In the browser view, you could mark songs
or directories with `m' and then append them to the queue with `a'.

Usage:

Just do "M-x mpdired".  It will pop you to a MPDired buffer in the
queue view by default.  To alternate between the queue view and the
browser view hit `o'.

MPDired connects to a MPD server using two customs: `mpdired-host'
and `mpdired-port'.  Those customs defaults to your MPD_HOST and
MPD_PORT environment variables or to "localhost" and 6600 if these
are not set.

Once connected, the handle to the server is saved in a buffer local
variable into the MPDired buffer.  From now on, the customs are
just used by global MPDired commands to connect to the user defined
server.  All commands used inside a MPDired buffer will connect to
the buffer local server.  This way, you can manage more than one
MPD server with multiple MPDired buffers.

Philosophy:

MPDired is designed to be the least intrusive.  Nothing will be
shown into the mode line, which I consider to be user's territory.
There is also no timers set by MPDired, so updating anything always
comes from a user's action.

The browser view is built from the MPD's "listall" and
"listplaylists" commands.  The MPD's documentation does *not*
recommend to do so but AFAIU there is no other way to access your
music collection in terms of directories and files.  As my music
collection is already ordered into directories and with meaningful
filenames, I prefer to use this interface rather then to rely on
files' tags.

Be aware that if your music collection consists of just a set of
not very well named files into one big directory and that you rely
on tags such as "Genre", "Album", "Artist" to find your way through
it then, maybe, MPDired is not the right client for you.