Scroll Restore mode is a minor mode to restore the position of
`point' in a sequence of scrolling commands whenever that position
has gone off-screen and becomes visible again.  The user option
`scroll-restore-commands' specifies the set of commands that may
constitute such a sequence.

The following additional options are provided:

- Recenter the window when restoring the original position, see
  `scroll-restore-recenter'.

- Jump back to the original position before executing a command not
  in `scroll-restore-commands', see `scroll-restore-jump-back'.  The
  resulting behavior is similar to that provided by a number of word
  processors.

- Change the appearance of the cursor in the selected window to
  indicate that the original position is off-screen, see
  `scroll-restore-handle-cursor'.

- With `transient-mark-mode' non-nil Emacs highlights the region
  between `point' and `mark' when the mark is active.  If you scroll
  `point' off-screen, Emacs relocates `point' _and_ the region.
  Customizing `scroll-restore-handle-region' permits to highlight the
  original region as long as the original position of `point' is
  off-screen, and restore the original region whenever the original
  position of `point' becomes visible again.


Caveats:

- Scroll Restore mode does not handle `switch-frame' and
  `vertical-scroll-bar' events executed within the loops in
  `mouse-show-mark' and `scroll-bar-drag' (these don't call
  `post-command-hook' as needed by Scroll Restore mode).

- Scroll Restore mode may disregard your customizations of
  `scroll-margin'.  Handling `scroll-margin' on the Elisp level is
  tedious and might not work correctly.

- Scroll Restore mode should handle `make-cursor-line-fully-visible'
  but there might be problems.

- Scroll Restore mode can handle region and cursor only in the
  selected window.  This makes a difference when you have set
  `highlight-nonselected-windows' to a non-nil value.

- Scroll Restore mode has not been tested with emulation modes like
  `cua-mode' or `pc-selection-mode'.  In particular, the former's
  handling of `cursor-type' and `cursor-color' might be affected by
  Scroll Restore mode."

- Scroll Restore mode might interact badly with `follow-mode'.  For
  example, the latter may deliberately select a window A when the
  original position of a window B appears in it.  This won't restore
  the appearance of the cursor when Scroll Restore mode handles it.