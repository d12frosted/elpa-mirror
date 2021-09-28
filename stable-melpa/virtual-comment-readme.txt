* Intro

This package allows adding virtual comments to files in buffers. These
comments don't belong to the files so they don't. They are saved in project
root or a global file which can be viewed and searched. The file name is
.evc.

* Virtual comments
A virtual comment is an overlay and it is added above the line it comments on
and has the same indentation. The virtual comment can be single line or
multiline. Each line can have one comment.

* Install
Spacemacs layer:
https://github.com/thanhvg/spacemacs-eos

Vanilla
(require 'virtual-comment)
(add-hook 'find-file-hook 'virtual-comment-mode)

* Commands
- virtual-comment-make: create or edit a comment at current line
- virtual-comment-next: go to next comment in buffer
- virtual-comment-previous: go to previous comment in buffer
- virtual-comment-delete: remove the current comment
- virtual-comment-paste: paste the last removed comment to current line
- virtual-comment-realign: realign the comments if they are misplaced
- virtual-comment-persist: manually persist project comments
- virtual-comment-show: show all comments of current project in a derived mode
from outline-mode, press enter on a comment will call virtual-comment-go to go
to the location of comment.
Commands to link to other location (reference):
- virtual-comment-remember-current-location store the current location
- virtual-comment-add-ref add the stored location (reference) as comment
- virtual-comment-goto-location go to location

There are no default bindings at all for these commands.

* Remarks
It's very hard to manage overlays. So this mode should be use in a sensible way.
Only comments of files can be persisted.

* Test
cask install
cask exec ert-runner

* Other similar packages and inspirations
https://github.com/blue0513/phantom-inline-comment
https://www.emacswiki.org/emacs/InPlaceAnnotations

Change log
20210-09-27: 0.02 add location/reference
