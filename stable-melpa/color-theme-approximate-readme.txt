
This package advises the `enable-theme' function and convert non-terminal colors
to their closest approximation. Inspired by VIM's CSApprox plugin
http://www.vim.org/scripts/script.php?script_id=2390

Normally Emacs does have non-terminal color themes degrade, however in some
system the effect is pretty poor. I've encountered this on Arch Linux and
Ubuntu (probably caused by some libvte weirdness).

; Installation:
Add the to your .emacs or similar:

(autoload 'color-theme-approximate-on "color-theme-approximate")
(color-theme-approximate-on)

; Changelog

v0.4, Feb 28 2014
- Revamp and simplify

v0.3, Feb 23 2014
- Fix for non-standard color names ("Grey07" in Magit)

v0.2, Mar 29 2013
- Fix error that degrades colors on graphical frame running the same Emacs server
- Fix error that `ca-defined-rgb-map' is wrong when start Emacs with graphical frame

v0.1, Jan 14 2013
- Initial version
