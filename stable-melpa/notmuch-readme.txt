This is an emacs-based interface to the notmuch mail system.

You will first need to have the notmuch program installed and have a
notmuch database built in order to use this. See
https://notmuchmail.org for details.

To install this software, copy it to a directory that is on the
`load-path' variable within emacs (a good candidate is
/usr/local/share/emacs/site-lisp). If you are viewing this from the
notmuch source distribution then you can simply run:

sudo make install-emacs

to install it.

Then, to actually run it, add:

(autoload 'notmuch "notmuch" "Notmuch mail" t)

to your ~/.emacs file, and then run "M-x notmuch" from within emacs,
or run:

emacs -f notmuch

Have fun, and let us know if you have any comment, questions, or
kudos: Notmuch list <notmuch@notmuchmail.org> (subscription is not
required, but is available from https://notmuchmail.org).

Note for MELPA users (and others tracking the development version
of notmuch-emacs):

This emacs package needs a fairly closely matched version of the
notmuch program. If you use the MELPA version of notmuch.el (as
opposed to MELPA stable), you should be prepared to track the
master development branch (i.e. build from git) for the notmuch
program as well. Upgrading notmuch-emacs too far beyond the notmuch
program can CAUSE YOUR EMAIL TO STOP WORKING.

TL;DR: notmuch-emacs from MELPA and notmuch from distro packages is
NOT SUPPORTED.
