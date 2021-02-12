
Description:

This extension provides basic support for executing the codesearch tools and
for managing codesearch indices.

For more details, see the project page at
https://github.com/abingham/emacs-codesearch

For more details on codesearch, see its project page at
https://github.com/google/codesearch

Installation:

The simple way is to use package.el:

  M-x package-install codesearch

Or, copy codesearch.el to some location in your emacs load
path. Then add "(require 'codesearch)" to your emacs initialization
(.emacs, init.el, or something).

Example config:

  (require 'codesearch)

This elisp extension assumes you've got the codesearch tools -
csearch and cindex - installed. See the codesearch-csearch and
codesearch-cindex variables for more information.
