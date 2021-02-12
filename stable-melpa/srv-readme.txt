This code implements RFC 2782 (SRV records).  It was originally
written for jabber.el <http://emacs-jabber.sf.net>, but is now a
separate package.

It is used to look up hostname and port for a service at a specific
domain.  There might be multiple results, and the caller is supposed
to attempt to connect to each hostname+port in turn.  For example,
to find the XMPP client service for the domain gmail.com:

(srv-lookup "_xmpp-client._tcp.gmail.com")
-> (("xmpp.l.google.com" . 5222)
    ("alt3.xmpp.l.google.com" . 5222)
    ("alt4.xmpp.l.google.com" . 5222)
    ("alt1.xmpp.l.google.com" . 5222)
    ("alt2.xmpp.l.google.com" . 5222))
