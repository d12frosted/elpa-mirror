Scroll screen down or up, and highlight current line before
or after scrolling
the lines it scrolling is screen_height*0.618

And the following to your ~/.emacs startup file.

(require 'golden-ratio-scroll-screen)
(global-set-key [remap scroll-down-command] 'golden-ratio-scroll-screen-down)
(global-set-key [remap scroll-up-command] 'golden-ratio-scroll-screen-up)

or:

(autoload 'golden-ratio-scroll-screen-down "golden-ratio-scroll-screen" "scroll half screen down" t)
(autoload 'golden-ratio-scroll-screen-up "golden-ratio-scroll-screen" "scroll half screen up" t)
(global-set-key [remap scroll-down-command] 'golden-ratio-scroll-screen-down)
(global-set-key [remap scroll-up-command] 'golden-ratio-scroll-screen-up)


; Codes

(require 'dired)
