
Quickstart

    (require 'button-lock)

    (global-button-lock-mode 1)

    (setq url-button (button-lock-set-button
                      "\\<http://[^[:space:]\n]+"
                      'browse-url-at-mouse
                      :face 'link :face-policy 'prepend))

Explanation

Button-lock is a minor mode which provides simple facilities to
define clickable text based on regular expressions.  Button-lock.el
piggybacks on font-lock.el, and is efficient.  Overlays are not
used.

Button-lock buttons (links) can execute any function.

There is little user-level interface for button-lock.el, which is
intended to be used from Emacs Lisp.  For a user-friendly library
built on top of button-lock.el, see wiki-nav.el or fixmee.el

    http://github.com/rolandwalker/button-lock/blob/master/wiki-nav.el
    http://github.com/rolandwalker/fixmee

Example usage

    (require 'button-lock)
    (global-button-lock-mode 1)

    ;; add a mouseable button to all occurrences of a word
    (button-lock-set-button "hello" 'beginning-of-line)

    ;; to remove that button later, pass all the same arguments to
    ;; button-lock-unset-button
    (button-lock-unset-button "hello" 'beginning-of-line)

    ;; or, save the result and pass it back to the unset function
    (setq mybutton (button-lock-set-button "hello" 'beginning-of-line))
    (button-lock-unset-button mybutton)

    ;; create a fancy raised button
    (require 'cus-edit)
    (button-lock-set-button "hello" #'(lambda ()
                                              (interactive)
                                              (save-match-data
                                                (deactivate-mark)
                                                (if (re-search-forward "hello" nil t)
                                                    (goto-char (match-beginning 0))
                                                  (goto-char (point-min))
                                                  (deactivate-mark)
                                                  (if (re-search-forward "hello" nil t)
                                                      (goto-char (match-beginning 0))))))
                            :face 'custom-button-face :mouse-face 'custom-button-mouse)

    ;; activate hyperlinks
    (button-lock-set-button "\\<http://[^[:space:]\n]+"
                            'browse-url-at-mouse
                            :face 'link :face-policy 'prepend)

    ;; activate hyperlinks only in lines that begin with a comment character
    (button-lock-set-button "^\\s-*\\s<.*?\\<\\(http://[^[:space:]\n]+\\)"
                            'browse-url-at-mouse
                            :face 'link :face-policy 'prepend :grouping 1)

    ;; turn folding-mode delimiters into mouseable buttons
    (add-hook 'folding-mode-hook  #'(lambda ()
                                      (button-lock-mode 1)
                                      (button-lock-set-button
                                       (concat "^" (regexp-quote (car (folding-get-mode-marks))))
                                       'folding-toggle-show-hide)
                                      (button-lock-set-button
                                       (concat "^" (regexp-quote (cadr (folding-get-mode-marks))))
                                       'folding-toggle-show-hide)))

    ;; create a button that responds to the keyboard, but not the mouse
    (button-lock-set-button "\\<http://[^[:space:]\n]+"
                            'browse-url-at-point
                            :mouse-binding     nil
                            :mouse-face        nil
                            :face             'link
                            :face-policy      'prepend
                            :keyboard-binding "RET")

    ;; define a global button, to be set whenever the minor mode is activated
    (button-lock-register-global-button "hello" 'beginning-of-line)

Interface

Button-lock is intended to be used via the following functions

    `button-lock-set-button'
    `button-lock-unset-button'
    `button-lock-extend-binding'
    `button-lock-clear-all-buttons'
    `button-lock-register-global-button'
    `button-lock-unregister-global-button'
    `button-lock-unregister-all-global-buttons'

See Also

    M-x customize-group RET button-lock RET

Prior Art

    hi-lock.el
    David M. Koppelman <koppel@ece.lsu.edu>

    buttons.el
    Miles Bader <miles@gnu.org>

Notes

    By default, button-lock uses newfangled left-clicks rather than
    Emacs-traditional middle clicks.

    Font lock is very efficient, but it is still possible to bog
    things down if you feed it expensive regular expressions.  Use
    anchored expressions, and be careful about backtracking.  See
    `regexp-opt'.

    Some differences between button-lock.el and hi-lock.el:

        * The purpose of hi-lock.el is to change the _appearance_
          of keywords.  The purpose of button-lock is to change the
          _bindings_ on keywords.

        * Hi-lock also supports embedding new keywords in files,
          which is too risky of an approach for button-lock.

        * Hi-lock supports overlays and can work without font-lock.

    Some differences between button-lock.el and buttons.el

        * Buttons.el is for inserting individually defined
          buttons.  Button-lock.el is for changing all matching text
          into a button.

Compatibility and Requirements

    GNU Emacs version 24.5-devel     : not tested
    GNU Emacs version 24.4           : yes
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3           : yes
    GNU Emacs version 22.2           : yes, with some limitations
    GNU Emacs version 21.x and lower : unknown

    No external dependencies

Bugs

    Case-sensitivity of matches depends on how font-lock-defaults
    was called for the current mode (setting
    font-lock-keywords-case-fold-search).  So, it is safest to
    assume that button-lock pattern matches are case-sensitive --
    though they might not be.

    Return value for button-lock-register-global-button is inconsistent
    with button-lock-set-button.  The global function does not
    return a button which could be later passed to
    button-lock-extend-binding, nor are the arguments parsed and
    checked for validity.  Any errors for global buttons are also
    deferred until the mode is activated.

    This package is generally incompatible with interactive modes
    such as `comint-mode' and derivatives, due conflicting uses
    of the rear-nonsticky text property.  To change this, :rear-sticky
    can be set when `calling button-lock-set-button'.  See also
    https://github.com/rolandwalker/fixmee/issues/8#issuecomment-75397467 .

TODO

    Validate arguments to button-lock-register-global-button.
    maybe split set-button into create/set functions, where
    the create function does all validation and returns a
    button object.  Pass in button object to unset as well.

    Why are mouse and keyboard separate, can't mouse be passed
    through kbd macro?  The issue may have been just surrounding
    mouse events with "<>" before passing to kbd.

    Look into new syntax-propertize-function variable (Emacs 24.x).

    A refresh function to toggle every buffer?

    Peek into font-lock-keywords and deduplicate based on the
    stored patterns.

    Substitute a function for regexp to make properties invisible
    unless button-lock mode is on - esp for keymaps.

    Add predicate argument to button-set where predicate is
    evaluated during matcher.  This could be used to test for
    comment-only.

    Consider defining mode-wide button locks (pass the mode as the
    first argument of font-lock-add-keywords).  Could use functions
    named eg button-lock-set-modal-button.

    Add a language-specific navigation library (header files in C,
    etc).

    Example of exchanging text values on wheel event.

    Convenience parameters for right-click menus.

    Button-down visual effects as with Emacs widgets.

License

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

Ths software is provided by Roland Walker "AS IS" and any express
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
