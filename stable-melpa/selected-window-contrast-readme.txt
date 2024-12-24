It Loop windows at frame, measure and adjust contrast.  Allow to
 set color (face) of background and text by comparing their
 brightness.
This is useful for changing themes during the daytime (circadian
 package) and for highlighting selected window.  Also this works
 for modeline.

Usage:

 (require 'selected-window-contrast)
 ;; - increase contrast for selected window (default = 1.0)
 (setopt selected-window-contrast-selected-magnitude-text 0.8)
 (setopt selected-window-contrast-selected-magnitude-background 0.9)
 ;; - decrease conrtrast for other windows (default = 1.0)
 (setopt selected-window-contrast-not-sel-magnitude-text 1.1)
 (setopt selected-window-contrast-not-sel-magnitude-background 1.1)
 (add-hook 'buffer-list-update-hook
          #'selected-window-contrast-highlight-selected-window)
 ;; - for case of call: $ emacsclient -c ~/file
 (add-hook 'server-after-make-frame-hook
          #'selected-window-contrast-highlight-selected-window)

To increase contrast of selected modeline:

 (selected-window-contrast-change-modeline 0.7 0.7)

How this works:
 1) We get color with `face-attribute' `selected-frame' for
 foreground and backgraound.
 2) Convert color to HSL
 3) adjust brightness in direction of foreground-background average
 4) convert color to RGB, then to HEX
 5) apply color

Customize: M-x customize-group RET selected-window-contrast
