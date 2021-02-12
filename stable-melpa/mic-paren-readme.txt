----------------------------------------------------------------------
Short Description:

Load this file, activate it and Emacs will display highlighting on
whatever parenthesis (and paired delimiter if you like this) matches
the one before or after point.  This is an extension to the paren.el
file distributed with Emacs.  The default behaviour is similar to
paren.el but more sophisticated.  Normally you can try all default
settings to enjoy mic-paren.

Some examples to try in your ~/.emacs:

 (add-hook 'LaTeX-mode-hook
           (function (lambda ()
                       (paren-toggle-matching-quoted-paren 1)
                       (paren-toggle-matching-paired-delimiter 1))))

 (add-hook 'c-mode-common-hook
           (function (lambda ()
                        (paren-toggle-open-paren-context 1))))

If you use CUA mode, these might be useful, too:

 (put 'paren-forward-sexp 'CUA 'move)
 (put 'paren-backward-sexp 'CUA 'move)

----------------------------------------------------------------------
Installation:

o Place this file in a directory in your `load-path' and byte-compile
  it.  If there are warnings, please report them to ttn.
o Put the following in your .emacs file:
     (require 'mic-paren) ; loading
     (paren-activate)     ; activating
     ;;; set here any of the customizable variables of mic-paren:
     ;;; ...
o Restart your Emacs; mic-paren is now installed and activated!
o To list the possible customizations type `C-h f paren-activate' or
  go to the customization group `mic-paren-matching'.

----------------------------------------------------------------------
Long Description:

mic-paren.el is an extension and replacement to the packages paren.el
and stig-paren.el for Emacs.  When mic-paren is active Emacs normal
parenthesis matching is deactivated.  Instead parenthesis matching will
be performed as soon as the cursor is positioned at a parenthesis.  The
matching parenthesis (or the entire structured expression between the
parentheses) is highlighted until the cursor is moved away from the
parenthesis.  Features include:
o Both forward and backward parenthesis matching (simultaneously if
  cursor is between two expressions).
o Indication of mismatched parentheses.
o Recognition of "escaped" (also often called "quoted") parentheses.
o Recognition of SML-style "sexp-ish" comment syntax.
  NB: This support is preliminary; there are still problems
      when the parens in the comment span multiple lines, etc.
o Option to match "escaped" parens too, especially in (La)TeX-mode
  (e.g., matches expressions like "\(foo bar\)" properly).
o Offers two functions as replacement for `forward-sexp' and
  `backward-sexp' which handle properly quoted parens (s.a.).  These
  new functions can automatically be bounded to the original binding
  of the standard `forward-sexp' and `backward-sexp' functions.
o Option to activate matching of paired delimiter (i.e., characters with
  syntax '$').  This is useful for writing in LaTeX-mode for example.
o Option to select in which situations (always, never, if match, if
  mismatch) the entire expression should be highlighted or only the
  matching parenthesis.
o Message describing the match when the matching parenthesis is off-screen
  (vertical and/or horizontal).  Message contains either the linenumber or
  the number of lines between the two matching parens.  Option to select in
  which cases this message should be displayed.
o Optional delayed highlighting (useful on slow systems),
o Functions to activate/deactivate mic-paren.el are provided.
o Numerous options to control the behaviour and appearance of
  mic-paren.el.

mic-paren.el was originally developed and tested under Emacs 19.28 -
20.3.  Since then, support for Emacs 19 and 20 has bit-rotted (not
dropped completely, but not tested against changes, either), and
will probably be removed without warning in a future version.  This
version was developed and tested under Emacs 23.0.60 (wip).  XEmacs
compatibility has been provided by Steven L Baur <steve@xemacs.org>.
Jan Dubois (jaduboi@ibm.net) provided help to get mic-paren to work in
OS/2.

This file (and other wonderful stuff) can be obtained from
the Emacs Wiki: <http://www.emacswiki.org/>

----------------------------------------------------------------------
Available customizable options:
- `paren-priority'
- `paren-overlay-priority'
- `paren-sexp-mode'
- `paren-highlight-at-point'
- `paren-highlight-offscreen'
- `paren-display-message'
- `paren-message-linefeed-display'
- `paren-message-no-match'
- `paren-message-show-linenumber'
- `paren-message-truncate-lines'
- `paren-max-message-length'
- `paren-ding-unmatched'
- `paren-delay'
- `paren-dont-touch-blink'
- `paren-match-face'
- `paren-mismatch-face'
- `paren-no-match-paren'
- `paren-bind-modified-sexp-functions'
Available customizable faces:
- `paren-face-match'
- `paren-face-mismatch'
- `paren-face-no-match'
Available commands:
- `paren-activate'
- `paren-deactivate'
- `paren-toggle-matching-paired-delimiter'
- `paren-toggle-matching-quoted-paren'
- `paren-toggle-open-paren-context'
- `paren-forward-sexp'
- `paren-backward-sexp'
----------------------------------------------------------------------

IMPORTANT NOTES (important for people who have customized mic-paren
                 from within elisp):
- In version >= 3.3 the prefix "mic-" has been removed from the
  command-names `mic-paren-forward-sexp' and `mic-paren-backward-sexp'.
  Now all user-functions and -options begin with the prefix "paren-"
  because this package should be a replacement of the other
  paren-packages like paren.el and stig-paren.el!
- In version >= 3.2 the prefix "mic-" has been removed from the
  command-names `mic-paren-toggle-matching-quoted-paren' and
  `mic-paren-toggle-matching-paired-delimiter'.
- In versions >= 3.1 mic-paren is NOT auto-activated after loading.
- In versions >= 3.0 the variable `paren-face' has been renamed to
  `paren-match-face'.

----------------------------------------------------------------------
Versions:
v3.13   + Fix bug introduced in v3.12: Use ‘cl-flet*’.

v3.12   + Avoid naked ‘flet’; use ‘cl-flet’ instead.
          Thanks to Le Wang.

v3.11   + Added support for recognizing SML-style comments as a sexp.
          Thanks to Leo Liu, Stefan Monnier.

v3.10   + Added message-length clamping (var `paren-max-message-length').
          Thanks to Jonathan Kotta.

v3.9    + Fixed XEmacs bug in `define-mic-paren-nolog-message'.
          Thanks to Sivaram Neelakantan.

v3.8    + Maintainership (crassly) grabbed by ttn.
        + License now GPLv3+.
        + Byte-compiler warnings eliminated; if you see one, tell me!
        + Dropped funcs: mic-char-bytes, mic-char-before.
        + Docstrings, messages, comments revamped.

v3.7    + Removed the message "You should be in LaTeX-mode!".
        + Fixed a bug in `paren-toggle-matching-quoted-paren'.
        + Fixed some misspellings in the comments and docs.

v3.6    + Fixed a very small bug in `mic-paren-horizontal-pos-visible-p'.
        + The informational messages like "Matches ... [+28]" which are
          displayed if the matching paren is offscreen, do not longer
          wasting the log.

v3.5    + No mic-paren-messages are displayed if we are in isearch-mode.
        + Matching quoted parens is switched on if entering a minibuffer.
          This is useful for easier inserting regexps, e.g., with
          `query-replace-regexp'.  Now \(...\) will be highlighted
          in the minibuffer.
        + New option `paren-message-show-linenumber': You can determine
          the computation of the offscreen-message-linenumber.  Either the
          number of lines between the two matching parens or the absolute
          linenumber.  (Thank you for the idea and a first implementation
          to Eli Barzilay <eli@barzilay.org>.)
        + New option `paren-message-truncate-lines': If mic-paren messages
          should be truncated or not (has only an effect in GNU Emacs 21).
          (Thank you for the idea and a first implementation to Eli
          Barzilay <eli@barzilay.org>.)

v3.4    + Corrected some bugs in the backward-compatibility for older
          Emacsen.  Thanks to Tetsuo Tsukamoto <czkmt@remus.dti.ne.jp>.

v3.3    + Now the priority of the paren-overlays can be customized
          (option `paren-overlay-priority').  For a description of the
          priority of an overlay see in the emacs-lisp-manual the node
          "Overlays".  This option is mainly useful for experienced
          users which use many packages using overlays to perform their
          tasks.
        + Now you can determine what line-context will be displayed if
          the matching open paren is offscreen.  In functional
          programming languages like lisp it is useful to display the
          following line in the echo-area if the opening matching paren
          has no preceding text in the same line.
          But in procedural languages like C++ or Java it is convenient
          to display the first previous non empty line in this case
          instead of the following line.  Look at the new variable
          `paren-open-paren-context-backward' and the related toggling
          function `paren-toggle-open-paren-context' for a detailed
          description of this new feature.
        + In addition to the previous described new feature you can
          specify how a linefeed in the message (e.g., if the matching
          paren is offscreen) is displayed.  This is mainly because the
          standard echo-area display of a linefeed (^J) is bad to read.
          Look at the option `paren-message-linefeed-display'.
        + Solved a little bug in the compatibility-code for Emacsen
          not supporting current customize-feature.
        + Removed the prefix "mic-" from the commands
          `mic-paren-forward-sexp' and `mic-paren-backward-sexp'.
          For an explanation look at comments for version v3.2.

v3.2    + The prefix "mic-" has been removed from the commands
          `mic-paren-toggle-matching-quoted-paren' and
          `mic-paren-toggle-matching-paired-delimiter'.  This is for
          consistency.  Now all user-variables, -faces and -commands
          begin with the prefix "paren-" and all internal functions
          and variables begin with the prefix "mic-paren-".
        + Now you can exactly specify in which situations the whole
          sexp should be highlighted (option `paren-sexp-mode'):
          Always, never, if match or if mismatch.  Tested with Gnus
          Emacs >= 20.3.1 and XEmacs >= 21.1.

v3.1    + From this version on mic-paren is not autoloaded.  To
          activate it you must call `paren-activate' (either in your
          .emacs or manually with M-x).  Therefore the variable
          `paren-dont-activate-on-load' ise obsolet and has been
          removed.
        + Now mic-paren works also in older Emacsen without the
          custom-feature.  If the actual custom-library is provided
          mic-paren use them and is full customizable otherwise normal
          defvars are used for the options.
        + Fix of a bug displaying a message if the matching paren is
          horizontal out of view.
        + All new features are now tested with XEmacs >= 21.1.6.

v3.0    + Checking if matching paren is horizontally offscreen (in
          case of horizontal scrolling).  In that case the message is
          displayed in the echo-area (anlogue to vertical offscreen).
          In case of horizontal offscreen closing parenthesis the
          displayed message is probably wider than the frame/window.
          So you can only read the whole message if you are using a
          package like mscroll.el (scrolling long messages) in GNU
          Emacs.
        + Now full customizable, means all user-options and -faces now
          can be set with the custom-feature of Emacs.  On the other
          hand, this means this version of mic-paren only works with an
          Emacs which provides the custom-package!
        + In case of the matching paren is offscreen now the displayed
          message contains the linenumber of the matching paren too.
        This version is only tested with Gnu Emacs >= 20.4 and not with
        any XEmacs!
        Implemented by Klaus Berndl <berndl@sdm.de>.

v2.3    No additional feature but replacing `char-bytes' and
        `char-before' with `mic-char-bytes' and `mic-char-before' to
        prevent a clash in the global-namespace.  Now the new
        features of v2.1 and v2.2 are also tested with XEmacs!

v2.2    Adding the new feature for matching paired delimiter.  Not
        tested with XEmacs.  Implemented by Klaus Berndl <berndl@sdm.de>

v2.1    Adding the new feature for matching escaped parens too.  Not
        tested with XEmacs.  Implemented by Klaus Berndl <berndl@sdm.de>.

v2.0    Support for MULE and Emacs 20 multibyte characters added.
        Inspired by the suggestion and code of Saito Takaaki
        <takaaki@is.s.u-tokyo.ac.jp>.

v1.9    Avoids multiple messages/dings when point has not moved.  Thus,
        mic-paren no longer overwrites messages in minibuffer.  Inspired by
        the suggestion and code of Eli Barzilay <eli@barzilay.org>.

v1.3.1  Some spelling corrected (from Vinicius Jose Latorre
        <vinicius@cpqd.br> and Steven L Baur <steve@xemacs.org>).

v1.3    Added code from Vinicius Jose Latorre <vinicius@cpqd.br> to
        highlight unmatched parentheses (useful in minibuffer).

v1.2.1  Fixed stuff to work with OS/2 emx-emacs:
         - checks if `x-display-colour-p' is bound before calling it;
         - changed how X/Lucid Emacs is detected.
        Added automatic load of the timer-feature (plus variable to
        disable the loading).
