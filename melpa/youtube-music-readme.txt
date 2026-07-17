youtube-music.el is a YouTube Music client for Emacs.  Playback is
handled by an `mpv' subprocess, controlled over a JSON IPC socket;
browsing and search talk to the YouTube Music API directly.

The primary entry point is `M-x youtube-music', which pops a status
buffer styled after Magit: a Now Playing section, the upcoming
queue, and browseable sources.  Press `C-h m' inside the buffer to
see every key binding.

Features:

  - search songs and playlists in one prompt: picking a song
    plays that one track, picking a playlist queues it whole,
  - browse your library (`M-x youtube-music-library'): liked
    songs, saved playlists, and the personalized Home shelves,
  - start a radio of similar tracks from any song,
  - like / dislike tracks, shuffle, repeat, seek, edit the queue,
  - now-playing info in the global mode line, plus MPRIS support
    so desktop media controllers (playerctl, waybar, media keys)
    see the player,
  - one-keypress login: the YouTube Music cookie is pulled from
    your browser (Firefox, Chrome, Chromium, Brave, Edge, Safari)
    via yt-dlp, stored in a 0600 credentials file, and silently
    re-extracted when it expires.

OAuth device flow is intentionally not used: Google has been
restricting which client_ids may grant the YouTube Music scopes,
so the unofficial-OAuth path is currently unreliable.  The cookie
flow is robust and is used by `ytmusicapi' and `ytermusic' alike.

Required external programs: `mpv' and `yt-dlp'.
