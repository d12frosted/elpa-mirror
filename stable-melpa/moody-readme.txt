This package provides utilities for displaying elements of the
mode line as tabs and ribbons.  It also provides replacements
for a few built-in elements.

The biggest differences to similar packages is that this one is
much simpler and much more consistent.  When using this package,
only the color of the mode line changes when a window becomes
in-/active.  Other packages additionally change what elements
are being displayed and also the appearance of an individual
element may change completely, which I found highly distracting
when trying out those packages, because I never knew what visual
clues to look for in order to find a certain piece of information.

Configuration
=============

Replacing default elements
--------------------------

To style the buffer identification, displayed in the mode line, as
shown at https://github.com/tarsius/moody, add the following to your
init file.

  (require 'moody)
  (moody-replace-mode-line-front-space)
  (moody-replace-mode-line-buffer-identification)
  (moody-replace-vc-mode)

Or if you are using `use-package'.

  (use-package moody
    :config
    (moody-replace-mode-line-front-space)
    (moody-replace-mode-line-buffer-identification)
    (moody-replace-vc-mode))

Moody provides functions named `moody-replace-...', each of which
replaces a particular element with a styled variant.  These functions
can also be called interactively, in which case they toggle between
using the styled and vanilla variants of their respective element.

To learn what element substitutions are available out of the box, use
M-x moody-replace- TAB.

Styling
-------

Depending on the used theme, the faces `mode-line', `mode-line-active'
and `mode-line-inactive' might have to be modified when using Moody.

Let's go through some changes that are commonly required.  We will be
using `set-face-attribute' to achieve this.  The calls to that function
should be placed right after `load-theme'.

These examples assume Emacs 29.1 or later.  If you use an older
release, modify `mode-line' instead of `mode-line-active'.

Many themes (including the default theme) set the `:box' attribute
for these faces.  That conflicts with Moody, so you most likely have
to remove those boxes.

  (set-face-attribute 'mode-line-active nil :box 'unspecified)
  (set-face-attribute 'mode-line-inactive nil :box 'unspecified)

A look similar to boxes can be achieved by using the `:overline' and
`:underline' attributes.

  (set-face-attribute 'mode-line-active nil :overline "blue")
  (set-face-attribute 'mode-line-active nil
                      :underline `(:color "blue" :position t))

  (set-face-attribute 'mode-line-inactive nil :overline "green")
  (set-face-attribute 'mode-line-inactive nil
                      :underline `(:color "green" :position t))

Beginning with Emacs 29.1, we can use :position t to put the
underline at the very bottom of the mode line.  When using an older
release, then this unfortunately can only be enabled globally.

  (setq x-underline-at-descent-line t)
