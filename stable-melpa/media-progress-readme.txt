Package gets information about viewing progress of the media files.
It parses data, saved by media players - for now only mpv player supported.

Preparations:
Install mpv player. You can save position on exit manually using
"Shift-Q" shortcut, or add these lines to the mpv config:

keep-open=yes
save-position-on-quit=yes

Optionally - install "mediainfo" app to display progress and "completed"
status.

Usage:
Package provides function `media-progress-info-string' which will
return progress string for media file.
