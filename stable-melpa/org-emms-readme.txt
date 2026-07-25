This package provides an Org link type for playing multimedia files
with EMMS, The Emacs Multimedia System. If the link contains a
track position, playback will start at the specified position. For
example:

[[emms:/path/to/audio.mp3::2:43]]     Starts playback at 2 min 43 sec.
[[emms:/path/to/audio.mp3::1:10:45]]  Starts playback at 1 hr 10 min 45 sec.
[[emms:/path/to/audio.mp3::49]]       Starts playback at 0 min 49 sec.

Available commands include `org-emms-insert-link`,
`org-emms-insert-track`, `org-emms-insert-track-position`

It is also possible to store an Org link from an EMMS playlist or
browser buffer with `org-store-link`, then insert it into an Org
buffer with `org-insert-link`.

See also: http://orgmode.org/worg/code/elisp/org-player.el
