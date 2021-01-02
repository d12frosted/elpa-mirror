
`Path headerline mode' is mode for displaying file path on headerline.
Modeline is too short to show filepath when split window by vertical.
path-headerline-mode show full file path if window width is enough.
but if window width is too short to show full file path, show directory path exclude file name.

; Installation
Make sure "path-headerline-mode.el" is in your load path, then place
this code in your .emacs file:

(require 'path-headerline-mode)
(path-headerline-mode +1)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
