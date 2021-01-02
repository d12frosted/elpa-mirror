
This project adds a minor mode for GNU Emacs that adds tools to help
developing games using the `LÖVE' engine. This minor mode works in
conjunction with and requires `lua-mode'.

Usage:

Put this file in your Emacs lisp path (i.e. site-lisp) and add
this to your `.emacs' file:

(require 'love-minor-mode)

If you are working on a LÖVE project then you can enable the minor
mode with the command (love-minor-mode t).  Emacs will activate
the minor mode automatically if you visit a Lua buffer that
contains any built-in LÖVE names.

See the file 'README.markdown' for a description of the commands
that LÖVE minor mode provides.  If you do not have the file
available then you can see the key-bindings and their commands by
entering 'C-h f love-minor-mode'.

