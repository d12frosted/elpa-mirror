`lodgeit.el` allows you to easily submit regions to a lodgeit base
pastebin.

Installation:

   (require 'lodgeit)

You can then configure the pastebin you want to use via the
`lodgeit-pastebin-base` variable.

   (setq lodgeit-pastebin-base "http://paste.openstack.org/")

Usage:

Select some region and `M-x lodgeit-paste`. The major mode should
be used to properly highlight the paste on the server. The URL is
added to the kill ring for pasting as needed.
