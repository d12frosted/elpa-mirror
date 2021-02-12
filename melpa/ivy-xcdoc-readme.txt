
This package provides functions to search Xcode documents within Emacs,
Currently support API search only, result topics will show in web browser.
Other features may be added later.

Example usage:

  (require 'ivy-xcdoc)

Then:

  M-x `ivy-xcdoc-search-api' RET

or

  M-x `ivy-xcdoc-search-api-at-point' RET

Tips:

You may want to customization `ivy-xcdoc-docsets', default settings is
known to work with Xcode 8.0,  for other verison  the docset paths
maybe different, and the default settings contains OSX and iOS documents
only, whatchOS and tvOS is not include by default.

You can also set the `ivy-xcdoc-url-browser-function' variable to change
the default display style, for example use an external browser.
