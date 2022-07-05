
This package provides integration with the mpv video player for `elfeed-tube'
entries, which see.

With `elfeed-tube-mpv' loaded, clicking on a transcript segment in an Elfeed
Youtube video feed entry will launch mpv at that time, or seek to that point
if already playing.

It defines two commands and a minor mode:

- `elfeed-tube-mpv': Start an mpv session that is "connected" to an Elfeed
entry corresponding to a Youtube video. You can use this command to start
playback, or seek in mpv to a transcript segment, or enqueue a video in mpv
if one is already playing. Call with a prefix argument to spawn a new
instance of mpv instead.

- `elfeed-tube-mpv-where': Jump in Emacs to the transcript position
corresponding to the current playback time in mpv.

- `elfeed-tube-mpv-follow-mode': Follow along in the transcript in Emacs to
the video playback.
