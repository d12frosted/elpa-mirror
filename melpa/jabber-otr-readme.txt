This package provides Off-The-Record encryption support for
jabber.el.

To use it, you need to have python-potr installed.  You can install
it with:

sudo pip install python-potr

Or see https://github.com/python-otr/pure-python-otr for more
information.

To activate OTR when chatting with someone, type M-x
jabber-otr-encrypt in the chat buffer.  If the contact activates
OTR, the chat buffer should switch to encrypted mode automatically.

This is still a work in progress.  Please send bug reports and
patches/pull requests.
