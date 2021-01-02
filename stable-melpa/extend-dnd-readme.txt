
* Introduction
I would like to drag files onto a ESS buffer and write the appropriate
code.  Enter Extend drag and drop.
* Installation
To install, put the `extend-dnd.el' somewhere in your load path, and add
the following lines to your startup file, usually =~/.emacs=


(require 'extend-dnd)
(extend-dnd-activate)

* Status and Future
Currently it only supports a few modes and extensions, but it is extendable.
* Working with Yasnippets
If you want extend-dnd to expand yasnippets based on the file name,
make sure that `yas/wrap-around-region' is set to be ='t= or ='cua=.

After you define a snippet in the major mode you are working with, and put
the file name as `yas/selected-text'.  For example with R csv files
you could define






${1:$(concat "dat." (replace-regexp-in-string "^[.]" "" (replace-regexp-in-string "[.]$" "" (replace-regexp-in-string "[^A-Za-z.0-9]+" "." (file-name-sans-extension (file-name-nondirectory yas/text)) t t))))} <- read.csv("${1:`yas/selected-text`}");



Then once this has been defined press `C-cC-d' to add the extension to
the drag and drop list.

The extension will be expanded based on the `key' value.  Therefore,
if you want more than one possible action for a particular file, give
it the same key.

For example, if you want the possibility to write to the csv you
dragged in, you may wish to have the snippet:






write.csv(d,"${1:`yas/selected-text`}");



* Wish List/TODO
** TODO Support dired mode
** TODO Support inferior processes.
** TODO Allow generic Yasnippet expansion by key name (like dnd_csv will automatically do drag and drop for csv files)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
