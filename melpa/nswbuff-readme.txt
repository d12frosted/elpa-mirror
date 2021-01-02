
`nswbuff' is an Emacs library for quick buffer switching based on swbuff.el,
incorporating the changes from swbuff-x.el and a few new features not present
in either.

This package provides two commands: `nswbuff-switch-to-next-buffer' and
`nswbuff-switch-to-previous-buffer' to switch to the next or previous buffer
in the buffer list, respectively.  During buffer switching, the list of
switchable buffers is visible at the bottom of the frame.

Switching buffers pops-up a status window at the bottom of the selected
window.  The status window shows the list of switchable buffers where the
switched one is highlighted using `nswbuff-current-buffer-face'.  This window
is automatically discarded after any command is executed or after the delay
specified by `nswbuff-clear-delay'.

The bufferlist is sorted by how recently the buffers were used.  If you
prefer a fixed (cyclic) order set `nswbuff-recent-buffers-first' to nil.

There are several options to manipulate the list of switchable buffers.
The option `nswbuff-exclude-buffer-regexps' defines a list of regular
expressions for excluded buffers.  The default setting excludes
buffers whose name begin with a blank character.  To exclude all the
internal buffers (that is *scratch*, *Message*, etc...) you could
use the following regexps '("^ .*" "^\\*.*\\*").

Buffers can also be excluded by major mode using the option
`nswbuff-exclude-mode-regexp'.

The option `nswbuff-include-buffer-regexps' defines a list of regular
expressions of buffers that must be included, even if they already match a
regexp in `nswbuff-exclude-buffer-regexps'.  (The same could be done by using
more sophisticated exclude regexps, but this option keeps the regexps cleaner
and easier to understand.)

You can further customize the list of switchable buffers by setting the
option `nswbuff-buffer-list-function' to a function that returns a list of
buffers.  Only the buffers returned by this function will be offered for
switching.  If this function returns nil, the buffers returned by
`buffer-list' is used instead.  Note that this list is still checked against
`nswbuff-exclude-buffer-regexps', `nswbuff-exclude-mode-regexp' and
`nswbuff-include-buffer-regexps'.

One function already provided that makes use of this option is
`nswbuff-projectile-buffer-list', which returns the buffers of the current
[Projectile](http://batsov.com/projectile/) project plus any buffers in
`(buffer-list)' that match `nswbuff-include-buffer-regexps'.
