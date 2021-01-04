Interface to a Transmission session.

Entry points are the `transmission' and `transmission-add'
commands.  A variety of commands are available for manipulating
torrents and their contents, many of which can be applied over
multiple items by selecting them with marks or within a region.
The menus for each context provide good exposure.

"M-x transmission RET" pops up a torrent list.  One can add,
start/stop, verify, remove torrents, set speed limits, ratio
limits, bandwidth priorities, trackers, etc.  Also, one can
navigate to the corresponding file list, torrent info, or peer info
contexts.  In the file list, individual files can be toggled for
download, and their priorities set.

Customize-able are: the session address components, RPC
credentials, the display format of dates, file sizes and transfer
rates, pieces display, automatic refreshing of the torrent
list, etc.  See the `transmission' customization group.

The design draws from a number of sources, including the command
line utility transmission-remote(1), the ncurses interface
transmission-remote-cli(1), and the rtorrent(1) client.  These can
be found respectively at the following:
<https://github.com/transmission/transmission/blob/master/utils/remote.c>
<https://github.com/fagga/transmission-remote-cli>
<https://rakshasa.github.io/rtorrent/>

Originally based on the JSON RPC library written by Christopher
Wellons, available online at <https://github.com/skeeto/elisp-json-rpc>.
