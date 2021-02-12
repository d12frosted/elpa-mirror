
MoveText 2.0.0 is a re-write of the old move-text and compatible with >= Emacs 25.1

It allows you to move the current line using M-up / M-down if a
region is marked, it will move the region instead.

Using the prefix (C-u *number* or META *number*) you can predefine how
many lines move-text will travel.


; Installation:

Put move-text.el to your load-path.
The load-path is usually ~/elisp/.
It's set in your ~/.emacs like this:
(add-to-list 'load-path (expand-file-name "~/elisp"))

And the following to your ~/.emacs startup file.

(require 'move-text)
(move-text-default-bindings)

; Acknowledgements:

 Original v1.x was a Feature extracted from basic-edit-toolkit.el - by Andy Stewart (LazyCat)
