Support this work https://github.com/sponsors/xenodium

`ready-player-mode' is a lightweight media (audio/video) major mode for Emacs.

Setup:

  (require 'ready-player)
  (ready-player-mode)

To customize supported media files, set `ready-player-supported-media'
before invoking `ready-player-add-to-auto-mode-alist'.

`ready-player-mode' relies on command line utilities to play media.
 Customize `ready-player-open-playback-commands' to your preference.

Note: This is a new package.  Please report issues or send
patches to https://github.com/xenodium/ready-player
