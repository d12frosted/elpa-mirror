gather.el provides search regexp and kill text.  This is not replacing
nor modifying Emacs `kill-ring' mechanism.  You MUST know about elisp
regular-expression.
Have similar concept of `occur'.  If I think `occur' have line oriented
feature, gather.el have list oriented feature.  You can handle the list,
as long as you can handle Emacs-Lisp list object.

## Install:

Put this file into load-path'ed directory, and byte compile it if
desired. And put the following expression into your ~/.emacs.

    (require 'gather)
    (define-key ctl-x-r-map "\M-w" 'gather-matching-kill-save)
    (define-key ctl-x-r-map "\C-w" 'gather-matching-kill)
    (define-key ctl-x-r-map "\M-y" 'gather-matched-insert)
    (define-key ctl-x-r-map "\M-Y" 'gather-matched-insert-with-format)
    (define-key ctl-x-r-map "v" 'gather-matched-show)

********** Emacs 22 or earlier **********
    (require 'gather)
    (global-set-key "\C-xr\M-w" 'gather-matching-kill-save)
    (global-set-key "\C-xr\C-w" 'gather-matching-kill)
    (global-set-key "\C-xr\M-y" 'gather-matched-insert)
    (global-set-key "\C-xr\M-Y" 'gather-matched-insert-with-format)
    (global-set-key "\C-xrv" 'gather-matched-show)

## Usage:

`C-x r M-w` : Kill the regexp in current-buffer.
`C-x r C-w` : Kill and delete regexp in current-buffer.
`C-x r M-y` : Insert killed text to point.
`C-x r M-Y` : Insert killed text as formatted text to point.
`C-x r v`   : View killed text status.

Why gather.el?

1. Hope to get list of function names in elisp file buffer.
2. C-x r M-w with regexp like "(defun \\(.+?\\_>\\)"
3. Now, you can paste function names by C-x r M-y with 1
4. Write a external document of functions has been gathered.
