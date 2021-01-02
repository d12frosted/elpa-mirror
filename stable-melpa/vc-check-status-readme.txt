This is an Emacs extension that warns you when you are about to quit
Emacs and leaving a git repository that has some file opened in Emacs
in a dirty state: uncommitted changes, unpushed commits, etc...

; Installation:

Put the following in your .emacs:

(require 'vc-check-status)
(vc-check-status-activate 1)

See documentation on https://github.com/thisirs/vc-check-status#vc-check-status
