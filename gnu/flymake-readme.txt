Flymake is a minor Emacs mode performing on-the-fly syntax checks.

Flymake collects diagnostic information for multiple sources,
called backends, and visually annotates the relevant portions in
the buffer.

This file contains the UI for displaying and interacting with the
results produced by these backends, as well as entry points for
backends to hook on to.

The main interactive entry point is the `flymake-mode' minor mode,
which periodically and automatically initiates checks as the user
is editing the buffer.  The variables `flymake-no-changes-timeout',
`flymake-start-on-flymake-mode' give finer control over the events
triggering a check, as does the interactive command  `flymake-start',
which immediately starts a check.

Shortly after each check, a summary of collected diagnostics should
appear in the mode-line.  If it doesn't, there might not be a
suitable Flymake backend for the current buffer's major mode, in
which case Flymake will indicate this in the mode-line.  The
indicator will be `!' (exclamation mark), if all the configured
backends errored (or decided to disable themselves) and `?'
(question mark) if no backends were even configured.

For programmers interested in writing a new Flymake backend, the
docstring of `flymake-diagnostic-functions', the Flymake manual, and the
code of existing backends are probably good starting points.

The user wishing to customize the appearance of error types should
set properties on the symbols associated with each diagnostic type.
The standard diagnostic symbols are `:error', `:warning' and
`:note' (though a specific backend may define and use more).  The
following properties can be set:

* `flymake-bitmap', an image displayed in the fringe according to
`flymake-fringe-indicator-position'.  The value actually follows
the syntax of `flymake-error-bitmap' (which see).  It is overridden
by any `before-string' overlay property.

* `flymake-severity', a non-negative integer specifying the
diagnostic's severity.  The higher, the more serious.  If the
overlay property `priority' is not specified, `severity' is used to
set it and help sort overlapping overlays.

* `flymake-overlay-control', an alist ((OVPROP . VALUE) ...) of
further properties used to affect the appearance of Flymake
annotations.  With the exception of `category' and `evaporate',
these properties are applied directly to the created overlay.  See
Info Node `(elisp)Overlay Properties'.

* `flymake-category', a symbol whose property list is considered a
default for missing values of any other properties.  This is useful
to backend authors when creating new diagnostic types that differ
from an existing type by only a few properties.  The category
symbols `flymake-error', `flymake-warning' and `flymake-note' make
good candidates for values of this property.

For instance, to omit the fringe bitmap displayed for the standard
`:note' type, set its `flymake-bitmap' property to nil:

  (put :note 'flymake-bitmap nil)

To change the face for `:note' type, add a `face' entry to its
`flymake-overlay-control' property.

  (push '(face . highlight) (get :note 'flymake-overlay-control))

If you push another alist entry in front, it overrides the previous
one.  So this effectively removes the face from `:note'
diagnostics.

  (push '(face . nil) (get :note 'flymake-overlay-control))

To erase customizations and go back to the original look for
`:note' types:

  (cl-remf (symbol-plist :note) 'flymake-overlay-control)
  (cl-remf (symbol-plist :note) 'flymake-bitmap)