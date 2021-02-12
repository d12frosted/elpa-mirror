Minor mode that can make all comments temporarily invisible.

In most situations, comments in a program are good.  However,
exuberant use of comments may make it harder to follow the flow of
the actual program.  By temporarily making comments invisible, the
program will stand out more clearly.

"Invisible" in this context means that the comments will not be
visible but they will still take up the same space they did before,
so non-comment portions will not move.

Example:

| Before                     | After                         |
| ------                     | -----                         |
| ![](doc/before.png)        | ![](doc/after.png)            |


Install:

Install this using the build-in Emacs package manager, e.g. using
`M-x package-install-from-file RET nocomments-mode.el RET'.

Usage:

This package provides two minor modes:

- `nocomments-mode' - Local minor mode that makes all comments in
  current buffer invisible.

- `nocomments-global-mode' - Global minor mode that makes all
  comments in all buffers invisible.

Configuration:

For convenience, you can bind a key to toggle the visibility of
comment.  For example, you can place the following in a suitable
init file to make F12 toggle comments:

    (global-set-key (kbd "<f12>") #'nocomments-mode)
