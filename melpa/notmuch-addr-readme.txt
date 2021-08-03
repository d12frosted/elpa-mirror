An alternative to `notmuch-address'.  This implementation is much
simpler.  It gives up on persistent caching, external scripts and
backward compatibility.

This implementation uses the improved completion API offered by
Emacs 27.1 and later.  `notmuch-address' uses that old API, which
Emacs still supports.  In [1] I have documented the issues of the
old API and its use in Notmuch, as well as some other defects.

To use `notmuch-addr' you must enable its use right after Notmuch
has loaded the old `notmuch-address', which cannot be prevented.
If you do it later then it might have no effect:

(with-eval-after-load 'notmuch-address
  (require 'notmuch-addr)
  (notmuch-addr-setup))

This implementation is essentially identical to the upstream
implementation, except that it uses "notmuch address ..." as
an additional source of completion candidates.

[1]: https://nmbug.notmuchmail.org/nmweb/show/20201108231150.5419-1-jonas%40bernoul.li
