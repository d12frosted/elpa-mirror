
Quickstart

To make the mode enabled every time Emacs starts, add the following
to Emacs initialisation file (~/.emacs or ~/.emacs.d/init.el):

If installed from melpa.
      (smart-cursor-color-mode 1)

If installed manually,
      (add-to-list 'load-path "path-to-installed-directory")
      (require 'smart-cursor-color)
      (smart-cursor-color-mode 1)

When hl-line-mode is on,
smart-cursor-color-mode is not work.
So must turn off hl-line-mode.
      (hl-line-mode -1)

But when global-hl-line-mode is on,
smart-cursor-color-mode is work.
      (global-hl-line-mode 1)
      (smart-cursor-color-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
