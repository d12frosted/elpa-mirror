Allows for customization of Emacs frames, which include height and width of
new Emacs frames.  Options for new frames are those given to `make-frame`.
This is handy for those that rather resize your Emacs frames with a key
binding than using your mouse.

The library "learns" frame configurations, then restores them later on:

* Record frame positions with `M-x cframe-add-or-advance-setting`.
* Restore previous settings on start up with `cframe-restore`.
* Cycles through configuratinos with `cframe-add-or-advance-setting`.
* Pull up the [entries buffer] with `cframe-list`.

I use the following in my `~/.emacs` configuration file:

(require 'cframe)
;; frame size settings based on screen dimentions
(global-set-key "\C-x9" 'cframe-restore)
;; doesn't clobber anything in shell, Emacs Lisp buffers (maybe others?)
(global-set-key "\C-\\" 'cframe-add-or-advance-setting)
;; toggle full or maximized screen
(global-set-key "\C-x\C-\\" 'cframe-toggle-frame-full-or-maximized)
