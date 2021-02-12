ercn allows for flexible notification rules in ERC. You can
configure it to notify for certain classes of users, query buffers,
certain buffers, etc. It utilizes functions (and a small bit of
copy pasta) from erc-match to get the job done. See the
documentation for `ercn-notify-rules' and `ercn-suppress-rules' to
set it up.

When a notification is needed, ercn calls `ercn-notify-hook' so
that any notification mechanism available for your system can be
utilized with a little elisp.

Installation:
=============

Via Marmalade (recommended)
---------------------------

If you are on Emacs 23, go to marmalade-repo.org and follow the installation
instructions there.

If you are on Emacs 24, add Marmalade as a package archive source in
~/.emacs.d/init.el:

  (require 'package)
  (add-to-list 'package-archives
      '("marmalade" . "http://marmalade-repo.org/packages/") t)
  (package-initialize)

Then you can install it:

  M-x package-refresh-contents
  M-x package-install RET ercn RET

Manually (via git)
------------------

Download the source or clone the repo and add the following to
~/.emacs.d/init.el:

  (add-to-list 'load-path "path/to/ercn")
  (require 'ercn)

Configuration
=============

Two variables control whether or not ercn calls `ercn-notify-hook':

* `ercn-notify-rules': Rules to determine if the hook should be called. It
  defaults to calling the hook whenever a pal speaks, a keyword is mentioned,
  your current-nick is mentioned, or a message is sent inside a query buffer.

* `ercn-suppress-rules': Rules to determine if the notification should be
  suppressed. Takes precedent over `ercn-notify-rules'. The default will
  suppress messages from fools, dangerous-hosts, and system messages.

Both vars are alists that contain the category of message as the keys and as
the value either the symbol ‘all, a list of buffer names in which to
notify or suppress, or a function predicate.

The supported categories are:

* message - category added to all messages
* current-nick - messages that mention you
* keyword - words in the `erc-keywords' list
* pal - nicks in the `erc-pals' list
* query-buffer - private messages
* fool - nicks in the `erc-fools' list
* dangerous-host - hosts in the `erc-dangerous-hosts' list
* system - messages sent from the system (join, part, etc.)

An example configuration
------------------------

  (setq ercn-notify-rules
      '((current-nick . all)
           (keyword . all)
           (pal . ("#emacs"))
           (query-buffer . all)))

  (defun do-notify (nickname message)
      ;; notification code goes here
  )

  (add-hook 'ercn-notify-hook 'do-notify)

In this example, `ercn-notify-hook' will be called whenever anyone
mentions my nick or a keyword or when sent from a query buffer, or if a pal
speaks in #emacs.

To call the hook on all messages
--------------------------------

  (setq ercn-notify-rules '((message . all))
      ercn-suppress-rules nil)

  (defun do-notify (nickname message)
      ;; notification code goes here
  )

  (add-hook 'ercn-notify-hook 'do-notify)

I wouldn’t recommend it, but it’s your setup.


History

1.0.0 - Initial release.  It probably even works.

1.0.1 - save-excursion, to avoid messing with the current line

1.0.2 - fix autoloads

1.1 - Added customize options; renamed `erc-notify' `erc-notify-hook'
