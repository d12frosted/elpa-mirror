youtube-music.el is a YouTube Music client for Emacs.  It uses
`mpv' as its playback backend (over a JSON IPC socket) and -- in
later phases -- the YouTube Music internal API for browsing and
search.

The primary entry point is `M-x youtube-music', which pops a status
buffer styled after Magit: a Now Playing section, the upcoming
queue, and browseable sources.  Press `C-h m' inside the buffer to
see every key binding.

Phase 1 ships the playback skeleton:

  - spawn and supervise an `mpv' subprocess,
  - send commands and receive events over a UNIX-socket IPC channel,
  - track playback state via property observation,
  - render a status buffer with a magit-style sectioned layout,
  - display now-playing information in the global mode line.

Phase 2 adds the YouTube Music API client and search:

  - cookie-based authentication, stored in a 0600 credentials file,
  - signed youtubei/v1 POST requests with SAPISIDHASH auth,
  - `M-x youtube-music-search' to find songs and play one.

Phase 3 adds login/logout management and library browse:

  - `M-x youtube-music-auth' transient (login / logout / status),
  - `M-x youtube-music-liked'  to play your liked-songs list,
  - `M-x youtube-music-library-playlists' to pick and play a saved
    playlist,
  - `M-x youtube-music-library' transient that groups the above.

OAuth device flow is intentionally deferred: Google has been
restricting which client_ids may grant the YouTube Music scopes,
so the unofficial-OAuth path is currently unreliable.  The cookie
flow is robust and is used by `ytmusicapi' and `ytermusic' alike.

Required external programs: `mpv' and `yt-dlp'.
