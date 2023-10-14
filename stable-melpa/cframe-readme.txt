Emacs frames position and dimensions are "learned" from user provided frame
configurations, then restores them later.  This is for users that prefer to
resize Emacs frames with a key binding rather than the mouse.

To use this library:

1. Position the frame how you like it.
2. Record the frame with `M-x cframe-add-or-advance-setting`.
3. Restore previous settings on start up with `cframe-restore`.
4. Cycle through configurations with `cframe-add-or-advance-setting`.

You can get a list of the configuration and which is currently used with
`cframe-list`.

Recommended `~/.emacs` configuration to restore the frame on start up:

(require 'cframe)
;; frame size settings based on screen dimentions
(global-set-key "\C-x9" 'cframe-restore)
;; doesn't clobber anything in shell, Emacs Lisp buffers (maybe others?)
(global-set-key "\C-\\" 'cframe-add-or-advance-setting)
;; toggle full or maximized screen
(global-set-key "\C-x\C-\\" 'cframe-toggle-frame-full-or-maximized)
