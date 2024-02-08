
The Selected Window Accent Mode is an Emacs package designed to visually
distinguish the currently selected window by applying a unique accent
color to its fringes, mode line, header line, and margins.


1 Quick Start

  To use left and bottom accent based on the themes highlight colour:

  | (use-package selected-window-accent-mode
  |  :custom
  |  (selected-window-accent-fringe-thickness 10)
  |  (selected-window-accent-custom-color nil)
  |  (selected-window-accent-mode-style 'subtle))

  OR define your own colour:

  | (use-package selected-window-accent-mode
  |  :custom
  |  (selected-window-accent-fringe-thickness 10)
  |  (selected-window-accent-custom-color "#427900")
  |  (selected-window-accent-mode-style 'subtle))

2 Alternative window highlighting packages

  There exist a few Emacs packages that perform window highlighting but
  that don't quite provide the feature set of selected-window-accent.

  selected-window-accent focusses more on clearly but non-intrusively
  highlighting the currently selected/focussed window by highlighting
  aspects of the window border without having to modify the appearance
  of non-selected windows, hence more akin to a tiling window manager.

2.1 dimmer

  "This package provides a minor mode that indicates which buffer is
  currently active by dimming the faces in the other buffers."

  This is the closest in functionality to selected-window-accent, the
  difference being that dimmer dims non selected windows rather than
  accent the selected window.

  dimmer can be used in conjunction and will complement
  selected-window-accent to further enhance the emphasizing of the
  selected window.

2.2 hiwin

  "This package provides a minor-mode to change the background colour of
  the non active window."

  It uses overlays to highlight non active windows, so is similar to
  dimmer but is less subtle in its highlighting mechanism and hasn't
  been updated in excess of 10 years.

2.3 color-theme-buffer-local

  "This package lets you set a color-theme on a per-buffer basis."

  Unlike dimmer and hiwin this package isn't related to the concept of a
  selected window but more of defining different themes for different
  windows to distinguish them.

2.4 solaire-mode

  "This package is designed to visually distinguish "real" buffers
  (i.e. file-visiting code buffers where you do most of your work) from
  "unreal" buffers (like popups, sidebars, log buffers, terminals, etc)
  by giving the latter a slightly different -- often darker --
  background"

  Unlike dimmer and hiwin this package isn't related to the concept of a
  selected window but more of distinguishing between collections of IDE
  like elements within Emacs.
