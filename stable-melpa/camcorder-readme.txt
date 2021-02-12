
  Tool for capturing screencasts directly from Emacs.

  • To use it, simply call `M-x camcorder-record'.
  • A new smaller frame will popup and recording starts.
  • When you're finished, hit `F12' and wait for the conversion to
    finish.

  Screencasts can be generated in any format understood by
  `imagemagick''s `convert' command. You can even pause the recording
  with `F11'!

  If you want to record without a popup frame, use `M-x
  camcorder-mode'.

Dependencies
────────────

  `camcorder.el' uses the [*Names*] package, so if you're installing
  manually you need to install that too.

  For the recording, `camcorder.el' uses the following linux utilities.
  If you have these, it should work out of the box. If you use something
  else, you should still be able to configure `camcorder.el' work.

  • recordmydesktop
  • mplayer
  • imagemagick

  Do you know of a way to make it work with less dependencies? *Open an
  issue and let me know!*


  [*Names*] https://github.com/Bruce-Connor/names/

Troubleshooting
───────────────

  If camcorder.el seems to pick an incorrect window id (differing from the
  one that `wminfo' returns), you can change `camcorder-window-id-offset' from its
  default value of 0.
