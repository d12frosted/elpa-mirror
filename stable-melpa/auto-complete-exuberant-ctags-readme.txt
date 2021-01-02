
This package provide Exuberant ctags auto-complete.el source

; Installation:

Put anything-exuberant-ctags.el to your load-path.
The load-path is usually ~/elisp/.
It's set in your ~/.emacs like this:
(add-to-list 'load-path (expand-file-name "~/elisp"))

And the following to your ~/.emacs startup file.

(require 'auto-complete-exuberant-ctags)
(ac-exuberant-ctags-setup)

In your project root directory, do follow command to make tags file.

ctags --verbose -R --fields="+afikKlmnsSzt"

No need more.
