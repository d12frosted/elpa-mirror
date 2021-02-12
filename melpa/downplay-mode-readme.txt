Downplay is a minor Emacs mode that provides facilities to apply a
face (via overlays) to all but the current region or line.

To enable Downplay minor mode, type M-x downplay-mode.
This applies only to the current buffer.

When 'downplay is called, it will change the downplayed state of
the buffer depending on the current state:

- when the downplay is inactive:
  - if the region is active and transient-mark-mode is active,
    downplay-face is applied to all of the buffer except the region
  - else downplay-face is applied to all of the buffer except the
    current line
- when the downplay is active:
  - if the region is active and transient-mark-mode is active and
    the region has changed since the downplay was activated,
    downplay-face is reapplied to all of the buffer except the
    region
  - else if the current line has changed, downplay-face is
    reapplied to all of the buffer except the current line
  - else the downplay is deactivated (downplay-face is unapplied
    from the entire buffer)

By default, 'downplay is bound to C-c z when downplay-mode is
active. The default downplay-face sets the height of the text to
0.75.
