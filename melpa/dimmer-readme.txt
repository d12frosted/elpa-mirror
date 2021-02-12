
This module provides a minor mode that indicates which buffer is
currently active by dimming the faces in the other buffers.  It
does this nondestructively, and computes the dimmed faces
dynamically such that your overall color scheme is shown in a muted
form without requiring you to define what is a "dim" version of
every face.

`dimmer.el' can be configured to adjust foreground colors (default),
background colors, or both.

Usage:

     (require 'dimmer)
     (dimmer-configure-which-key)
     (dimmer-configure-helm)
     (dimmer-mode t)

Configuration:

By default dimmer excludes the minibuffer and echo areas from
consideration, so that most packages that use the minibuffer for
interaction will behave as users expect.

`dimmer-configure-company-box' is a convenience function for users
of company-box.  It prevents dimming the buffer you are editing when
a company-box popup is displayed.

`dimmer-configure-helm' is a convenience function for helm users to
ensure helm buffers are not dimmed.

`dimmer-configure-gnus' is a convenience function for gnus users to
ensure article buffers are not dimmed.

`dimmer-configure-hydra' is a convenience function for hydra users to
ensure  "*LV*" buffers are not dimmed.

`dimmer-configure-magit' is a convenience function for magit users to
ensure transients are not dimmed.

`dimmer-configure-org' is a convenience function for org users to
ensure org-mode buffers are not dimmed.

`dimmer-configure-posframe' is a convenience function for posframe
users to ensure posframe buffers are not dimmed.

`dimmer-configure-which-key' is a convenience function for which-key
users to ensure which-key popups are not dimmed.

Please submit pull requests with configurations for other packages!

Customization:

`dimmer-adjustment-mode' controls what aspect of the color scheme is adjusted
when dimming.  Choices are :foreground (default), :background, or :both.

`dimmer-fraction' controls the degree to which buffers are dimmed.
Range is 0.0 - 1.0, and default is 0.20.  Increase value if you
like the other buffers to be more dim.

`dimmer-buffer-exclusion-regexps' can be used to specify buffers that
should never be dimmed.  If the buffer name matches any regexp in
this list then `dimmer.el' will not dim that buffer.

`dimmer-buffer-exclusion-predicates' can be used to specify buffers that
should never be dimmed.  If any predicate function in this list
returns true for the buffer then `dimmer.el' will not dim that buffer.

`dimmer-prevent-dimming-predicates' can be used to prevent dimmer from
altering the dimmed buffer list.  This can be used to detect cases
where a package pops up a window temporarily, and we don't want the
dimming to change.  If any function in this list returns a non-nil
value, dimming state will not be changed.

`dimmer-watch-frame-focus-events' controls whether dimmer will dim all
buffers when Emacs no longer has focus in the windowing system.  This
is enabled by default.  Some users may prefer to set this to nil, and
have the dimmed / not dimmed buffers stay as-is even when Emacs
doesn't have focus.

`dimmer-use-colorspace' allows you to specify what color space the
dimming calculation is performed in.  In the majority of cases you
won't need to touch this setting.  See the docstring below for more
information.
