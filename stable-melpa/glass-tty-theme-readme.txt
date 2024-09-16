Reverse video-like theme for use with the Glass TTY VT220 font.

Like the 'reverse' theme, this mimics the color theme applied when
starting Emacs in reverse video mode while adding support for
multiple frames.  Additionally, 'glass-tty' addresses some issues
'reverse' has with multiple frames while remaining backwards
compatible with the default theme for tty frames.  Because this
theme is also designed around the Glass TTY VT220 font, it
automatically scales the font correctly depending on the windowing
system.  The end result is a color theme suitable for use when
Emacs runs as a service across multiple platforms.

Before using this theme, dowload and install the font from
https://caglrc.cc/~svo/glasstty/.  How to change Emacs' default
font depends on the windowing system:

- On Windows, create a Registry key named
  HKEY_CURRENT_USER\\Software\\GNU\\Emacs\\ containing a string
  value 'Emacs.Font' with the data '-*-Glass TTY
  VT220-*-*-*--*-150-*-*-*-*-*-*'.

- On X11, add the following to ~/.Xresources: 'Emacs.Font: -*-Glass
  TTY VT220-*-*-*--*-150-*-*-*-*-*-*'

- On macOS, run the following Emacs Lisp expression: '(add-to-list
  'default-frame-alist '(font . \"-*-Glass TTY
  VT220-*-*-*--*-200-*-*-*-*-*-*\"))'

See also:
https://www.emacswiki.org/emacs/SetFonts
https://www.emacswiki.org/emacs/ChangeFontsPermanentlyOnWindows
