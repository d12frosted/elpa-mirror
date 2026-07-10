The inhibit-mouse package allows the disabling of mouse input in Emacs using
inhibit-mouse-mode.

Instead of modifying the keymap of its own mode (as the disable-mouse package
does), enabling inhibit-mouse-mode only modifies input-decode-map to disable
mouse events, making it more efficient and faster than disable-mouse.

Additionally, the inhibit-mouse package allows for the restoration of mouse
input when inhibit-mouse-mode is disabled.

Installation from MELPA:
------------------------
(use-package inhibit-mouse
  :custom
  ;; Disable highlighting of clickable text such as URLs and hyperlinks when
  ;; hovered by the mouse pointer.
  (inhibit-mouse-adjust-mouse-highlight t)

  ;; Disables the use of tooltips (show-help-function) during mouse events.
  (inhibit-mouse-adjust-show-help-function t)

  :init
  (if (daemonp)
      (add-hook 'server-after-make-frame-hook #'inhibit-mouse-mode)
    (inhibit-mouse-mode 1)))

Usage:
------
You can enable or disable inhibit-mouse-mode using:
  (inhibit-mouse-mode)

Links:
------
- inhibit-mouse.el @GitHub:
  https://github.com/jamescherti/inhibit-mouse.el
