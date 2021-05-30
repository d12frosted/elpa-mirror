INSTALL

To install, put this file along your Emacs-Lisp `load-path' and add
the following into your ~/.emacs startup file or set
`global-smart-tab-mode' to non-nil with customize:

    (require 'smart-tab)
    (global-smart-tab-mode 1)

DESCRIPTION

Try to 'do the smart thing' when tab is pressed.  `smart-tab'
attempts to expand the text before the point or indent the current
line or selection.

See <http://www.emacswiki.org/cgi-bin/wiki/TabCompletion#toc2>.
There are a number of available customizations on that page.

Features that might be required by this library:

  `cl-macs'
  `easy-mmmode'
