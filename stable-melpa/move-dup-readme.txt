This package offers convenient editing commands much like Eclipse's ability
to move and duplicate lines or rectangular selections by way of
`move-dup-mode'.

If you aren't using `package.el' or plan to customize the default
key-bindings, you need to put `move-dup.el' into your Emacs' load-path and
`require' it in your Emacs init file; otherwise you can skip this part.

(require 'move-dup)

If you don't want to toggle the minor mode, you can bind these functions like
so.  All of these functions work on a single line or a rectangle.

(global-set-key (kbd "M-<up>") 'move-dup-move-lines-up)
(global-set-key (kbd "M-<down>") 'move-dup-move-lines-down)
(global-set-key (kbd "C-M-<up>") 'move-dup-duplicate-up)
(global-set-key (kbd "C-M-<down>") 'move-dup-duplicate-down)

If you used `package.el' to install `move-dup.el', this is equivalent to all
of the above.
(global-move-dup-mode)

You can also turn on `move-dup-mode' individually for each buffer.
(move-dup-mode)
