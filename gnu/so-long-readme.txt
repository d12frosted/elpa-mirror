* Introduction
--------------
When the lines in a file are so long that performance could suffer to an
unacceptable degree, we say "so long" to the slow modes and options enabled
in that buffer, and invoke something much more basic in their place.

Many Emacs modes struggle with buffers which contain excessively long lines.
This is commonly on account of 'minified' code (i.e. code that has been
compacted into the smallest file size possible, which often entails removing
newlines should they not be strictly necessary).  This can result in lines
which are many thousands of characters long, and most programming modes
simply aren't optimised (remotely) for this scenario, so performance can
suffer significantly.

When so-long detects such a file, it calls the command `so-long', which
overrides certain minor modes and variables (you can configure the details)
to improve performance in the buffer.

The default action enables the major mode `so-long-mode' in place of the mode
that Emacs selected.  This ensures that the original major mode cannot affect
performance further, as well as making the so-long activity more obvious to
the user.  These kinds of minified files are typically not intended to be
edited, so not providing the usual editing mode in such cases will rarely be
an issue; however you can restore the buffer to its original state by calling
`so-long-revert' (the key binding of which is advertised when the major mode
change occurs).  If you prefer that the major mode not be changed in the
first place, there is a `so-long-minor-mode' action available, which you can
select by customizing the `so-long-action' user option.

The user options `so-long-action' and `so-long-action-alist' determine what
`so-long' and `so-long-revert' will do, enabling you to configure alternative
actions (including custom actions).  As well as the major and minor mode
actions provided by this library, `longlines-mode' is also supported by
default as an alternative action.

Note that while the measures taken can improve performance dramatically when
dealing with such files, this library does not have any effect on the
fundamental limitations of the Emacs redisplay code itself; and so if you do
need to edit the file, performance may still degrade as you get deeper into
the long lines.  In such circumstances you may find that `longlines-mode' is
the most helpful facility.

Note also that the mitigations are automatically triggered when visiting a
file.  The library does not automatically detect if long lines are inserted
into an existing buffer (although the `so-long' command can be invoked
manually in such situations).

* Installation
--------------
Use M-x global-so-long-mode to enable/toggle the functionality.  To enable
the functionality by default, either customize the `global-so-long-mode' user
option, or add the following to your init file:

  ;; Avoid performance issues in files with very long lines.
  (global-so-long-mode 1)

If necessary, ensure that so-long.el is in a directory in your load-path, and
that the library has been loaded.  (These steps are not necessary if you are
using Emacs 27+, or have installed the GNU ELPA package.)

* Overview of modes and commands
--------------------------------
- `global-so-long-mode' - A global minor mode which enables the automated
   behaviour, causing the user's preferred action to be invoked whenever a
   newly-visited file contains excessively long lines.
- `so-long-mode' - A major mode, and the default action.
- `so-long-minor-mode' - A minor mode version of the major mode, and an
   alternative action.
- `longlines-mode' - A minor mode provided by the longlines.el library,
   and another alternative action.
- `so-long' - Manually invoke the user's preferred action, enabling its
   performance improvements for the current buffer.
- `so-long-revert' - Restore the original state of the buffer.
- `so-long-customize' - Configure the user options.
- `so-long-commentary' - Read this documentation in outline-mode.

* Usage
-------
In most cases you will simply enable `global-so-long-mode' and leave it to
act automatically as required, in accordance with your configuration (see
"Basic configuration" below).

On rare occasions you may choose to manually invoke the `so-long' command,
which invokes your preferred `so-long-action' (exactly as the automatic
behaviour would do if it had detected long lines).  You might use this if a
problematic file did not meet your configured criteria, and you wished to
trigger the performance improvements manually.

It is also possible to directly use `so-long-mode' or `so-long-minor-mode'
(major and minor modes, respectively).  Both of these modes are actions
available to `so-long' but, like any other mode, they can be invoked directly
if you have a need to do that (see also "Other ways of using so-long" below).

If the behaviour ever triggers when you did not want it to, you can use the
`so-long-revert' command to restore the buffer to its original state.

* Basic configuration
---------------------
Use M-x customize-group RET so-long RET
(or M-x so-long-customize RET)

The user options `so-long-target-modes' and `so-long-threshold' determine
whether action will be taken automatically when visiting a file, and
`so-long-action' determines what will be done.

* Actions and menus
-------------------
The user options `so-long-action' and `so-long-action-alist' determine what
will happen when `so-long' and `so-long-revert' are invoked, and you can add
your own custom actions if you wish.  The selected action can be invoked
manually with M-x so-long; and in general M-x so-long-revert will undo the
effects of whichever action was used (which is particularly useful when the
action is triggered automatically, but the detection was a 'false positive'.)

All defined actions are presented in the "So Long" menu, which is visible
whenever long lines have been detected.  Selecting an action from the menu
will firstly cause the current action (if any) to be reverted, before the
newly-selected action is invoked.

Aside from the menu bar, the menu is also available in the mode line --
either via the major mode construct (when `so-long-mode' is active), or in
a separate mode line construct when some other major mode is active.

* Files with a file-local 'mode'
--------------------------------
A file-local major mode is likely to be safe even if long lines are detected
(the author of the file would otherwise be unlikely to have set that mode),
and so these files are treated as special cases.  When a file-local 'mode' is
present, the function defined by the `so-long-file-local-mode-function' user
option is called.  The default value will cause the `so-long-minor-mode'
action to be used instead of the `so-long-mode' action, if the latter was
going to be used for this file.  This is still a conservative default, but
this option can also be configured to inhibit so-long entirely in this
scenario, or to not treat a file-local mode as a special case at all.

* Buffers which are not displayed in a window
---------------------------------------------
When a file with long lines is visited and the buffer is not displayed right
away, it may be that it is not intended to be displayed at all, and that it
has instead been visited for behind-the-scenes processing by some library.
Invisible buffers are less likely to cause performance issues, and it also
might be surprising to the other library if such a buffer were manipulated by
`so-long' (which might in turn lead to confusing errors for the user); so in
these situations the `so-long-invisible-buffer-function' value is called
instead.  By default this arranges for `so-long' to be invoked on the buffer
if and when it is displayed, but not otherwise.

This 'deferred call' is actually the most common scenario -- even when a
visited file is displayed "right away", it is normal for the buffer to be
invisible when `global-so-long-mode' processes it, and the gap between
"arranging to call" and "calling" `so-long' is simply extremely brief.

* Inhibiting and disabling minor modes
--------------------------------------
Certain minor modes cause significant performance issues in the presence of
very long lines, and should be disabled automatically in this situation.

The simple way to disable most buffer-local minor modes is to add the mode
symbol to the `so-long-minor-modes' list.  Several modes are targeted by
default, and it is a good idea to customize this variable to add any
additional buffer-local minor modes that you use which you know to have
performance implications.

These minor modes are disabled if `so-long-action' is set to either
`so-long-mode' or `so-long-minor-mode'.  If `so-long-revert' is called, then
the original values are restored.

In the case of globalized minor modes, be sure to specify the buffer-local
minor mode, and not the global mode which controls it.

Note that `so-long-minor-modes' is not useful for other global minor modes
(as distinguished from globalized minor modes), but in some cases it will be
possible to inhibit or otherwise counter-act the behaviour of a global mode
by overriding variables, or by employing hooks (see below).  You would need
to inspect the code for a given global mode (on a case by case basis) to
determine whether it's possible to inhibit it for a single buffer -- and if
so, how best to do that, as not all modes are alike.

* Overriding variables
----------------------
`so-long-variable-overrides' is an alist mapping variable symbols to values.
If `so-long-action' is set to either `so-long-mode' or `so-long-minor-mode',
the buffer-local value for each variable in the list is set to the associated
value in the alist.  Use this to enforce values which will improve
performance or otherwise avoid undesirable behaviours.  If `so-long-revert'
is called, then the original values are restored.

* Retaining minor modes and settings when switching to `so-long-mode'
---------------------------------------------------------------------
A consequence of switching to a new major mode is that many buffer-local
minor modes and variables from the original major mode will be disabled.
For performance purposes this is a desirable trait of `so-long-mode', but
specified modes and variables can also be preserved across the major mode
transition by customizing the `so-long-mode-preserved-minor-modes' and
`so-long-mode-preserved-variables' user options.

When `so-long-mode' is called, the states of any modes and variables
configured by these options are remembered in the original major mode, and
reinstated after switching to `so-long-mode'.  Likewise, if `so-long-revert'
is used to switch back to the original major mode, these modes and variables
are again set to the same states.

The default values for these options ensure that if `view-mode' was active
in the original mode, then it will also be active in `so-long-mode'.

* Hooks
-------
`so-long-hook' runs at the end of the `so-long' command, after the configured
action has been invoked.

Likewise, if the `so-long-revert' command is used to restore the original
state then, once that has happened, `so-long-revert-hook' is run.

The major and minor modes also provide the usual hooks: `so-long-mode-hook'
for the major mode (running between `change-major-mode-after-body-hook' and
`after-change-major-mode-hook'); and `so-long-minor-mode-hook' (when that
mode is enabled or disabled).

* Troubleshooting
-----------------
Any elisp library has the potential to cause performance problems; so while
the default configuration addresses some important common cases, it's
entirely possible that your own config introduces problem cases which are
unknown to this library.

If visiting a file is still taking a very long time with so-long enabled,
you should test the following command:

emacs -Q -l so-long -f global-so-long-mode <file>

For versions of Emacs < 27, use:
emacs -Q -l /path/to/so-long.el -f global-so-long-mode <file>

If the file loads quickly when that command is used, you'll know that
something in your personal configuration is causing problems.  If this
turns out to be a buffer-local minor mode, or a user option, you can
likely alleviate the issue by customizing `so-long-minor-modes' or
`so-long-variable-overrides' accordingly.

The in-built profiler can be an effective way of discovering the cause
of such problems.  Refer to M-: (info "(elisp) Profiling") RET

In some cases it may be useful to set a file-local `mode' variable to
`so-long-mode', completely bypassing the automated decision process.
Refer to M-: (info "(emacs) Specifying File Variables") RET

If so-long itself causes problems, disable the automated behaviour with
M-- M-x global-so-long-mode, or M-: (global-so-long-mode 0)

* Example configuration
-----------------------
If you prefer to configure in code rather than via the customize interface,
then you might use something along these lines:

  ;; Enable so-long library.
  (when (require 'so-long nil :noerror)
    (global-so-long-mode 1)
    ;; Basic settings.
    (setq so-long-action 'so-long-minor-mode)
    (setq so-long-threshold 1000)
    (setq so-long-max-lines 100)
    ;; Additional target major modes to trigger for.
    (mapc (apply-partially #'add-to-list 'so-long-target-modes)
          '(sgml-mode nxml-mode))
    ;; Additional buffer-local minor modes to disable.
    (mapc (apply-partially #'add-to-list 'so-long-minor-modes)
          '(diff-hl-mode diff-hl-amend-mode diff-hl-flydiff-mode))
    ;; Additional variables to override.
    (mapc (apply-partially #'add-to-list 'so-long-variable-overrides)
          '((show-trailing-whitespace . nil)
            (truncate-lines . nil))))

* Mode-specific configuration
-----------------------------
The `so-long-predicate' function is called in the context of the buffer's
original major mode, and therefore major mode hooks can be used to control
the criteria for calling `so-long' in any given mode (plus its derivatives)
by setting buffer-local values for the variables in question.  This includes
`so-long-predicate' itself, as well as any variables used by the predicate
when determining the result.  By default this means `so-long-threshold' and
possibly also `so-long-max-lines' and `so-long-skip-leading-comments' (these
latter two are not used by default starting from Emacs 28.1).  E.g.:

  (add-hook 'js-mode-hook 'my-js-mode-hook)

  (defun my-js-mode-hook ()
    "Custom `js-mode' behaviours."
    (setq-local so-long-max-lines 100)
    (setq-local so-long-threshold 1000))

`so-long-variable-overrides' and `so-long-minor-modes' may also be given
buffer-local values in order to apply different settings to different types
of file.  For example, the Bidirectional Parentheses Algorithm does not apply
to `<' and `>' characters by default, and therefore one might prefer to not
set `bidi-inhibit-bpa' in XML files, on the basis that XML files with long
lines are less likely to trigger BPA-related performance problems:

  (add-hook 'nxml-mode-hook 'my-nxml-mode-hook)

  (defun my-nxml-mode-hook ()
    "Custom `nxml-mode' behaviours."
    (require 'so-long)
    (setq-local so-long-variable-overrides
                (remove '(bidi-inhibit-bpa . t) so-long-variable-overrides)))

Finally, note that setting `so-long-target-modes' to nil buffer-locally in
a major mode hook would prevent that mode from ever being targeted.  With
`prog-mode' being targeted by default, specific derivatives of `prog-mode'
could therefore be un-targeted if desired.

* Other ways of using so-long
-----------------------------
It may prove useful to automatically invoke major mode `so-long-mode' for
certain files, irrespective of whether they contain long lines.

To target specific files and extensions, using `auto-mode-alist' is the
simplest method.  To add such an entry, use:
(add-to-list 'auto-mode-alist (cons REGEXP 'so-long-mode))
Where REGEXP is a regular expression matching the filename.  e.g.:

- Any filename with a particular extension ".foo":
  (rx ".foo" eos)

- Any file in a specific directory:
  (rx bos "/path/to/directory/")

- Only *.c filenames under that directory:
  (rx bos "/path/to/directory/" (zero-or-more not-newline) ".c" eos)

- Match some sub-path anywhere in a filename:
  (rx "/sub/path/foo")

- A specific individual file:
  (rx bos "/path/to/file" eos)

Another way to target individual files is to set a file-local `mode'
variable.  Refer to M-: (info "(emacs) Specifying File Variables") RET

`so-long-minor-mode' can also be called directly if desired.  e.g.:
(add-hook 'FOO-mode-hook 'so-long-minor-mode)

In Emacs 26.1 or later (see "Caveats" below) you also have the option of
using file-local and directory-local variables to determine how `so-long'
behaves.  e.g. -*- so-long-action: longlines-mode; -*-

The buffer-local `so-long-function' and `so-long-revert-function' values may
be set directly (in a major mode hook, for instance), as any existing value
for these variables will be used in preference to the values defined by the
selected action.  For file-local or directory-local usage it is preferable to
set only `so-long-action', as all function variables are marked as 'risky',
meaning you would need to add to `safe-local-variable-values' in order to
avoid being queried about them.

Finally, the `so-long-predicate' user option enables the automated behaviour
to be determined by a custom function, if greater control is needed.

* Implementation notes
----------------------
This library advises `set-auto-mode' (in order to react after Emacs has
chosen the major mode for a buffer), and `hack-local-variables' (so that we
may behave differently when a file-local mode is set).  In earlier versions
of Emacs (< 26.1) we also advise `hack-one-local-variable' (to prevent a
file-local mode from restoring the original major mode if we had changed it).

Many variables are permanent-local because after the normal major mode has
been set, we potentially change the major mode to `so-long-mode', and it's
important that the values which were established prior to that are retained.

* Caveats
---------
The variables affecting the automated behaviour of this library (such as
`so-long-action') can be used as file- or dir-local values in Emacs 26+, but
not in previous versions of Emacs.  This is on account of improvements made
to `normal-mode' in 26.1, which altered the execution order with respect to
when local variables are processed.  In earlier versions of Emacs the local
variables are processed too late, and hence have no effect on the decision-
making process for invoking `so-long'.  It is unlikely that equivalent
support will be implemented for older versions of Emacs.  The exception to
this caveat is the `mode' pseudo-variable, which is processed early in all
versions of Emacs, and can be set to `so-long-mode' if desired.

* Change Log:

1.1.2 - Use `so-long-mode-line-active' face on `mode-name' in `so-long-mode'.
1.1.1 - Identical to 1.1, but fixing an incorrect GNU ELPA release.
1.1   - Utilise `buffer-line-statistics' in Emacs 28+, with the new
        `so-long-predicate' function `so-long-statistics-excessive-p'.
      - Increase `so-long-threshold' from 250 to 10,000.
      - Increase `so-long-max-lines' from 5 to 500.
      - Include `fundamental-mode' in `so-long-target-modes'.
      - New user option `so-long-mode-preserved-minor-modes'.
      - New user option `so-long-mode-preserved-variables'.
1.0   - Included in Emacs 27.1, and in GNU ELPA for prior versions of Emacs.
      - New global mode `global-so-long-mode' to enable/disable the library.
      - New user option `so-long-action'.
      - New user option `so-long-action-alist' defining alternative actions.
      - New user option `so-long-variable-overrides'.
      - New user option `so-long-skip-leading-comments'.
      - New user option `so-long-file-local-mode-function'.
      - New user option `so-long-invisible-buffer-function'.
      - New user option `so-long-predicate'.
      - New variable and function `so-long-function'.
      - New variable and function `so-long-revert-function'.
      - New command `so-long' to invoke `so-long-function' interactively.
      - New command `so-long-revert' to invoke `so-long-revert-function'.
      - New minor mode action `so-long-minor-mode' facilitates retaining the
        original major mode, while still disabling minor modes and overriding
        variables like the major mode `so-long-mode'.
      - Support `longlines-mode' as a `so-long-action' option.
      - Added "So Long" menu, including all selectable actions.
      - Added mode-line indicator, user option `so-long-mode-line-label',
        and faces `so-long-mode-line-active', `so-long-mode-line-inactive'.
      - New help commands `so-long-commentary' and `so-long-customize'.
      - Refactored the default hook values using variable overrides
        (and returning all the hooks to nil default values).
      - Performance improvements for `so-long-detected-long-line-p'.
      - Converted defadvice to nadvice.
0.7.6 - Bug fix for `so-long-mode-hook' losing its default value.
0.7.5 - Documentation.
      - Added sgml-mode and nxml-mode to `so-long-target-modes'.
0.7.4 - Refactored the handling of `whitespace-mode'.
0.7.3 - Added customization group `so-long' with user options.
      - Added `so-long-original-values' to generalise the storage and
        restoration of values from the original mode upon `so-long-revert'.
      - Added `so-long-revert-hook'.
0.7.2 - Remember the original major mode even with M-x `so-long-mode'.
0.7.1 - Clarified interaction with globalized minor modes.
0.7   - Handle header 'mode' declarations.
      - Hack local variables after reverting to the original major mode.
      - Reverted `so-long-max-lines' to a default value of 5.
0.6.5 - Inhibit globalized `hl-line-mode' and `whitespace-mode'.
      - Set `buffer-read-only' by default.
0.6   - Added `so-long-minor-modes' and `so-long-hook'.
0.5   - Renamed library to "so-long.el".
      - Added explicit `so-long-enable' command to activate our advice.
0.4   - Amended/documented behaviour with file-local 'mode' variables.
0.3   - Defer to a file-local 'mode' variable.
0.2   - Initial release to EmacsWiki.
0.1   - Experimental.