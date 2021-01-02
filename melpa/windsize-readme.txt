Use the arrow keys (C-S-<dir> by default) to move one of the
borders of the active window in that direction. Always prefers to
move the right or bottom border when possible, and falls back to
moving the left or top border otherwise.

Rather than me trying to explain that in detail, it's best to just
split your emacs frame in to several windows and try it - trust me,
it's intuitive once you give it a go.

; Usage

(require 'windsize)
(windsize-default-keybindings) ; C-S-<left/right/up/down>

Or bind windsize-left, windsize-right, windsize-up, and
windsize-down to the keys you prefer.

By default, resizes by 8 columns and by 4 rows. Customize by
setting windsize-cols and/or windsize-rows.
Note that these variables are not buffer-local, since resizing
windows usually affects at least 2 buffers.
