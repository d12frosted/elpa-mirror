Inserts a script tag for HTML and HAML documents with a URL to a
given JavaScript library taken from: http://scriptsrc.net/

To use this, make sure that this file is in Emacs load-path:
  (add-to-list 'load-path "/path/to/directory/or/file")

Require it:
  (require 'html-script-src)

Then in your HTML or HAML file, interactively call the function
`html-script-src'.
