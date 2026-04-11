Sekka is yet another Japanese Input Method inspired by SKK.
Pure Emacs Lisp implementation -- no server required.
[https://github.com/kiyoka/sekka]

you might want to enable IME:

 (require 'sekka)
 (global-sekka-mode 1)

To enable sticky-shift with ";" key:

 (setq sekka-sticky-shift t)

