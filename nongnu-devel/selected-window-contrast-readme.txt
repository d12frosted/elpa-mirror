Highlight the selected window by adjusting the contrast of the text
 foreground and background relative to the current theme. It works
 well if you switch themes frequently; contrast will be
 preserved. This also applies to the modeline.
 Modeline and cursor highlighting - working in TTY.
We also highlight the cursor position, which can be disabled with
(setopt selected-window-contrast-cursor-flag nil) in .emacs.
 or
 M-x customize-variable RET selected-window-contrast-cursor-flag

Usage:

(add-to-list 'load-path "path_to/selected-window-contrast") ; optional
(when (require 'selected-window-contrast nil 'noerror)
  (setopt selected-window-contrast-bg-selected 0.95)
  (setopt selected-window-contrast-bg-others 0.75)
  (setopt selected-window-contrast-text-selected 0.9)
  (setopt selected-window-contrast-text-others 0.6)
  (add-hook 'buffer-list-update-hook
            #'selected-window-contrast-highlight-selected-window))

 How this works:

 1) We get color with `face-attribute' `selected-frame' for
 foreground and backgraound.
 2) Convert color to HSL
 3) adjust brightness in direction of foreground-background average
 4) convert color to RGB, then to HEX
 5) apply color

Customize: M-x customize-group RET selected-window-contrast

Note, if you use C-o to switch windows, this may conflict with
 rectangle-mark-mode-map
Rebind keys then:
(keymap-set rectangle-mark-mode-map "C-c o" #'open-rectangle)
(keymap-set rectangle-mark-mode-map "C-o" #'other-window)

Donate:

- BTC (Bitcoin) address: 1CcDWSQ2vgqv5LxZuWaHGW52B9fkT5io25
- USDT (Tether TRX-TRON) address: TVoXfYMkVYLnQZV3mGZ6GvmumuBfGsZzsN
- TON (Telegram) address: UQC8rjJFCHQkfdp7KmCkTZCb5dGzLFYe2TzsiZpfsnyTFt9D