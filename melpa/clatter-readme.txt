clatter.el is a dedicated, IRCv3-compliant IRC client for Emacs.
Pure Elisp, requiring only Emacs 30.1+ and curl (for async URL/image fetching).

Spiritual successor to CLatter (Common Lisp TUI IRC client),
redesigned from scratch for Emacs.

Features:
- Full IRC protocol (RFC 1459/2812)
- IRCv3 capability negotiation (CAP LS 302)
- SASL authentication (PLAIN and EXTERNAL)
- Message tags, batch, labeled-response, chathistory
- MONITOR, typing indicators, CTCP
- TLS/SSL with client certificate support
- Buffer-per-channel with nick colorization
- auth-source integration for passwords
- Reconnection with exponential backoff

Quick start:

  (require 'clatter)
  (setq clatter-networks
    '(("libera"
       :server "irc.libera.chat"
       :port 6697
       :tls t
       :nick "yournick"
       :sasl plain
       :autojoin ("#systemcrafters" "#commonlisp"))))
  (clatter-connect "libera")
