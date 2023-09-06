Usage:

Breadcrumbs are sequences of short strings indicating where you
are in some big tree-like maze.

To craft these strings, this library uses the maps provided by
project.el and Imenu, respectively.  Project breadcrumbs shows you
the current buffer's path in a large project.  Imenu breadcrumbs
show the current position of point in the buffer's nested
structure of programming constructs (for example, a specific
functions within multiple C++ nested namespaces).

To use this library:

* `M-x breadcrumb-mode` is a global mode.  Will try to turn itself
  on conservatively and only if there's a project.

* `M-x breadcrumb-local-mode` is a buffer-local minor mode, if you
   don't want the default heuristics for turning it on everywhere.

* Manually put the mode-line constructs

    (:eval (breadcrumb-imenu-crumbs))

  and

    (:eval (breadcrumb-project-crumbs))

 in your settings of the `mode-line-format' or
 `header-line-format' variables.

The shape and size of each breadcrumb groups may be tweaked via
`breadcrumb-imenu-max-length', `breadcrumb-project-max-length',
`breadcrumb-imenu-crumb-separator', and
`breadcrumb-project-crumb-separator'.

The structure each the breadcrumbs varies depending on whether
either project.el and imenu.el (or both) can do useful things for
your buffer.

For Project breadcrumbs, this depends on whether project.el's
`project-current' can guess what project the current buffer
belongs to.

For Imenu breadcrumbs, this varies.  Depending on the major-mode
author's taste, the Imenu tree (in variable `imenu--index-alist')
may have different structure.  Sometimes, minor mode also tweak
the Imenu tree in useful ways.  For example, with recent Eglot (I
think Eglot 1.14+), managed buffers get extra region info added to
it, which makes Breadcrumb show "richer" paths.

Implementation notes:

This _should_ be faster than which-func.el due some caching
strategies.  One of these strategies occurs in `bc--ipath-alist',
which takes care not to over-call `imenu--make-index-alist', which
could be slow (in fact very slow if an external process needs to
be contacted).  The variable `breadcrumb-idle-delay' controls
that.  Another cache occurs in `bc--ipath-plain-cache' second is
just a simple "space-for-speed" cache.

Breadcrumb uses the double-dashed Imenu symbols
`imenu--index-alist' and `imenu--make-index-alist'.  There's
really no official API here.  It's arguable that, despite the
name, these aren't really internal symbols (the much older
which-func.el library makes liberal use of them, for example).

Todo:

Make more clicky buttons in the headerline to do whatever