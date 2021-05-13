This package complements (does not replace) the standard whois
functionality of GNU Emacs.  It provides:

* A `whois-mode' with font-lock highlighting to make whois
  responses easier to read.

* A `whois-shell' command to make a whois query using the system
  whois program instead of Emacs' own (often not up to date) whois
  client.

* A `whois-expand' command to repeat the last whois query using the
  domain registrar's own whois server.

To replace Emacs' own `whois' command with the one from this
package:

(when (require 'whois nil t) (defalias 'whois 'whois-shell))
