A music client for Subsonic-compatible servers (Navidrome, Gonic,
...) and Music Assistant: browse artists, albums, album lists and
podcasts, search, and manage a play queue from Emacs.

Playback happens locally through mpv, or remotely on the Subsonic
server's jukebox, a UPnP/DLNA renderer or a Music Assistant player.
Start with `M-x supersonic'; see the README for configuration.

mpv is driven over a Unix-domain socket, so local playback does not
work on native Windows.
