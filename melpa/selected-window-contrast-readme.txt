Highlight selected window by adjusting contrast of text
 "foreground" and background.
Working good if you switch temes frequently, contrast will be kept.
Also this works for modeline.
 We also highligh cursor position, this may be disabled with
 M-x customize-variable RET selected-window-contrast-text-switch-mode

Usage:

(add-to-list 'load-path "path_to/selected-window-contrast") ; optional
(when (require 'selected-window-contrast nil 'noerror)
  (setopt selected-window-contrast-bg-selected 0.95)
  (setopt selected-window-contrast-bg-others 0.75)
  (setopt selected-window-contrast-text-selected 0.9)
  (setopt selected-window-contrast-text-others 0.6)
  (add-hook 'buffer-list-update-hook
            #'selected-window-contrast-highlight-selected-window))


To disable highlighting window with rectangle around pointer use:
(setopt selected-window-contrast-mode 1)


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
- USDT (Tether TRX-TRON) address: TVoXfYMkVYLnQZV3mGZ6GvmumuBfGsZzsN
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
