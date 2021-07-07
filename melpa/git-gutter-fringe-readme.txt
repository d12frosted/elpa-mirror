Show git diff information in fringe. You can use this package
only GUI Emacs, not working no window emacs.

To use this package, add following code to your init.el or .emacs

(require 'git-gutter-fringe)
(global-git-gutter-mode t)

; If you want to show git diff information at right fringe
(setq git-gutter-fr:side 'right-fringe)
