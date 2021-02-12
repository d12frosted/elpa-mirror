This lets you associate external applications with files so that
you can open them via C-x C-f, with RET in dired, etc.

Copy openwith.el to your load-path and add to your .emacs:

   (require 'openwith)
   (openwith-mode t)

To customize associations etc., use:

   M-x customize-group RET openwith RET
