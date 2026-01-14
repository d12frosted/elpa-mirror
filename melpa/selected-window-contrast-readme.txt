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

Donate:
- BTC (Bitcoin) address: 1CcDWSQ2vgqv5LxZuWaHGW52B9fkT5io25
- USDT (Tether) address: TVoXfYMkVYLnQZV3mGZ6GvmumuBfGsZzsN
- TON (Telegram) address: UQC8rjJFCHQkfdp7KmCkTZCb5dGzLFYe2TzsiZpfsnyTFt9D

Other packages:
- Modern navigation in major modes https://github.com/Anoncheg1/firstly-search
- Search with Chinese	https://github.com/Anoncheg1/pinyin-isearch
- Ediff no 3-th window	https://github.com/Anoncheg1/ediffnw
- Dired history		https://github.com/Anoncheg1/dired-hist
- Copy link to clipboard	https://github.com/Anoncheg1/emacs-org-links
- Solution for "callback hell"	https://github.com/Anoncheg1/emacs-async1
- Restore buffer state	https://github.com/Anoncheg1/emacs-unmodified-buffer1
- outline.el usage		https://github.com/Anoncheg1/emacs-outline-it
- Call LLMs & AIfrom Org-mode block.  https://github.com/Anoncheg1/emacs-oai
