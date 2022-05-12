
This file is for lazy people wanting to swap buffers without
typing C-x b on each window. This is useful when you have :

+--------------+-------------+
|              |             |
|    #emacs    |    #gnus    |
|              |             |
+--------------+-------------+
|                            |
|           .emacs           |
|                            |
+----------------------------+

and you want to have :

+--------------+-------------+
|              |             |
|    #gnus     |   .emacs    |
|              |             |
+--------------+-------------+
|                            |
|           #emacs           |
|                            |
+----------------------------+

With buffer-move, just go in #gnus, do buf-move-left, go to #emacs
(which now should be on top right) and do buf-move-down.

To use it, simply put a (require 'buffer-move) in your ~/.emacs and
define some keybindings. For example, i use :

(global-set-key (kbd "<C-S-up>")     'buf-move-up)
(global-set-key (kbd "<C-S-down>")   'buf-move-down)
(global-set-key (kbd "<C-S-left>")   'buf-move-left)
(global-set-key (kbd "<C-S-right>")  'buf-move-right)

Alternatively, you may let the current window switch back to the previous
buffer, instead of swapping the buffers of both windows. Set the
following customization variable to 'move to activate this behavior:

(setq buffer-move-behavior 'move)
