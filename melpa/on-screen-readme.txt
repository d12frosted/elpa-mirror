Scrolling can be distracting because your eyes may lose
orientation.  This library implements a minor mode that highlights
the previously visible buffer part after each scroll.

Installation: Put this library somewhere in your load-path, or
install via M-x package-list-packages.  Then add to your init-file:

  (require 'on-screen)

To invoke on-screen globally for all buffers, also add

  (on-screen-global-mode +1)

Alternatively you can use the buffer local version `on-screen-mode'.
For example, add this line to your init file:

  (add-hook 'Info-mode-hook 'on-screen-mode)

to enable it in all Info buffers.

By default, fringe markers are used for highlighting - see
`on-screen-highlight-method' to change that.  Type M-x
customize-group RET on-screen RET to see what else can be
configured.  If you use a configuration file (.emacs), you may also
want to define mode specific settings by using buffer local
variables.  For example, to use non intrusive fringe markers by
default, but transparent overlays in w3m, you would add

  (add-hook
   'w3m-mode-hook
   (defun my-w3m-setup-on-screen ()
     (setq-local on-screen-highlight-method 'shadow)))

to your .emacs.

If you use transparent overlays for highlighting and there is the
library "hexrgb.el" in your `load-path', it will be used to compute
highlighting colors dynamically instead of using constant faces.
I.e. if you use non-default background colors (e.g. from custom
themes), on-screen will try to perform highlighting with a
suitable, slightly different color.  See
`on-screen-highlighting-to-background-delta' to control this.


Implementation notes (mainly for myself):

Implementing this functionality is not as straightforward as one
might think.  There are commands that scroll other windows than the
current one.  Not only scrolling commands can scroll text - also
editing or even redisplay can cause windows to scroll.  There is
weird stuff such as folding and narrowing, influencing the visible
buffer part.  And although highlighting is realized in the
displayed buffers (with overlays), it must be organized on a
per-window basis, because different buffer parts may be displayed
in different windows, and their highlightings must not interfere.

That all makes it necessary to observe windows via hacks in
different hooks, and to manage information about buffers, visible
parts and timers in a data structure (`on-screen-data').  It is
realized as an association list whose keys are windows.  There are
some pitfalls - e.g. the data can be out of date if the window
configuration has changed and windows display different buffers
now.  The data must be updated, but not simply be thrown away,
because the highlightings in the old buffers must be removed
nonetheless.


Acknowledgments:

This library was inspired by a similar feature of the "Conqueror"
web browser.

Thanks for Drew Adams for testing and contributions.
