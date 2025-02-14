# a68-mode -- Algol68 major mode

This mode fully supports automatic indentation and font locking
(i.e. syntax highlighting) including the three comment styles.

a68-mode supports only the UPPER stropping style and not the QUOTE or
POINT style.

A minor mode a68-pretty-bold-tags-mode is provided that, when active,
makes bold tags in the buffer appear in lower case and styled
according to the a68-bold-tag-face.  This allows to show bold tags as
underlined, or bold, or whatever other visual characteristic that can
be configured in an Emacs face.

A minor mode a68-auto-stropping-mode is provided that, when active,
applies upper stropping automatically as you type, to both keywords
and mode indicators defined in the current buffer.

### Manual installation

Just put a68-mode.el somewhere in your load-path and require it.
Or visit the file with Emacs and M-x package-install-file RET.

### Customization

The following variables are available for customization:

 * a68-indent-level (default 3): indentation offset
 * a68-comment-style (default "#"): the default comment style used
   by e.g. comment-dwim.

see M-x customize-group a68 RET for more info.

### Known issues

It doesn't handle well shebangs: #! is taken as the start of the
comment up to the next #.

### Little history of this code

Jose E. Marchesi wrote the first version of a68-mode.el.

At some point someone got a copy of a68-mode.el, renamed it to
algol-mode.el and distributed it in github.

Then Omar Polo forked algol-mode.el, renaming it back to a68-mode.el.

Finally at some point Jose decided to ditch his original version and
start using and maintain Omar's version instead.

This is that copy.
