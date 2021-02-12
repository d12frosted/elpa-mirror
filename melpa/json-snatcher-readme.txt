
Well this was my first excursion into ELisp programmming.  It didn't go too badly once
I fiddled around with a bunch of the functions.

The process of getting the path to a JSON value at point starts with
a call to the jsons-print-path function.

It works by parsing the current buffer into a list of parse tree nodes
if the buffer hasn't already been parsed in the current Emacs session.
While parsing, the region occupied by the node is recorded into the
jsons-parsed-regions hash table as a list.The list contains the location
of the first character occupied by the node, the location of the last
character occupied, and the path to the node.  The parse tree is also stored
in the jsons-parsed list for possible future use.

Once the buffer has been parsed, the node at point is looked up in the
jsons-curr-region list, which is the list of regions described in the
previous paragraph for the current buffer.  If point is not in one of these
interval ranges nil is returned, otherwise the path to the value is returned
in the form [<key-string>] for objects, and [<loc-int>] for arrays.
eg: ['value1'][0]['value2'] gets the array at with name value1, then gets the
0th element of the array (another object), then gets the value at 'value2'.


; Installation:

IMPORTANT: Works ONLY in Emacs 24 due to the use of the lexical-binding variable.

To install add the json-snatcher.el file to your load-path, and
add the following lines to your .emacs file:
(require 'json-snatcher)
(defun js-mode-bindings ()
  "Sets a hotkey for using the json-snatcher plugin."
  (when (string-match  "\\.json$" (buffer-name))
      (local-set-key (kbd "C-c C-g") 'jsons-print-path)))
(add-hook 'js-mode-hook 'js-mode-bindings)
(add-hook 'js2-mode-hook 'js-mode-bindings)

This binds the key to snatch the path to the JSON value to C-c C-g only
when either JS mode, or JS2 mode is active on a buffer ending with
the .json extension.
