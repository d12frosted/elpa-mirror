This package provides a new org link type for playing back
multimedia files from Org documents using EMMS, The Emacs
Multimedia System. If the link contains a track position, playback
will start at the specified position. For example:

[[emms:/path/to/audio.mp3::2:43]]     Starts playback at 2 min 43 sec.
[[emms:/path/to/audio.mp3::1:10:45]]  Starts playback at 1 hr 10 min 45 sec.
[[emms:/path/to/audio.mp3::49]]       Starts playback at 0 min 49 sec.

The two main commands are `org-emms-insert-track' and
`org-emms-insert-track-position'. The latter is especially useful
for aligning text with audio when transcribing spoken language.

It is also possible to make a usual org link (with `org-store-link'
command) from EMMS playlist and browser buffers, and then insert it
into an org-mode buffer (with `org-insert-link' command).

See also: http://orgmode.org/worg/code/elisp/org-player.el
