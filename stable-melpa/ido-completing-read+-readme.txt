If you use the excellent `ido-mode' for efficient completion of
file names and buffers, you might wonder if you can get ido-style
completion everywhere else too. Well, that's what this package
does! ido-ubiquitous is here to enable ido-style completion for
(almost) every function that uses the standard completion function
`completing-read'.

This package implements the `ido-completing-read+' function, which
is a wrapper for `ido-completing-read'. Importantly, it detects
edge cases that ordinary ido cannot handle and either adjusts them
so ido *can* handle them, or else simply falls back to Emacs'
standard completion instead. Hence, you can safely set
`completing-read-function' to `ido-completing-read+' without
worrying about breaking completion features that are incompatible
with ido. (Package authors interested in implementing ido support
within their packages can also use `ido-completing-read+' instead
of `ido-completing-read' to provide a more consistent user
experience.)

To use this package, call `ido-ubiquitous-mode' to enable the mode,
or use `M-x customize-variable ido-ubiquitous-mode' it to enable it
permanently. Once the mode is enabled, most functions that use
`completing-read' will now have ido completion. If you decide in
the middle of a command that you would rather not use ido, just use
C-f or C-b at the end/beginning of the input to fall back to
non-ido completion (this is the same shortcut as when using ido for
buffers or files).

Note that `completing-read-default' is a very general function with
many complex behaviors that ido cannot emulate. This package
attempts to detect some of these cases and avoid using ido when it
sees them. So some functions will not have ido completion even when
this mode is enabled. Some other functions have ido disabled in
them because their packages already provide support for ido via
other means (for example, magit). See `M-x describe-variable
ido-cr+-disable-list' for more information.

ido-completing-read+ version 4.0 is a major update. The formerly
separate package ido-ubiquitous has been subsumed into
ido-completing-read+, so ido-ubiquitous 4.0 is just a wrapper that
loads ido-completing-read+ and displays a warning about being
obsolete. If you have previously customized ido-ubiquitous, be sure
to check out `M-x customize-group ido-completing-read-plus' after
updating to 4.0 and make sure the new settings are to your liking.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
