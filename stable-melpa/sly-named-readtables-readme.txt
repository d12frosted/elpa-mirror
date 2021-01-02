;
An external contrib for SLY that enables different readtables to be
active in different parts of the same file.

SLY lives at https://github.com/capitaomorte/sly.

; Installation:

Since this is an external contrib with both Elisp and Lisp parts,
merely loading the Elisp will have little effect. The contrib has
to be registered in SLY's `sly-contribs' variable for SLY to take care
of loading the Lisp side on demand.

For convenience, the `sly-named-readtables-autoloads.el' Elisp file
takes care of this automatically. So in your `~/.emacs' or
`~/.emacs.d/init/el' init file:

(setq inferior-lisp-program "/path/to/your/preferred/lisp")
(add-to-list 'load-path "/path/to/sly")
(require 'sly-autoloads)

(add-to-list 'load-path "/path/to/sly-named-readtables")
(require 'sly-named-readtables-autoloads)

In case you already have SLY loaded and/or running, you might have to
`M-x sly-setup' and `M-x sly-enable-contrib' to enable it.

`sly-named-readtables' should now kick in in Lisp buffers. You must
have `named-readtables` setup in your Lisp before it takes any actual
effect though. That's easy, just `(ql:quickload :named-readtables)'.
