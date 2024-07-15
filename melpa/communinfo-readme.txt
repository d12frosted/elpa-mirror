Version 30 of GNU Emacs introduces a user option variable
`Info-url-alist' that allows to associate Info manuals to URLs.
Its default value only associates those Info manuals that are part
of Emacs.  This package provides the variable
`communinfo-url-alist' which can be used as value for
`Info-url-alist' that provides URL-associations for many more free,
libre and open source software projects.

Here's how to use `communinfo' after installation:

  (require 'info)
  (require 'communinfo)

  (setopt Info-url-alist communinfo-url-alist)
