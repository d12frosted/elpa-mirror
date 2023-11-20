
When using the non-native fullscreen mode of Emacs on modern MacBook Pro
machines, it ends up rendering buffer content behind the camera notch. This
package attempts to solve this by way of resizing the tab-bar to fill the
vertical space taken up by the camera notch.

Obviously `tab-bar-mode' must be enabled with the tab-bar visible at the top
of the frame for this package to be able to function.

Non-Native Fullscreen?

The default native fullscreen implementation on macOS can be rather annoying,
as it moves applications over to their own separate desktop Space. This
prevents you from layering windows from other applications on top it, among
other things.

Emacs supports both native and non-native fullscreen modes. In the non-native
mode, Emacs just acts like any other window, but stretches itself to cover
the whole screen, and hides the menu bar and dock. Non-native fullscreen is
enabled with:

    (setq ns-use-native-fullscreen nil)

In the non-native fullscreen mode, Emacs is not aware of the physical camera
notch however, so it does not know to avoid rendering things behind it.

Usage

You must be using `tab-bar-mode', with the tab-bar visible at the top of the
frame above all buffers.

Then simply add `tab-bar-notch-spacer' to the `tab-bar-format' variable, for
example:

    (setq tab-bar-format '(tab-bar-format-history
                           tab-bar-format-tabs
                           tab-bar-separator
                           tab-bar-format-add-tab
                           tab-bar-notch-spacer))

To disable the package, simply remove `tab-bar-notch-spacer', and it will
unregister itself from window resizing hooks.
