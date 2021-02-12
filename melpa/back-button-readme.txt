
Quickstart

    (require 'back-button)

    (back-button-mode 1)

    press the plus sign in the toolbar to create a mark

    press the arrows in the toolbar to navigate marks

    or use C-x C-Space as usual, then try C-x C-<right>
    to reverse the operation

Explanation

Back-button provides an alternative method for navigation by
analogy with the "back" button in a web browser.

Every Emacs command which pushes the mark leaves behind an
invisible record of the location of the point at that moment.
Back-button moves the point back and forth over all the positions
where some command pushed the mark.

This is essentially a replacement for `pop-global-mark', and the
default keybindings (when the minor mode is activated) override
that command.  The differences with `pop-global-mark' are:

   - Visual index showing how far you have traveled in the
     mark ring.

   - Easy way to move both forward and backward in the ring.

   - Pushes a mark on the first of a series of invocations, so you
     can always return to where you issued the command.

   - Skips duplicate positions, so that the interactive command
     always moves the point if possible.

Commands and keybindings are also included to give identical
semantics for navigating the local (per-buffer) `mark-ring'.  This
consistency in navigation comes at the cost of pushing the mark
twice, so experienced Emacs users may prefer to unbind these
commands and/or set `back-button-never-push-mark' in customize.

To use back-button, place the back-button.el library somewhere
Emacs can find it, and add the following to your ~/.emacs file:

    (require 'back-button)
    (back-button-mode 1)

Default key bindings:

    C-x C-<SPC>    go back in `global-mark-ring', respects prefix arg
    C-x C-<left>   go back in `global-mark-ring'
    C-x C-<right>  go forward in `global-mark-ring'

    C-x <SPC>      go back in (buffer-local) `mark-ring', respects prefix arg
    C-x <left>     go back in (buffer-local) `mark-ring'
    C-x <right>    go forward in (buffer-local) `mark-ring'

When the smartrep package is installed, the C-x prefix need not
be used for consecutive back-button commands.

When the visible-mark package is installed, marks will be
made visible in the current buffer during navigation.

See Also

    M-x customize-group RET back-button RET
    M-x customize-group RET editing-basics RET
    M-x customize-group RET visible-mark RET
    M-x customize-group RET nav-flash RET

Notes

    This library depends upon other commands pushing the mark to
    provide useful waypoints for navigation.  This is a common
    convention, but not universal.

    The function `back-button-push-mark-local-and-global' may be
    useful to call from Lisp.  It is a replacement for `push-mark'
    which unconditionally pushes onto the global mark ring,
    functionality which is not possible using vanilla `push-mark'.

    Theoretically, `back-button-push-mark-local-and-global' could
    cause issues with Lisp code which depends on the convention that
    `global-mark-ring' not contain consecutive marks in the same
    buffer.  However, no such issues have been observed.

Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.2           : yes, with some limitations
    GNU Emacs version 21.x and lower : unknown

    Uses if present: smartrep.el, nav-flash.el, visible-mark.el,
                     ucs-utils.el

Bugs

    Pressing the toolbar back-button can navigate to a different
    buffer with a different toolbar (and no back-button).

    Toolbar button disabling is not dependable.  Logic is left
    in place but unused.

    Toolbar shift-click does not work in Cocoa Emacs.

    Toolbar shift-click is not consistent with keyboard bindings
    (control for global ring, unmodified for local ring)

    Displaying the index in a popup requires unreleased popup-volatile.el

TODO

    better toolbar icons

    bug in visible-mark bug when mark is on last char of line

    integrated delete-mark

    could remove smartrep and implement mini-mode that includes
    extra commands such as delete-mark and perhaps digits
    for visible marks

    Used to remember thumb between series, so long as no mark was
    pushed, now that does not work b/c these functions themselves
    push the mark -- make that an option?  Maybe the right way is
    to keep it out-of-band.

    this is a crude but general way to force a navigation
    command to push the mark:

        (defvar push-mark-before-goto-char nil)
        (defadvice goto-char (before push-mark-first activate)
          (when push-mark-before-goto-char
            (back-button-push-mark-local-and-global nil t)))
        ;; example use
        (defun ido-imenu-push-mark ()
          (interactive)
          (let ((push-mark-before-goto-char t))
            (ido-imenu)))

    A better way would be: using a pre-command-hook, track series of
    related navigation commands (defined by a property placed on
    each command).  Push a global mark for the first of a related
    series, don't push for subsequent.  There is already a property
    placed on some navigation commands which might be sufficient -
    or is that only scroll commands?  There is a package AutoMark
    which purports to do this, but it doesn't do the hard part of
    classifying all commands.

; License

Simplified BSD License:

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

   1. Redistributions of source code must retain the above
      copyright notice, this list of conditions and the following
      disclaimer.

   2. Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials
      provided with the distribution.

This software is provided by Roland Walker "AS IS" and any express
or implied warranties, including, but not limited to, the implied
warranties of merchantability and fitness for a particular
purpose are disclaimed.  In no event shall Roland Walker or
contributors be liable for any direct, indirect, incidental,
special, exemplary, or consequential damages (including, but not
limited to, procurement of substitute goods or services; loss of
use, data, or profits; or business interruption) however caused
and on any theory of liability, whether in contract, strict
liability, or tort (including negligence or otherwise) arising in
any way out of the use of this software, even if advised of the
possibility of such damage.

The views and conclusions contained in the software and
documentation are those of the authors and should not be
interpreted as representing official policies, either expressed
or implied, of Roland Walker.
