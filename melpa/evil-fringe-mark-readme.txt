This file provides `evil-fringe-mark', which in turn provides the minor
modes `evil-fringe-mark-mode' and `global-evil-fringe-mark-mode'.  To
enable either mode, run its respective command.  These modes display
fringe bitmaps representing all `evil-mode' marks within a buffer; the
fringe in which bitmap overlays are placed may be changed by modifying
the global variable `evil-fringe-mark-side'.  The mode may be configured
to display special marks by setting `evil-fringe-mark-show-special' to a
non-nil value, and certain mark characters may be omitted from fringe
display by adding them to the list `evil-fringe-mark-ignore-chars'.
