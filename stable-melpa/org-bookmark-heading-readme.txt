This package provides Emacs bookmark support for Org mode.  You can
bookmark headings in Org mode files and jump to them using standard
Emacs bookmark commands.

It seems like this file should be named org-bookmark.el, but a
package by that name already exists in org-mode/contrib which lets
Org mode links point to Emacs bookmarks, sort-of the reverse of
this package.

It also seems like this should be built-in to Org mode...  ;)

; Installation

Require the package in your init file:

(require 'org-bookmark-heading)

Then you can customize `org-bookmark-jump-indirect' if you like.

; Usage

Use the standard Emacs bookmark commands, "C-x r m", etc.

If you use Helm, you can jump to Org mode bookmarks in an indirect
buffer by pressing "<C-return>" in the Helm buffer, or by choosing
the action from the list.

You can also customize the variable `org-bookmark-jump-indirect' to
make Org mode bookmarks always open in indirect buffers.
