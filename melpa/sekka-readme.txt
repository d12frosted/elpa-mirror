Sekka is yet another Japanese Input Method inspired by SKK.
sekka.el is a client for Sekka IME server.
[https://github.com/kiyoka/sekka]

you might want to enable IME:

 (require 'sekka)
 (global-sekka-mode 1)

To enable sticky-shift with ";" key:

 (setq sekka-sticky-shift t)

