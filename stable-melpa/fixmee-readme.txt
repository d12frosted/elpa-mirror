
Quickstart

    (require 'fixmee)

    (global-fixmee-mode 1)

    right-click on the word "fixme" in a comment

    ;; for `next-error' support
    M-x fixmee-view-listing RET

Explanation

Fixmee-mode tracks "fixme" notices in code comments, highlights
them, ranks them by urgency, and lets you navigate to them quickly.

A distinguishing feature of this library is that it tracks the
urgency of each notice, allowing the user to jump directly to
the most important problems.

Urgency of "fixme" notices is indicated by repetitions of the final
character.  For example, one might write "FIXMEEEEEEEEE" for an
important issue.  The `fixmee-goto-nextmost-urgent' command will
navigate to the longest notice first.

To use fixmee-mode, add the following to your ~/.emacs

    (require 'fixmee)
    (global-fixmee-mode 1)

Then, open some buffers and right-click on the word "fixme" in a
comment

or press

    C-c f

or

    M-x fixmee RET

or

   roll the mouse wheel when hovering over the text "fixm"
   in the modeline.

or

   execute `fixmee-view-listing' to navigate using
   `next-error' conventions.

Key Bindings

The default key bindings are

    C-c f   `fixmee-goto-nextmost-urgent'
    C-c F   `fixmee-goto-prevmost-urgent'
    C-c v   `fixmee-view-listing'
    M-n     `fixmee-goto-next-by-position'      ; only when the point is
    M-p     `fixmee-goto-previous-by-position'  ; inside a "fixme" notice

To constrain the nextmost/prevmost-urgent commands to the current
buffer only, use a universal prefix argument, eg

    C-u C-c f

When the smartrep package is installed, the "C-c" prefix need not
be used for consecutive fixmee-mode keyboard commands.  Instead,
just keep pressing "f" (or whichever key you set in customize).

There is also a context menu and mouse-wheel bindings on the
minor-mode lighter in the modeline:

            mouse-1  context menu
      wheel-down/up  next/prev by urgency
    M-wheel-down/up  next/prev by position

Patterns

The following fixme patterns are supported by default:

    @@@
    XXX             ; only this one is case-sensitive
    todo
    fixme

See Also

    M-x customize-group RET fixmee RET
    M-x customize-group RET nav-flash RET

Notes

    Currently, only open buffers are searched, not files or
    projects.

Compatibility and Requirements

    GNU Emacs version 24.5-devel     : not tested
    GNU Emacs version 24.4           : yes
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.2           : yes, with some limitations
    GNU Emacs version 21.x and lower : unknown

    Requires: button-lock.el
              tabulated-list.el (included with Emacs 24.x)

    Uses if present: smartrep.el, nav-flash.el, back-button.el,
                     string-utils.el

Bugs

    fixmee--listview-mode-map (the major-mode menu) does not work
    well as a context menu.
        - menu from major mode of selected window appears even when
          right-clicking in this window
        - mouse-event wrappers keep keyboard shortcuts from appearing
          in menu-bar
        - better to have a separate context menu attached to the
          entries, using a keymap text property

    When comment-start is defined, only the first notice on a line
    is lit up by button-lock, though fixmee-mode is aware of multiple
    notices on a line.  This is worked around for the moment by
    stripping these cases from fixmee-notice-list.  Better would be
    to add comment-sensitivity logic to button-lock, and remove the
    comment-matching section of the regexp passed to button-lock.

    Fixmee-maybe-turn-on gets called multiple times when a file
    is loaded.

    Fixmee-buffer-include-functions may not contain the function
    'frame-bufs-associated-p, because a new buffer is not yet
    associated with the frame at the time the global mode check
    calls fixmee-maybe-turn-on.

    Bug in tabulated-list: position of point is not maintained
    when sort headers are clicked while a different window is
    selected.

    This package is generally incompatible with interactive modes
    such as `comint-mode' and derivatives, due conflicting uses
    of the rear-nonsticky text property.  To change this, set
    customizable variable fixmee-rear-nonsticky.

TODO

    Push mark for navigation which happens from the listview

    There is no need for fixmee--listview-mode to be an interactive
    command.

    Consider allowing all navigation commands to update the listview
    buffer (currently only next-error commands do so)

    Display fully fontified context lines in listview buffer - some
    lines have fontification, seemingly at random.  Disabling
    whitespace trimming and excluded properties had no effect.

    Multi-line context in listview buffer - tabulated-list accepts
    newlines, but data then runs out of the column on the next
    line.  Would need to pad to match column position.

    Better feedback messages for end-of-list and start-of-list.

    Bookmark integration? (implicit bookmarking on notices).

    Wrap/cycle options on navigation-by-position.

    How to get last-command when user does M-x? (smex is not helping
    here).  (nth 0 command-history) ?

    Navigation can land on line near vertical edge of window -
    should respect user settings and scroll in as needed for
    context.

    Project support.

    Some kind of extra comment indicating a notice is to be ignored?
    Lead with a backwhack?

; License

   Simplified BSD License

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
