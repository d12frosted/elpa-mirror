
A hack of minor-modes.

`raise-minor-mode-map-alist' / `lower-minor-mode-map-alist' - resolve `minor-mode-map-alist' conflict

Example:
(raise-minor-mode-map-alist 'view-mode)
raises priority of `view-mode-map'.

; Commands

Below are complete command list:

 `show-minor-mode-map-priority'
   Show priority of `minor-mode-map-alist'.

; Customizable Options:

Below are customizable option list:


; Installation:

Put minor-mode-hack.el to your load-path.
The load-path is usually ~/elisp/.
It's set in your ~/.emacs like this:
(add-to-list 'load-path (expand-file-name "~/elisp"))

And the following to your ~/.emacs startup file.

(require 'minor-mode-hack)

No need more.
