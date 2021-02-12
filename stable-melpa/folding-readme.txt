{{{ Introduction

Preface

     This package provides a minor mode, compatible with all major
     editing modes, for folding (hiding) parts of the edited text or
     program.

     Folding mode handles a document as a tree, where each branch
     is bounded by special markers `{{{' and `}}}'. A branch can be
     placed inside another branch, creating a complete hierarchical
     structure. The markers:

     o  Are placed to the beginning of line. No spaces.
     o  Are prefixed by mode comment and space as needed.
        For example in C++ mode, the beginning marker is: "// {{{"
        See source code of folding.el and section "Set some useful default
        fold marks" for full listing of the markers. If you need to
        customize these markers, modify `folding-mode-marks-alist' after
        loading this package (See my-folding-load-hook example in this doc).

     Folding mode can CLOSE a fold, leaving only the initial `{{{'
     and possibly a comment visible.

     It can also ENTER a fold, which means that only the current
     fold will be visible, all text above `{{{' and below `}}}'
     will be invisible.

     Please note, that the maintainers do not recommend to use only
     folding for you your code layout and navigation. Folding.el is
     on its best when it can "chunk" large sections of code inside
     folds. The larger the chunks, the more the usability of
     folding will increase. Folding.el is not meant to hide
     individual functions: you may be better served by hideshow.el
     or imenu.el (which can parse the function indexes)

}}}
{{{ Installation

 Installation

     To install Folding mode, put this file (folding.el) on your
     Emacs `load-path' (or extend the load path to include the
     directory containing this file) and optionally byte compile it.

     The best way to install folding is the autoload installation,
     so that folding is loaded into your emacs only when you turn on
     `folding-mode'. This statement speeds up loading your .emacs

         (autoload 'folding-mode          "folding" "Folding mode" t)
         (autoload 'turn-off-folding-mode "folding" "Folding mode" t)
         (autoload 'turn-on-folding-mode  "folding" "Folding mode" t)

     But if you always use folding, then perhaps you want more
     traditional installation. Here Folding mode starts
     automatically when you load a folded file.

         ;; (setq folding-default-keys-function
         ;;      'folding-bind-backward-compatible-keys)

         (if (load "folding" 'nomessage 'noerror)
             (folding-mode-add-find-file-hook))

     Folding uses a keymap which conforms with the new Emacs
     (started 19.29) style. The key bindings are prefixed with
     "C-c@" instead of old "C-c". To use the old keyboard bindings,
     uncomment the lines in the the above installation example

     The same folding marks can be used in `vim' editor command
     "set fdm=marker".

 Uninstallation

     To remove folding, call `M-x' `folding-uninstall'.

 To read the manual

     At any point you can reach the manual with `M-x'
     `finder-commentary' RET folding RET.

}}}
{{{ DOCUMENTATION

 Compatibility

     Folding supports following Emacs flavors:

         Unix Emacs  19.28+ and Win32 Emacs  19.34+
         Unix XEmacs 19.14+ and Win32 XEmacs 21.0+

 Compatibility not for old NT Emacs releases

     NOTE: folding version starting from 2.47 gets around this bug
     by using adviced kill/yank functions. The advice functions are
     only instantiated under problematic NT Emacs versions.

     Windows NT/9x 19.34 - 20.3.1 (i386-*-nt4.0) versions contained
     a bug which affected using folding. At the time the bug was
     reported by Trey Jackson <trey A T cs berkeley edu>

         If you kill folded area and yank it back, the ^M marks are
         removed for some reason.

         Before kill
         ;;{{{ fold...

         After yank
         ;;{{{ fold all lines together }}}

 Related packages or modes

     Folding.el was designed to be a content organizer and it is most
     suitable for big files. Sometimes people misunderstand the
     package's capabilities and try to use folding.el in wrong places,
     where some other package would do a better job. Trying to wrap
     individual functions inside fold-marks is not where folding is
     it's best. Grouping several functions inside a logical fold-block
     in the other is. So, to choose a best tool for your need,
     here are some suggestions,:

     o  Navigating between or hiding individual functions -
        use combination of imenu.el, speedbar.el and
        hideshow.el
     o  Organizing large blocks - use folding.el
     o  For text, `outline-mode' is more non-intrusive than folding.
        Look at Emacs NEWS file (`C-x' `n') and you can see beautifully
        laid out content.

 Tutorial

     To start folding mode, give the command: `M-x' `folding-mode'
     `RET'. The mode line should contain the string "Fld" indicating
     that folding mode is activated.

     When loading a document containing fold marks, Folding mode is
     automatically started and all folds are closed. For example when
     loading my init file, only the following lines (plus a few lines
     of comments) are visible:

         ;;{{{ General...
         ;;{{{ Keyboard...
         ;;{{{ Packages...
         ;;{{{ Major modes...
         ;;{{{ Minor modes...
         ;;{{{ Debug...

     To enter a fold, use `C-c @ >'. To show it without entering,
     use `C-c @ C-s', which produces this display:

         ;;{{{ Minor modes

         ;;{{{ Follow mode...
         ;;{{{ Font-lock mode...
         ;;{{{ Folding...

         ;;}}}

     To show everything, just as the file would look like if
     Folding mode hadn't been activated, give the command `M-x'
     `folding-open-buffer' `RET', normally bound to `C-c' `@'
     `C-o'.  To close all folds and go to the top level, the
     command `folding-whole-buffer' could be used.

 Mouse support

     Folding mode v2.0 introduced mouse support. Folds can be shown
     or hidden by simply clicking on a fold mark using mouse button
     3. The mouse routines have been designed to call the original
     function bound to button 3 when the user didn't click on a
     fold mark.

 The menu

     A menu is placed in the "Tools" menu. Should no Tools menu exist
     (Emacs 19.28) the menu will be placed in the menu bar.

 ISearch

     When searching using the incremental search (C-s) facilities,
     folds will be automagically entered and closed.

 Problems

    Uneven fold marks

     Oops, I just deleted some text, and a fold mark got deleted!
     What should I do?  Trust me, you will eventually do this
     sometime. the easiest way is to open the buffer using
     `folding-open-buffer' (C-c @ C-o) and add the fold mark by
     hand. To find mismatching fold marks, the package `occur' is
     useful. The command:

         M-x occur RET {{{\|}}} RET

     will extract all lines containing folding marks and present
     them in a separate buffer.

     Even though all folding marks are correct, Folding mode
     sometimes gets confused, especially when entering and leaving
     folds very often. To get it back on track, press C-g a few
     times and give the command `folding-open-buffer' (C-c @ C-o).

    Fold must have a label

     When you make a fold, be sure to write some text for the name
     of the fold, otherwise there may be an error "extraneous fold
     mark..." Write like this:

         ;;{{{ Note
         ;;}}}

     instead of

         ;;{{{
         ;;}}}

    folding-whole-buffer doesn't fold whole buffer

     If you call commands `folding-open-buffer' and
     `folding-whole-buffer' and notice that there are open fold
     sections in the buffer, then you have mismatch of folds
     somewhere. Run ` M-x' `occur' and type regexp `{{{\|}}}' to
     check where is the extra open or closing fold mark.

 Folding and outline modes

     Folding mode is not the same as Outline mode, a major and
     minor mode which is part of the Emacs distribution. The two
     packages do, however, resemble each other very much.  The main
     differences between the two packages are:

     o   Folding mode uses explicit marks, `{{{' and `}}}', to
         mark the beginning and the end of a branch.
         Outline, on the other other hand, tries to use already
         existing marks, like the `\section' string in a TeX
         document.

     o   Outline mode has no end marker which means that it is
         impossible for text to follow a sub-branch.

     o   Folding mode use the same markers for branches on all depths,
         Outline mode requires that marks should be longer the
         further, down in the tree you go, e.g `\chap', \section',
         `\subsection', `\subsubsection'. This is needed to
         distinguish the next mark at the current or higher levels
         from a sub-branch, a problem caused by the lack of
         end-markers.

     o   Folding mode has mouse support, you can navigate through a
         folded document by clicking on fold marks. (The XEmacs version
         of Outline mode has mouse support.)

     o   The Isearch facilities of Folding is capable of
         automatically to open folds. Under Outline, the the entire
         document must be opened prior isearch.

     In conclusion, Outline mode is useful when the document being
     edited contains natural markers, like LaTeX. When writing code
     natural markers are hard to find, except if you're happy with
     one function per fold.

 Future development ideas

     The plan was from the beginning to rewrite the entire package.
     Including replacing the core of the program, written using
     old Emacs technology (selective display), and replace it with
     modern equivalences, like overlays or text-properties for
     Emacs and extents for XEmacs.

     It is not likely that any of this will come true considering
     the time required to rewrite the core of the package. Since
     the package, in it's current state, is much more powerful than
     the original, it would be appropriate to write such package
     from scratch instead of doing surgery on this one.

}}}

{{{ Customization

 Customization: general

     The behavior of Folding mode is controlled mainly by a set of
     Emacs Lisp variables. This section will discuss the most
     useful ones, for more details please see the code. The
     descriptions below assumes that you know a bit about how to
     use simple Emacs Lisp and knows how to edit ~/.emacs, your
     init file.

 Customization: hooks

     The normal procedure when customizing a package is to write a
     function doing the customization. The function is then added
     to a hook which is called at an appropriate time. (Please see
     the example section below.)  The following hooks are
     available:

     o   `folding-mode-hook'
          Called when folding mode is activated.
     o   `<major mode>-folding-hook'
          Called when starting folding mode in a buffer with major
          mode set to <major mode>. (e.g. When editing C code
          the hook `c-mode-folding-hook' is called.)
     o   `folding-load-hook'
          Called when folding mode is loaded into Emacs.

 Customization: The Mouse

     The variable `folding-behave-table' contains the actions which
     should be performed when the user clicks on an open fold, a
     closed fold etc.  For example, if you prefer to `enter' a fold
     rather than `open' it you should rebind this variable.

     The variable `folding-default-mouse-keys-function' contains
     the name of the function used to bind your mouse keys. To use
     your own mouse bindings, create a function, say
     `my-folding-bind-mouse', and set this variable to it.

 Customization: Keymaps

     When Emacs 19.29 was released, the keymap was divided into
     strict parts. (This division existed before, but a lot of
     packages, even the ones delivered with Emacs, ignored them.)

         C-c <letter>    -- Reserved for the users private keymap.
         C-c C-<letter>  -- Major mode. (Some other keys are
                            reserved as well.)
         C-c <Punctuation Char> <Whatever>
                         -- Reserved for minor modes.

     The reason why `C-c@' was chosen as the default prefix is that
     it is used by outline-minor-mode. It is not likely that few
     people will try to use folding and outline at the same time.

     However, old key bindings have been kept if possible.  The
     variable `folding-default-keys-function' specifies which
     function should be called to bind the keys. There are various
     function to choose from how user can select the keybindings.
     To use the old key bindings, add the following line to your
     init file:

         (setq folding-default-keys-function
               'folding-bind-backward-compatible-keys)

     To define keys similar to the keys used by Outline mode, use:

         (setq folding-default-keys-function
               'folding-bind-outline-compatible-keys)

 Customization: adding new major modes

     To add fold marks for a new major mode, use the function
     `folding-add-to-marks-list'. The command also replaces
     existing marks. An example:

         (folding-add-to-marks-list
          'c-mode "/* {{{ " "/* }}} */" " */" t)

 Customization: ISearch

     If you don't like the extension folding.el applies to isearch,
     set the variable `folding-isearch-install' to nil before
     loading this package.

}}}
{{{ Examples

 Example: personal setup

     To define your own key binding instead of using the standard
     ones, you can do like this:

          (setq folding-mode-prefix-key "\C-c")
          ;;
          (setq folding-default-keys-function
              '(folding-bind-backward-compatible-keys))
          ;;
          (setq folding-load-hook 'my-folding-load-hook)


          (defun my-folding-load-hook ()
            "Folding setup."

            (folding-install)  ;; just to be sure

            ;; ............................................... markers ...

            ;;  Change text-mode fold marks. Handy for quick
            ;;  sh/perl/awk code

            (defvar folding-mode-marks-alist)

            (let* ((ptr (assq 'text-mode folding-mode-marks-alist)))
              (setcdr ptr (list "# {{{" "# }}}")))

            ;; ........................................ bindings ...

            ;;  Put `folding-whole-buffer' and `folding-open-buffer'
            ;;  close together.

            (defvar folding-mode-prefix-map nil)

            (define-key folding-mode-prefix-map "\C-w" nil)
            (define-key folding-mode-prefix-map "\C-s"
                        'folding-show-current-entry)
            (define-key folding-mode-prefix-map "\C-p"
                        'folding-whole-buffer))

 Example: changing default fold marks

     In case you're not happy with the default folding marks, you
     can change them easily. Here is an example

         (setq folding-load-hook 'my-folding-load-hook)

         (defun my-folding-load-hook ()
           "Folding vars setup."
           ;;  Change marks for 'text-mode'
           (let* ((ptr (assq 'text-mode folding-mode-marks-alist)))
             (setcdr ptr (list "# {{{" "# }}}"))))

 Example: choosing different fold marks for mode

     Suppose you sometimes want to use different fold marks for the
     major mode: e.g. to alternate between "# {{{" and "{{{" in
     `text-mode' Call `M-x' `my-folding-text-mode-setup' to change
     the marks.

           (defun my-folding-text-mode-setup (&optional use-custom-folding-marks)
             (interactive
               (list (y-or-n-p "Use Custom fold marks now? ")))
             (let* ((ptr (assq major-mode folding-mode-marks-alist))
                    (default-begin "# {{{")
                    (default-end   "# }}}")
                    (begin "{{{")
                    (end   "}}}"))
               (when (eq major-mode 'text-mode)
                 (unless use-custom-folding-marks
                   (setq  begin default-begin  end default-end)))
               (setcdr ptr (list begin end))
               (folding-set-marks begin end)))

 Example: AucTex setup

     Suppose you're using comment.sty with AucTeX for editing
     LaTeX2e documents and you have these comment types. You would
     like to be able to set which of these 3 is to be folded at any
     one time, using a simple key sequence: move back and forth
     easily between the different comment types, e.g., "unfold
     everything then fold on \x".

         \O   ...  \endO
         \L   ...  \endL
         \B   ...  \endB

         (setq folding-load-hook 'my-folding-load-hook)

         (defun my-folding-load-hook ()
           "Folding vars setup."
           (let ((ptr (assq 'text-mode folding-mode-marks-alist)))
             (setcdr ptr (list "\\O" "\\endO"))
             (define-key folding-mode-prefix-map "C"
                        'my-folding-marks-change)))

         (defun my-folding-marks-change (&optional selection)
           "Select folding marks: prefixes nil, C-u and C-u C-u."
           (interactive "P")
           (let ((ptr (assq major-mode folding-mode-marks-alist))
                 input)
             (when (string-match "^\\(plain-\\|la\\|auc\\)?tex-"
                                 (symbol-name  major-mode))
               (setq input
                     (read-string "Latex \\end(X) Marker (default O): "
                                  nil nil "O" nil))
               (setq input (upcase input))
               (turn-off-folding-mode)
               (folding-add-to-marks-list
                major-mode
                (concat "\\" input) (concat "\\end" input) nil nil t)
               ;; (setcdr ptr (list (concat "\\" input) (concat "\\end" input)))
               (turn-on-folding-mode))))
         ;;  End of example

 Bugs: Lazy-shot.el conflict in XEmacs

     [XEmacs 20.4 lazy-shot-mode]
     1998-05-28 Reported by Solofo Ramangalahy <solofo A T mpi-sb mpg de>

         % xemacs -q folding.el
         M-x eval-buffer
         M-x folding-mode
         M-x font-lock-mode
         M-x lazy-shot-mode
         C-s mouse

     then search for mouse again and again. At some point you will
     see "Deleting extent" in the minibuffer and XEmacs freezes.

     The strange point is that I have this bug only under Solaris
     2.5 sparc (binaries from ftp.xemacs.org) but not under Solaris
     2.6 x86. (XEmacs 20.4, folding 2.35). I will try to access
     more machines to see if it's the same.

     I suspect that the culprit is lazy-shot as it is beta, but
     maybe you will be able to describe the bug more precisely to
     the XEmacs people I you can reproduce it.

}}}
{{{ Old Documentation

 Old documentation

     The following text was written by Jamie Lokier for the release
     of Folding 1.6. It is included here for history.

     Emacs 18:
     Folding mode has been tested with versions 18.55 and
     18.58 of Emacs.

     Epoch:
     Folding mode has been tested on Epoch 4.0p2.

     [X]Emacs:
     There is code in here to handle some aspects of XEmacs.
     However, up to version 19.6, there appears to be no way to
     display folds. Selective-display does not work, and neither do
     invisible extents, so Folding mode has no chance of
     working. This is likely to change in future versions of
     XEmacs.

     Emacs 19:
     Tested on version 19.8, appears to be fine. Minor bug:
     display the buffer in several different frames, then move in
     and out of folds in the buffer. The frames are automatically
     moved to the top of the stacking order.

     Some of the code is quite horrible, generally in order to
     avoid some Emacs display "features". Some of it is specific to
     certain versions of Emacs. By the time Emacs 19 is around and
     everyone is using it, hopefully most of it won't be necessary.

 More known bugs

     *** Needs folding-fold-region to be more intelligent about
     finding a good region. Check folding a whole current fold.

     *** Now works with 19!  But check out what happens when you
     exit a fold with the file displayed in two frames. Both
     windows get fronted. Better fix that sometime.

 Future features

     *** I will add a `folding-next-error' sometime. It will only
     work with Emacs versions later than 18.58, because compile.el
     in earlier versions does not count line-numbers in the right
     way, when selective display is active.

     *** Fold titles should be optionally allowed on the closing
     fold marks, and `folding-tidy-inside' should check that the
     opening title matches the closing title.

     *** `folded-file' set in the local variables at the end of a
     file could encode the type of fold marks used in that file,
     and other things, like the margins inside folds.

     *** I can see a lot of use for the newer features of Emacs 19:

     Using invisible text-properties (I hope they are intended to
     make text invisible; it isn't implemented like that yet), it
     will be possible to hide folded text without affecting the
     text of the buffer. At the moment, Folding mode uses selective
     display to hide text, which involves substituting
     carriage-returns for line-feeds in the buffer. This isn't such
     a good way. It may also be possible to display different folds
     in different windows in Emacs 19.

     Using even more text-properties, it may be possible to track
     pointer movements in and out of folds, and have Folding mode
     automatically enter or exit folds as necessary to maintain a
     sensible display. Because the text itself is not modified (if
     overlays are used to hide text), this is quite safe. It would
     make it unnecessary to provide functions like
     `folding-forward-char', `folding-goto-line' or
     `folding-next-error', and things like I-search would
     automatically move in and out of folds as necessary.

     Yet more text-properties/overlays might make it possible to
     avoid using narrowing. This might allow some major modes to
     indent text properly, e.g., C++ mode.

}}}
