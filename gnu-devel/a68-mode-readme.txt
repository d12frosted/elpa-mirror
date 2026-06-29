# a68-mode -- Algol68 major mode

This mode fully supports automatic indentation and font locking
(i.e. syntax highlighting) including the three comment styles.

a68-mode supports the classical UPPER stropping regime and the more
modern SUPPER stropping implemented by the GCC Algol 68 front-end.
The mode will assume SUPPER stropping unless the string "pr UPPER pr"
is found anywhere in the program text.

### Manual installation

Just put a68-mode.el somewhere in your load-path and require it.
Or visit the file with Emacs and M-x package-install-file RET.

### Customization

The following variables are available for customization:

 * a68-indent-level (default 3): indentation offset
 * a68-comment-style-{upper,supper} (default "#"): the default comment style used
   by e.g. comment-dwim.

see M-x customize-group a68 RET for more info.

### Little history of this code

Jose E. Marchesi wrote the first version of a68-mode.el.

At some point someone got a copy of a68-mode.el, renamed it to
algol-mode.el and distributed it in github.

Then Omar Polo forked algol-mode.el, renaming it back to a68-mode.el.

Finally at some point Jose decided to ditch his original version and
start using and maintain Omar's version instead.

This is that copy.
