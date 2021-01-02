
Emacs-libvterm (vterm) is fully-fledged terminal emulator based on an
external library (libvterm) loaded as a dynamic module.  As a result of using
compiled code (instead of elisp), emacs-libvterm is fully capable, fast, and
it can seamlessly handle large outputs.

; Installation

Emacs-libvterm requires support for loading modules.  You can check if your
Emacs supports modules by inspecting the variable module-file-suffix.  If it
nil, than, you need to recompile Emacs or obtain a copy of Emacs with this
option enabled.

Emacs-libvterm requires CMake and libvterm.  If libvterm is not available,
emacs-libvterm will downloaded and compiled.  In this case, libtool is
needed.

The reccomended way to install emacs-libvterm is from MELPA.

; Usage

To open a terminal, simply use the command M-x vterm.

; Tips and tricks

Adding some shell-side configuration enables a large set of additional
features, including, directory tracking, prompt recognition, message passing.
