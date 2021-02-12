This extension is useful when you want save window configuration
between emacs sessions or for emacs lisp programer who want handle
window layout.

; Dependencies:
 no extra libraries is required

Put this file into your load-path and the following into your ~/.emacs:
  (require 'windata)
You can use desktop to save window configuration between different
session:
  (require 'desktop)
  (add-to-list 'desktop-globals-to-save 'windata-named-winconf)
