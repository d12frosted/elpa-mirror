
This package provides commands to toggle the visibility of Lisp
docstrings in code buffers.  It works with any major mode that uses
`font-lock-doc-face' for docstring highlighting and supports standard
s-expression navigation.

The core idea is to reduce visual clutter when reviewing code structure,
refactoring, or studying codebases while keeping documentation readily
available when needed.

The package uses Emacs overlays to hide text non-destructively: buffer
content is never modified, and all changes are purely visual.

Key features:

* Buffer-wide toggling of all docstrings
* Point-specific toggling of individual docstrings
* Configurable hiding styles (complete, partial, first-line)
* Debug mode to inspect detected docstrings
* Works with mixed fontification (like hl-todo)

The detection algorithm is robust: it uses font-lock to identify
docstrings, then parses string literal boundaries to handle escaped
quotes and face splits correctly.  This works reliably across Emacs Lisp,
Common Lisp, Scheme, and other Lisp dialects.

Basic usage:

    M-x lisp-docstring-toggle           ; Toggle all docstrings
    M-x lisp-docstring-toggle-at-point  ; Toggle docstring at point

With the minor mode enabled (default bindings):

    C-c , t   ; Toggle all docstrings
    C-c , .   ; Toggle docstring at point
    C-c , D   ; Show debug information

The prefix key C-c , can be customized via
`lisp-docstring-toggle-keymap-prefix'. For example, if you prefer
C-c C-d and it doesn't conflict with your major modes:

    (setq lisp-docstring-toggle-keymap-prefix "C-c C-d")

Customization:

The hiding style is controlled by `lisp-docstring-toggle-hide-style':

- `complete': Hide entire docstring (default)
- `partial': Show first N characters plus ellipsis
- `first-line': Show only first line plus ellipsis


The package draws inspiration from several places:

- `hideif.el': Overlay-based hiding patterns
- `outline.el': Folding interface conventions
- `pel-hide-docstring.el': Partial visibility concept

For detailed usage and customization, see the docstrings of:
- `lisp-docstring-toggle'
- `lisp-docstring-toggle-at-point'
- `lisp-docstring-toggle-hide-style'
- `lisp-docstring-toggle-mode'
