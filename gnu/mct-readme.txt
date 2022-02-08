	    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	     MINIBUFFER AND COMPLETIONS IN TANDEM (MCT.EL)

			  Protesilaos Stavrou
			  info@protesilaos.com
	    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `mct' (or `mct.el' and variants), and provides every other
piece of information pertinent to it.

The documentation furnished herein corresponds to stable version 0.5.0,
released on 2022-02-08.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 0.6.0-dev.

Table of Contents
─────────────────

1. COPYING
2. Overview of MCT
3. Customizations
.. 1. Format of the Completions
.. 2. Live completion
.. 3. Minimum input threshold
.. 4. Delay between live updates
.. 5. Live updates per command or completion category
..... 1. Passlist for commands or completion categories
..... 2. Blocklist for commands or completion categories
..... 3. Known completion categories
.. 6. Size boundaries of the Completions
.. 7. Dynamic completion tables in mct-minibuffer-mode
.. 8. Hide the Completions mode line
.. 9. Remove shadowed file paths
.. 10. Alternating backgrounds in the Completions
.. 11. MCT in the minibuffer and in regular buffers
4. Usage
.. 1. Cyclic behaviour for mct-minibuffer-mode
.. 2. Selecting candidates with mct-minibuffer-mode
.. 3. Other commands for mct-minibuffer-mode
.. 4. Interaction model of mct-region-mode
5. Installation
.. 1. Install the package
.. 2. Manual installation method
6. Sample setup
7. Known issues and workarounds
.. 1. Avoid global-hl-line-mode in the Completions
8. Keymaps
.. 1. The use of remap for key bindings
9. User-level tweaks or custom code
.. 1. Sort completion candidates on Emacs 29
.. 2. MCT in the current or the other window
10. Extensions
.. 1. Enable Consult previews
.. 2. Avoid conflict between MCT and Corfu
11. Alternatives
12. Acknowledgements
13. Official sources
14. GNU Free Documentation License
15. Indices
.. 1. Function index
.. 2. Variable index
.. 3. Concept index


1 COPYING
═════════

  Copyright (C) 2021 Free Software Foundation, Inc.

        Permission is granted to copy, distribute and/or modify
        this document under the terms of the GNU Free
        Documentation License, Version 1.3 or any later version
        published by the Free Software Foundation; with no
        Invariant Sections, with the Front-Cover Texts being “A
        GNU Manual,” and with the Back-Cover Texts as in (a)
        below.  A copy of the license is included in the section
        entitled “GNU Free Documentation License.”

        (a) The FSF’s Back-Cover Text is: “You have the freedom to
        copy and modify this GNU manual.”


2 Overview of MCT
═════════════════

  Minibuffer and Completions in Tandem, also known as “MCT”, “Mct”,
  `mct', or `mct.el', is a package that enhances the default minibuffer
  and `*Completions*' buffer of Emacs 27 (or higher) so that they work
  together as part of a unified framework.  The idea is to make the
  presentation and overall functionality be consistent with other
  popular, vertically aligned completion UIs while leveraging built-in
  functionality.

  The main feature set that unifies the minibuffer and the
  `*Completions*' buffer consists of commands that cycle between the
  two, making it seem like they are part of a contiguous space ([Basic
  usage]).

  MCT tries to find a middle ground between the frugal defaults and the
  more opinionated completion UIs.  This is most evident in its approach
  on how to present completion candidates.  Instead of showing them
  outright or only displaying them on demand, MCT implements a minimum
  input threshold as well as a slight delay before it pops up the
  `*Completions*' buffer and starts updating it to respond to user
  input.


[Basic usage] See section 4


3 Customizations
════════════════

  MCT is highly configurable to adapt to the varying needs of users.
  This section documents each user option.


3.1 Format of the Completions
─────────────────────────────

  Brief: Set the presentation of candidates in the Completions’ buffer.

  Symbol: `mct-completions-format' (`choice' type)

  Possible values:

  1. `one-column' (default—only works on Emacs 28 or higher)
  2. `horizontal'
  3. `vertical'

  By default, MCT tries to display completion candidates in a single
  column.  This only works for Emacs version 28 or higher.  In older
  versions of Emacs, the choices are between two grid views as explained
  in the built-in user option `completions-format', with the fallback
  being the `horizontal' style.


3.2 Live completion
───────────────────

  Brief: Control auto-display and live-update of the `*Completions*'
  buffer.

  Symbol: `mct-live-completion' (`choice' type)

  Possible values:

  1. `nil'
  2. `t' (default)
  3. `visible'

  This user option governs the overall behaviour of MCT with regard to
  how it uses the Completions’ buffer:

  ⁃ When nil, the user has to manually request completions, using the
    regular activating commands ([Usage]).  The Completions’ buffer is
    never updated live to match user input.  Updating has to be handled
    manually.  This is like the out-of-the-box minibuffer completion
    experience.

  ⁃ When set to `visible', the Completions’ buffer is live updated only
    if it is visible (present in a window).  The actual display of the
    completions is still handled manually.  For this reason, the
    `visible' style does not read the `mct-minimum-input', meaning that
    it will always try to live update the visible completions,
    regardless of input length ([Minimum input threshold]).

  ⁃ When non-nil (the default), the Completions’ buffer is automatically
    displayed once the `mct-minimum-input' is met and is hidden if the
    input drops below that threshold.  While visible, the buffer is
    updated live to match the user’s input.

  Note that every command or completion category that is declared in the
  `mct-completion-passlist' ignores this option altogether.  This means
  that every such symbol will always show the Completions’ buffer
  automatically and will always update its contents live to match any
  further user input ([Passlist for commands or completion categories]).
  Same principle for the `mct-completion-blocklist', which will always
  disable both the automatic display and live updating of the
  Completions’ buffer ([Blocklist for commands or completion
  categories]).

  [Size boundaries of the Completions].


[Usage] See section 4

[Minimum input threshold] See section 3.3

[Passlist for commands or completion categories] See section 3.5.1

[Blocklist for commands or completion categories] See section 3.5.2

[Size boundaries of the Completions] See section 3.6


3.3 Minimum input threshold
───────────────────────────

  Brief: Try to live update completions when input is >= N.

  Symbol: `mct-minimum-input' (`natnum' type)

  By default, MCT expects the user to type `3' characters before it
  tries to compute completion candidates, display the `*Completions*'
  buffer and keep it updated live to match any subsequent input.

  Setting this user option to a value greater than 1 can help reduce the
  total number of candidates that are being computed.  That is because
  the Completions can consist of thousands of items that all need to be
  rendered at once in a buffer.

  In terms of the user experience, the minimum input threshold can make
  sessions feel less visually demanding when the user (i) knows what
  they are looking for and (ii) types fast enough so that the
  `*Completions*' never have the time to pop up.

  This variable is ignored for commands or completion categories that
  are specified in the `mct-completion-passlist' and
  `mct-completion-blocklist'.

  [Live updates per command or completion category].


[Live updates per command or completion category] See section 3.5


3.4 Delay between live updates
──────────────────────────────

  Brief: Delay in seconds before updating the Completions’ buffer.

  Symbol: `mct-live-update-delay' (`number' type)

  The delay in seconds between live updates of the Completions’ buffer.
  The default value is `0.3'.

  This variable is ignored for commands or completion categories that
  are specified in the `mct-completion-passlist' and
  `mct-completion-blocklist'.

  [Live updates per command or completion category].


[Live updates per command or completion category] See section 3.5


3.5 Live updates per command or completion category
───────────────────────────────────────────────────

  By default, MCT has the same behaviour across all types of completion.
  Specifically, it respects the `mct-live-completion' option on whether
  and when to perform live completion, the `mct-minimum-input' threshold
  before doing so, and the `mct-live-update-delay' between changes to
  the `*Completions*' buffer.

  [Live completion].

  [Minimum input threshold].

  [Delay between live updates].

  A passlist and a blocklist can override those options for the commands
  or categories specified.


[Live completion] See section 3.5.2

[Minimum input threshold] See section 3.3

[Delay between live updates] See section 3.4

3.5.1 Passlist for commands or completion categories
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  [ Updated as part of 0.6.0-dev. ]

  Brief: List of symbols where live completions are always enabled.

  Symbol: `mct-completion-passlist' (`repeat symbol' type)

  The value of this user option is a list of symbols.  Those can refer
  to commands like `find-file' or completion categories such as `file',
  `buffer', or what other packages define like Consult’s
  `consult-location' category.

  Any entry in the passlist ignores the value of `mct-live-completion'
  and the `mct-minimum-input'.  It also bypasses any possible delay
  introduced by `mct-live-update-delay'.  In other words, it immediately
  displays the `*Completions*' buffer and instantly updates it to match
  user input.

  [Known completion categories].


[Known completion categories] See section 3.5.3


3.5.2 Blocklist for commands or completion categories
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  [ Updated as part of 0.6.0-dev. ]

  Brief: List of symbols where live completions are always disabled.

  Symbol: `mct-completion-blocklist' (`repeat symbol' type)

  The value of this user option is a list of symbols.  Those can refer
  to commands like `find-file' or completion categories such as `file',
  `buffer', or what other packages define like Consult’s
  `consult-location' category.

  This means that they ignore `mct-live-completion'.  They do not
  automatically display the Completions’ buffer, nor do they update it
  to match user input.

  The Completions’ buffer can still be accessed with commands that place
  it in a window (such as `mct-list-completions-toggle',
  `mct-switch-to-completions-top').

  Perhaps a less drastic measure is to set `mct-minimum-input' to an
  appropriate value.  Or better use `mct-completion-passlist'.

  [Known completion categories].


[Known completion categories] See section 3.5.3


3.5.3 Known completion categories
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Below are the known completion categories that can be added to the
  `mct-completion-passlist' and `mct-completion-blocklist' (and relevant
  custom code).  This resource is non-exhaustive and will be updated to
  match available information.

  ⁃ `bookmark'
  ⁃ `buffer'
  ⁃ `charset'
  ⁃ `coding-system'
  ⁃ `color'
  ⁃ `command' (e.g. `M-x')
  ⁃ `customize-group'
  ⁃ `environment-variable'
  ⁃ `expression'
  ⁃ `face'
  ⁃ `file'
  ⁃ `function' (the `describe-function' command bound to `C-h f')
  ⁃ `info-menu'
  ⁃ `imenu'
  ⁃ `input-method'
  ⁃ `kill-ring'
  ⁃ `library'
  ⁃ `minor-mode'
  ⁃ `multi-category'
  ⁃ `package'
  ⁃ `project-file'
  ⁃ `symbol' (the `describe-symbol' command bound to `C-h o')
  ⁃ `theme'
  ⁃ `unicode-name' (the `insert-char' command bound to `C-x 8 RET')
  ⁃ `variable' (the `describe-variable' command bound to `C-h v')

  From the `consult' package:

  ⁃ `consult-grep'
  ⁃ `consult-isearch'
  ⁃ `consult-isearch'
  ⁃ `consult-kmacro'
  ⁃ `consult-location'

  From the `embark' package:

  ⁃ `embark-keybinding'

  In general, it is best not to add symbols which include several
  thousands of candidates to the passlist.  So no `command', `function',
  `symbol', `unicode-name', `variable'.

  When in doubt, do not add a symbol to either the pass- or block- list.


3.6 Size boundaries of the Completions
──────────────────────────────────────

  Brief: Set the maximum and minimum height of the Completions’ buffer.

  Symbol: `mct-completion-window-size' (`choice' type between nil and
  cons cell)

  The value is a cons cell in the form of `(max-height . min-height)'
  where each value is either a natural number or a function which
  returns such a number.

  The default maximum height of the window is calculated by the function
  `mct--frame-height-fraction', which finds the closest round number to
  1/3 of the frame’s height.  While the default minimum height is 1.
  This means that during live completions the Completions’ window will
  shrink or grow to show candidates within the specified boundaries.  To
  disable this bouncing effect, set both max-height and min-height to
  the same number.

  If nil, do not try to fit the Completions’ buffer to its window.

  [Live completion].


[Live completion] See section 3.2


3.7 Dynamic completion tables in mct-minibuffer-mode
────────────────────────────────────────────────────

  [ Part of 0.6.0-dev. ]

  Brief: Whether to keep dynamic completion live.

  Symbol: `mct-persist-dynamic-completion' (`boolean' type)

  Possible values:

  1. `nil'
  2. `t' (default)

  Without any intervention from MCT, the default Emacs behavior for
  commands such as `find-file' or for a `file' completion category is to
  hide the `*Completions*' buffer after updating the list of candidates
  in a non-exiting fashion (e.g. select a directory and expect to
  continue typing the path).  This, however, runs contrary to the
  interaction model of MCT when it performs live completions, because
  the user expects the Completions’ buffer to remain visible while
  typing out the path to the file ([Live completion]).

  When this user option is non-nil (the default) it makes all
  non-exiting commands keep the `*Completions*' visible when updating
  the list of candidates.

  This applies to prompts in the `file' completion category whenever the
  user selects a candidate with `mct-choose-completion-no-exit',
  `mct-edit-completion', `minibuffer-complete',
  `minibuffer-force-complete' (i.e. any command that does not exit the
  minibuffer).

  [Selecting candidates with mct-minibuffer-mode].

  The two exceptions are (i) when the current completion session runs a
  command or category that is blocked by the `mct-completion-blocklist'
  or (ii) the user option `mct-live-completion' is nil.

  [Blocklist for commands or completion categories].

  The underlying rationale:

  Most completion commands present a flat list of candidates to choose
  from.  Picking a candidate concludes the session.  Some prompts,
  however, can recalculate the list of completions based on the selected
  candidate.  A case in point is `find-file' (or any command with the
  `file' completion category) which dynamically adjusts the completions
  to show only the elements which extend the given file system path.  We
  call such cases “dynamic completion”.  Due to their particular nature,
  these need to be handled explicitly.  The present user option is
  provided primarily to raise awareness about this state of affairs.


[Live completion] See section 3.2

[Selecting candidates with mct-minibuffer-mode] See section 4.2

[Blocklist for commands or completion categories] See section 3.5.2


3.8 Hide the Completions mode line
──────────────────────────────────

  Brief: Do not show a mode line in the Completions’ buffer.

  Symbol: `mct-hide-completion-mode-line' (`boolean' type)

  By default, the `*Completions*' buffer has its own mode line, just
  like every other window.  Set this user option to non-nil to remove
  the mode line.


3.9 Remove shadowed file paths
──────────────────────────────

  Brief: Delete shadowed parts of file names from the minibuffer.

  Symbol: `mct-remove-shadowed-file-names' (`boolean' type)

  When the built-in `file-name-shadow-mode' is enabled and this user
  option is non-nil, MCT will delete the part of the file path that is
  shadowed (meaning that it is overriden) by the given input.

  For example, if the user types `~/' after a long path name, everything
  preceding the `~/' is removed so the interactive selection process
  starts again from the user’s `$HOME'.


3.10 Alternating backgrounds in the Completions
───────────────────────────────────────────────

  Brief: Use alternating backgrounds in the Completions.

  Symbol: `mct-apply-completion-stripes' (`boolean' type)

  By default, the `*Completions*' buffer uses the main background of the
  active theme (more specifically the `:background' attribute of the
  `default' face).  When set to non-nil, MCT applies applies alternating
  background colors in the Completions’ buffer.  These are in a shade of
  gray that contrasts with the main background.

  Due to the specific nature of this style, there is no basic face that
  can be inherited to achieve a consistent result across themes.  As
  such, it only looks as intended with the `modus-themes' (built into
  Emacs 28 or higher or available as a package).  Other themes would
  need to add support for the `mct-stripe' face.


3.11 MCT in the minibuffer and in regular buffers
─────────────────────────────────────────────────

  Emacs draws a distinction between two types of completion sessions:

  ⁃ Completion where the minibuffer is involved (such as to switch
    buffers or find a file).

  ⁃ Completion in a regular buffer to expand the text before point.  The
    minibuffer is not active.  We call this “in-buffer completion” or
    allude to the underlying function: `completion-in-region'.

  The former scenario is what MCT has supported since its inception.
  Starting with version `0.4.0' it also covers the latter case, though
  only experimentally (please report any bugs or point towards areas of
  possible improvement).

  To let users fine-tune their setup, MCT provides the
  `mct-minibuffer-mode' (formerly `mct-mode') as well as the global
  `mct-region-mode'.

  The decoupling between the two modes makes it possible to configure
  interchangeable components in a variety of combinations, such as MCT
  for the minibuffer and the Corfu package for completion-in-region
  ([Extensions]).  Or the Vertico package for the minibuffer and MCT for
  in-buffer completion ([Alternatives]).

  We jokingly say that since the introduction of `mct-region-mode' the
  acronym “MCT” now stands for “Minibuffer Confines Transcended”—the
  original was “Minibuffer and Completions in Tandem”.

  [Interaction model of mct-region-mode].


[Extensions] See section 10

[Alternatives] See section 11

[Interaction model of mct-region-mode] See section 4.4


4 Usage
═══════

  This section outlines the various patterns of interaction that MCT
  establishes.  Note that completion covers two distinct cases, which
  are reflected in the design of MCT: (i) in the minibuffer and (ii) for
  in-buffer completion ([MCT in the minibuffer and in regular buffers]).
  Most of this section is about the former scenario, which uses the
  `mct-minibuffer-mode'.  The `mct-region-mode' is less featureful by
  comparison.


[MCT in the minibuffer and in regular buffers] See section 3.11

4.1 Cyclic behaviour for mct-minibuffer-mode
────────────────────────────────────────────

  When `mct-minibuffer-mode' is enabled, some new keymaps are activated
  which add commands for cycling between the minibuffer and the
  completions.  Suppose the following standard layout:

  ┌────
  │ -----------------
  │ |        |      |
  │ | Buffers| Buf  |
  │ |        |      |
  │ -----------------
  │ |        |      |
  │ | Buf    | Buf  |
  │ |        |      |
  │ -----------------
  │ -----------------
  │ |               |
  │ |  Completions  |
  │ |               |
  │ -----------------
  │ -----------------
  │ |  Minibuffer   |
  │ -----------------
  └────

  When inside the minibuffer, pressing `C-n' (or down arrow) takes you
  to the top of the completions, while `C-p' (or up arrow) moves to the
  bottom.  The commands are `mct-switch-to-completions-top' for the
  former and `mct-switch-to-completions-bottom' for the latter.  If the
  `*Completions*' are not shown, then the buffer pops up automatically
  and point moves to the given position.

  Similarly, while inside the `*Completions*' buffer, `C-p' (or up
  arrow) at the top of the buffer switches to the minibuffer, while
  `C-n' (or down arrow) at the bottom of the buffer also goes to the
  minibuffer.  If point is anywhere else inside the buffer, those key
  bindings perform a regular line motion (if the `*Completions*' are set
  to a grid view, then the left and right arrow keys perform the
  corresponding lateral motions).  The commands are
  `mct-previous-completion-or-mini' and `mct-next-completion-or-mini'.
  Both accept an optional numeric argument.  If the Nth line lies
  outside the boundaries of the completions’ buffer, they move the point
  to the minibuffer.

  The display of the `*Completions*' can be toggled at any time from
  inside the minibuffer with `C-l' (mnemonic is “[l]ist completions” and
  the command is `mct-list-completions-toggle').

  By default, the `*Completions*' buffer appears in a window at the
  bottom of the frame.  Users can change its placement by configuring
  the variable `mct-display-buffer-action' (its doc string explains how
  and provides sample code).

  This is not the same for in-buffer completion performed by
  `mct-region-mode' ([Interaction model of mct-region-mode]).


[Interaction model of mct-region-mode] See section 4.4


4.2 Selecting candidates with mct-minibuffer-mode
─────────────────────────────────────────────────

  There are several ways to select a completion candidate.  These
  pertain to `mct-minibuffer-mode', as `mct-region-mode' only has the
  meaningful action of expanding the given candidate (with `RET' or
  `TAB' in the Completions’ buffer ([Cyclic behaviour for in-buffer
  completion])).

  1. Suppose that you are typing `mod' with the intent to select the
     `modus-themes.el' buffer.  To complete the candidate follow up
     `mod' with the `TAB' key (`minibuffer-complete').  If the match is
     unique, the text will be expanded.  Otherwise the `*Completions*'
     buffer will appear.  This does not exit the minibuffer, meaning
     that it does not confirm your choice.  To confirm your choice, use
     `RET'.  If you ever make a mistake and expand the wrong candidate,
     just use `undo'.  Lastly note that if the candidates meet the
     `completion-cycle-threshold' hitting `TAB' again will switch
     between them.
  2. While cycling through the completions’ buffer, type `RET' to select
     and confirm the current candidate (`mct-choose-completion-exit').
     This works for all types of completion prompts.
  3. Similar to the above, but without exiting the minibuffer (i.e. to
     confirm your choice) is `mct-choose-completion-no-exit' which is
     bound to `TAB' in the completions’ buffer.  This is particularly
     useful for certain contexts where selecting a candidate does not
     necessarily mean that the process has to be finalised (e.g. when
     using `find-file').  In those cases, the event triggered by `TAB'
     is followed by the renewal of the list of completions, where
     relevant (e.g. `TAB' over a directory in `find-file', which then
     shows the contents of that directory).

     The command can correctly expand completion candidates even when
     the active style in `completion-styles' is `partial-completion'.
     In other words, if the minibuffer contains input like `~/G/P/m' and
     the point is in the completions’ buffer over `Git/Projects/mct/'
     the minibuffer’ contents will become `~/Git/Projects/mct/' and then
     show the contents of that directory.
  4. Type `M-e' (`mct-edit-completion') in the completions’ buffer to
     place the current candidate in the minibuffer, without exiting the
     session.  This allows you to edit the text before confirming it.
     If point is in the minibuffer before performing this action, the
     current candidate is either the one at the top of the completions’
     buffer or that which is under the last known point in said buffer
     (the last known position is reset when the window is deleted).
     Internally, `mct-edit-completion' uses
     `mct-choose-completion-no-exit' to expand the completion candidate,
     so it retains its behaviour (as explained right above).

     Sometimes there is a need to switch to the minibuffer without
     selecting the candidate at point, such as to retype some part of
     the input.  In those cases, type `e' in the completions’ buffer to
     move to the minibuffer.  The command is called
     `mct-focus-minibuffer', which can also be assigned to the global
     keymap, though MCT leaves such a decision up to the user (same for
     `mct-focus-mini-or-completions').
  5. Select a candidate by its line number by typing `M-g M-g' in either
     the minibuffer or the `*Completions*' buffer.  This calls the
     command `mct-choose-completion-number' which internally enables
     line numbers and always makes the completions’ buffer visible.
     Selection in this way exits the minibuffer.

     NOTE: This method only works when `mct-completions-format' is set
     to its default value of `one-column'.  The other formats show
     completions in a grid view, which makes navigation based on line
     numbers imprecise.
  6. In prompts that allow the selection of multiple candidates
     (internally via the `completing-read-multiple' function) a `[CRM]'
     label is added to the text of the prompt.  The user thus knows that
     pressing `M-RET' (`mct-choose-completion-dwim') in the
     `*Completions*' will append the candidate at point to the list of
     selections and keep the completions available so that another item
     may be selected.  Any of the aforementioned applicable methods can
     confirm the final selection.  If, say, you want to pick a total of
     three candidates, do `M-RET' for the first two and `RET'
     (`mct-choose-completion-exit') for the last one.  In contexts that
     are not CRM-powered, the `M-RET' has the same effect as `TAB'
     (`mct-choose-completion-no-exit').
  7. When point is at the minibuffer, select the current candidate in
     the completions buffer with `C-RET' (`mct-complete-and-exit'),
     which has the same effect as first completing with `TAB' and then
     immediately exit the minibuffer with the completed candidate as the
     selected one.


[Cyclic behaviour for in-buffer completion] See section 4.4


4.3 Other commands for mct-minibuffer-mode
──────────────────────────────────────────

  ⁃ Emacs 28 has the ability to group candidates inside the completions’
    buffer under headings.  For example, the Consult package makes good
    use of those ([Extensions]).  MCT provides motions that jump between
    such headings, placing the point at the first candidate right below
    the heading’s text.  Use `M-n' (`mct-next-completion-group') and
    `M-p' (`mct-previous-completion-group') to move to the next or
    previous one, respectively.  Both commands accept an optional
    numeric argument.  For the sake of avoiding surprises, these
    commands do not cycle between the completions and the minibuffer:
    they stop at the first or last heading.
  ⁃ When using completion categories that involve file paths, such as
    `find-file', the backspace key (`DEL') goes up a directory if point
    is right after a path’s directory delimiter (a forward slash).
    Otherwise it deletes a single character backwards.  The command’s
    symbol is `mct-backward-updir'.


[Extensions] See section 10


4.4 Interaction model of mct-region-mode
────────────────────────────────────────

  When `mct-region-mode' is enabled, MCT is used for in-buffer
  completion.  In this scenario, the cyclic behaviour is less featureful
  than when the minibuffer is active (due to the specifics of the
  underlying commands), so we cover the differences ([Cyclic behaviour
  in the minibuffer]).

  In terms of its interaction model, `mct-region-mode' only gets enabled
  manually either by pressing `TAB' or `C-M-i' (`complete-symbol') in
  supporting major modes.  The `*Completions*' buffer pops up and is
  narrowed live to match any subsequent user input.  While the buffer is
  visible, we are performing `completion-in-region', which means that
  the Completions can be narrowed live by typing further.  Furthermore,
  `C-n' or `C-p' will move the point to the top/bottom of the
  Completions’ buffer from where the user can select a candidate with
  `RET'.

  In-buffer completion is always invoked manually.  There is no minimum
  input threshold and no delay between updates while live-updating of
  the `*Completions*' buffer is performed.  If the Completions are not
  visible, then no `completion-in-region' takes place and thus
  `mct-region-mode' should have no effect.

  By default, the placement of the Completions for this type of
  interaction is below the current buffer (as opposed to the bottom of
  the frame for `mct-minibuffer-mode').  It looks like this:

  ┌────
  │ ------------------------
  │ |               |      |
  │ | Current buffer| Buf  |
  │ |               |      |
  │ ------------------------
  │ |               |      |
  │ |  Completions  | Buf  |
  │ |               |      |
  │ ------------------------
  │ |        |      |      |
  │ |  Buf   | Buf  | Buf  |
  │ |        |      |      |
  │ ------------------------
  └────

  While inside the Completions’ buffer, `C-n' and `C-p' move to the next
  and previous line, respectively.  When they reach the top/bottom
  boundaries of the Completions’ buffer, they switch focus back to the
  buffer that started the completion.  However, and unlike
  `mct-minibuffer-mode', they do not keep the `*Completions*' window
  around.  This is because we cannot tell whether the user wanted to
  continue with a new completion upon returning to the buffer of origin
  or perform some other motion/command (in the minibuffer we can make
  that assumption because the minibuffer is purpose-specific, so for as
  long as it is active, the completion session goes on).  As such,
  `completion-in-region' must be restarted after cycling out of the
  `*Completions*'.

  To cancel in-buffer completion, type `C-g' either before switching to
  the Completions’ buffer or while inside of it.


[Cyclic behaviour in the minibuffer] See section 4.1


5 Installation
══════════════

5.1 Install the package
───────────────────────

  `mct' is available on the official GNU ELPA archive for users of Emacs
  version 27 or higher.  One can install the package without any further
  configuration.  The following commands shall suffice:

  ┌────
  │ M-x package-refresh-contents
  │ M-x package-install RET mct
  └────

  A package is also available via Guix:

  ┌────
  │ guix package -i emacs-mct
  └────


5.2 Manual installation method
──────────────────────────────

  Assuming your Emacs files are found in `~/.emacs.d/', execute the
  following commands in a shell prompt:

  ┌────
  │ cd ~/.emacs.d
  │ 
  │ # Create a directory for manually-installed packages
  │ mkdir manual-packages
  │ 
  │ # Go to the new directory
  │ cd manual-packages
  │ 
  │ # Clone this repo and name it "mct"
  │ git clone https://gitlab.com/protesilaos/mct.git mct
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/mct")
  └────

  Everything is in place to set up the package.


6 Sample setup
══════════════

  Minimal setup for the minibuffer and in-buffer completion:

  ┌────
  │ (require 'mct)
  │ (mct-minibuffer-mode 1)
  │ (mct-region-mode 1)
  └────

  And with more options:

  ┌────
  │ (require 'mct)
  │ 
  │ (setq mct-completion-window-size (cons #'mct--frame-height-fraction 1))
  │ (setq mct-remove-shadowed-file-names t) ; works when `file-name-shadow-mode' is enabled
  │ (setq mct-hide-completion-mode-line t)
  │ (setq mct-show-completion-line-numbers nil)
  │ (setq mct-apply-completion-stripes t)
  │ (setq mct-minimum-input 3)
  │ (setq mct-live-completion t)
  │ (setq mct-live-update-delay 0.6)
  │ (setq mct-persist-dynamic-completion t)
  │ (setq mct-completions-format 'one-column)
  │ 
  │ ;; This is for commands or completion categories that should always pop
  │ ;; up the completions' buffer.  It circumvents the default method of
  │ ;; waiting for some user input (see `mct-minimum-input') before
  │ ;; displaying and updating the completions' buffer.
  │ (setq mct-completion-passlist
  │       '(;; Some commands
  │ 	Info-goto-node
  │ 	Info-index
  │ 	Info-menu
  │ 	vc-retrieve-tag
  │ 	;; Some completion categories
  │ 	imenu
  │ 	file
  │ 	buffer
  │ 	kill-ring
  │ 	consult-location))
  │ 
  │ ;; The blocklist follows the same principle as the passlist, except it
  │ ;; disables live completions altogether.
  │ (setq mct-completion-blocklist nil)
  │ 
  │ ;; You can place the Completions' buffer wherever you want, by following
  │ ;; the syntax of `display-buffer'.  For example, try this:
  │ 
  │ ;; (setq mct-display-buffer-action
  │ ;;       (quote ((display-buffer-reuse-window
  │ ;;                display-buffer-in-side-window)
  │ ;;               (side . left)
  │ ;;               (slot . 99)
  │ ;;               (window-width . 0.3))))
  │ 
  │ (mct-minibuffer-mode 1)
  │ 
  │ ;; Optionally use MCT for in-buffer completion (though `corfu' is a
  │ ;; better option).
  │ (mct-region-mode 1)
  └────

  Other useful extras from the Emacs source code (read their doc
  strings):

  ┌────
  │ (setq completion-styles
  │       '(basic substring initials flex partial-completion))
  │ (setq completion-category-overrides
  │       '((file (styles . (basic partial-completion initials substring)))))
  │ 
  │ (setq completion-cycle-threshold 2)
  │ (setq completion-ignore-case t)
  │ (setq completion-show-inline-help nil)
  │ 
  │ (setq completions-detailed t)
  │ 
  │ (setq enable-recursive-minibuffers t)
  │ (setq minibuffer-eldef-shorten-default t)
  │ 
  │ (setq read-buffer-completion-ignore-case t)
  │ (setq read-file-name-completion-ignore-case t)
  │ 
  │ (setq resize-mini-windows t)
  │ (setq minibuffer-eldef-shorten-default t)
  │ 
  │ (file-name-shadow-mode 1)
  │ (minibuffer-depth-indicate-mode 1)
  │ (minibuffer-electric-default-mode 1)
  │ 
  │ ;; Do not allow the cursor in the minibuffer prompt
  │ (setq minibuffer-prompt-properties
  │       '(read-only t cursor-intangible t face minibuffer-prompt))
  │ 
  │ (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)
  │ 
  │ ;;; Minibuffer history
  │ (require 'savehist)
  │ (setq savehist-file (locate-user-emacs-file "savehist"))
  │ (setq history-length 10000)
  │ (setq history-delete-duplicates t)
  │ (setq savehist-save-minibuffer-history t)
  │ (add-hook 'after-init-hook #'savehist-mode)
  │ 
  │ ;;; Indentation and the TAB key
  │ (setq-default tab-always-indent 'complete) ; useful for `mct-region-mode'
  │ (setq-default tab-first-completion 'word-or-paren-or-punct) ; Emacs 27
  │ 
  │ ;;; Extensions
  │ 
  │ ;;;; Enable Consult previews in the Completions buffer.
  │ ;; Requires the `consult' package.
  │ (add-hook 'completion-list-mode-hook #'consult-preview-at-point-mode)
  │ 
  │ ;;;; Setup for Orderless
  │ ;; Requires the `orderless' package
  │ 
  │ ;; We make the SPC key insert a literal space and the same for the
  │ ;; question mark.  Spaces are used to delimit orderless groups, while
  │ ;; the quedtion mark is a valid regexp character.
  │ (let ((map minibuffer-local-completion-map))
  │   (define-key map (kbd "SPC") nil)
  │   (define-key map (kbd "?") nil))
  │ 
  │ ;; Because SPC works for Orderless and is trivial to activate, I like to
  │ ;; put `orderless' at the end of my `completion-styles'.  Like this:
  │ (setq completion-styles
  │       '(basic substring initials flex partial-completion orderless))
  │ (setq completion-category-overrides
  │       '((file (styles . (basic partial-completion orderless)))))
  └────


7 Known issues and workarounds
══════════════════════════════

  This section documents known issues and how to address them.


7.1 Avoid global-hl-line-mode in the Completions
────────────────────────────────────────────────

  MCT uses its own overlay to highlight the candidate at point.  To
  ensure that it does not interfere with the optional stripes (provided
  by the user option `mct-apply-completion-stripes') the highlight’s
  priority is set to a custom value.  This, in turn, means that when the
  user enables `global-hl-line-mode', its highlighted line takes
  precedence over the MCT highlight.  The solution to this conflict is
  to disable the hl-line locally for the `*Completions*' buffer like
  this:

  ┌────
  │ (add-hook 'completion-list-mode-hook (lambda () (setq-local global-hl-line-mode nil)))
  └────


8 Keymaps
═════════

  MCT defines its own keymaps, which extend those that are active in the
  minibuffer and the `*Completions*' buffer, respectively:

  ⁃ `mct-completion-list-mode-map'
  ⁃ `mct-minibuffer-local-completion-map'
  ⁃ `mct-minibuffer-local-filename-completion-map'
  ⁃ `mct-region-buffer-map'
  ⁃ `mct-region-completion-list-map'

  You can invoke `describe-keymap' to learn more about them.

  If you want to edit any key bindings, do it in these keymaps, not in
  those they extend and override (the names of the original ones are the
  same as above, minus the `mct-' prefix).


8.1 The use of remap for key bindings
─────────────────────────────────────

  MCT tries not to hardcode key bindings in order to respect user
  configurations.  To this end, Emacs provides the `remap' mechanism
  which effectively intercepts the key binding of the original command
  and applies it to the one specified.  Think of it like redirecting
  from the old to the new one.

  The code looks like this:

  ┌────
  │ (defvar mct-minibuffer-local-completion-map
  │   (let ((map (make-sparse-keymap)))
  │     (define-key map (kbd "C-j") #'exit-minibuffer)
  │     (define-key map [remap goto-line] #'mct-choose-completion-number)
  │     (define-key map [remap next-line] #'mct-switch-to-completions-top)
  │     (define-key map [remap next-line-or-history-element] #'mct-switch-to-completions-top)
  │     (define-key map [remap previous-line] #'mct-switch-to-completions-bottom)
  │     (define-key map [remap previous-line-or-history-element] #'mct-switch-to-completions-bottom)
  │     (define-key map (kbd "M-e") #'mct-edit-completion)
  │     (define-key map (kbd "C-<return>") #'mct-complete-and-exit)
  │     (define-key map (kbd "C-l") #'mct-list-completions-toggle)
  │     map)
  │   "Derivative of `minibuffer-local-completion-map'.")
  └────

  The `remap' might cause unwanted behaviour in cases where a user
  maintaints their own remappings which conflict with those of the
  package.  Consider, for example, this scenario:

  ┌────
  │ (require 'mct)
  │ 
  │ ;; Here goes the MCT setup
  │ 
  │ ;; More code...
  │ 
  │ ;; The user remaps `goto-line' to `my-goto-line-replacement' in the
  │ ;; `global-map'.
  │ (define-key global-map [remap goto-line] #'my-goto-line-replacement)
  └────

  If a user loads MCT first and later in their configuration defines a
  remap for `goto-line', then that will take precedence over what MCT
  wants to do.  The solution is for the user to update their code to
  specify an explicit key binding:

  ┌────
  │ (require 'mct)
  │ 
  │ ;; Here goes the MCT setup
  │ 
  │ ;; More code...
  │ 
  │ ;; The user specifies an explicit key binding for
  │ ;; `my-goto-line-replacement' in the `global-map'.
  │ (define-key global-map (kbd "M-g M-g") #'my-goto-line-replacement)
  └────


9 User-level tweaks or custom code
══════════════════════════════════

  In this section we cover custom code that builds on what MCT offers.


9.1 Sort completion candidates on Emacs 29
──────────────────────────────────────────

  Starting with Emacs 29 (current development target), the user option
  `completions-sort' controls the sorting method of candidates in the
  `*Completions*' buffer.  Beside the default of using `string-lessp',
  it accepts a custom function.  Consider any of the following examples:

  ┌────
  │ ;; Some sorting functions...
  │ (defun my-sort-by-alpha-length (elems)
  │   "Sort ELEMS first alphabetically, then by length."
  │   (sort elems (lambda (c1 c2)
  │ 		(or (string-version-lessp c1 c2)
  │ 		    (< (length c1) (length c2)))))))
  │ 
  │ (defun my-sort-by-history (elems)
  │   "Sort ELEMS by minibuffer history.
  │ Use `mct-sort-sort-by-alpha-length' if no history is available."
  │   (if-let ((hist (and (not (eq minibuffer-history-variable t))
  │ 		      (symbol-value minibuffer-history-variable))))
  │       (minibuffer--sort-by-position hist elems)
  │     (my-sort-by-alpha-length elems)))
  │ 
  │ (defun my-sort-multi-category (elems)
  │   "Sort ELEMS per completion category."
  │   (pcase (mct--completion-category)
  │     ('nil elems) ; no sorting
  │     ('kill-ring elems)
  │     ('project-file (my-sort-by-alpha-length elems))
  │     (_ (my-sort-by-history elems))))
  │ 
  │ ;; Specify the sorting function.
  │ (setq completions-sort #'my-sort-multi-category)
  └────

  [Known completion categories].


[Known completion categories] See section 3.5.3


9.2 MCT in the current or the other window
──────────────────────────────────────────

  Over at the [rde project], Andrew Tropin configures MCT to display the
  Completions’ buffer in either of two places:

  Current window
        This is the default behaviour.  It means that completions are
        presented where the user is already focused on, instead of the
        bottom of the display or some side window.

  Other window
        The least recently used window when the command that performs
        completion matches certain categories whose candidates are best
        shown next to the current window/context.  For example, Imenu
        (and extensions like `consult-imenu') creates a dynamically
        generated index of “points of interest” in the current buffer,
        so it is useful to have this displayed in the other window.

  Implementation details and particular preferences aside, this is a
  great example of using the various `display-buffer' functions to
  control the placement of the `*Completions*' buffer.

  ┌────
  │ (defvar rde-completion-categories-other-window
  │   '(imenu)
  │   "Completion categories that has to be in other window than
  │ current, otherwise preview functionallity will fail the party.")
  │ 
  │ (defvar rde-completion-categories-not-show-candidates-on-setup
  │   '(command variable function)
  │   "Completion categories that has to be in other window than
  │ current, otherwise preview functionallity will fail the party.")
  │ 
  │ (defun rde-display-mct-buffer-pop-up-if-apropriate (buffer alist)
  │   "Call `display-buffer-pop-up-window' if the completion category
  │ one of `rde-completion-categories-other-window', it will make
  │ sure that we don't use same window for completions, which should
  │ be in separate window."
  │   (if (memq (mct--completion-category)
  │ 	    rde-completion-categories-other-window)
  │       (display-buffer-pop-up-window buffer alist)
  │     nil))
  │ 
  │ (defun rde-display-mct-buffer-apropriate-window (buffer alist)
  │   "Displays completion buffer in the same window, where completion
  │ was initiated (most recent one), but in case, when compeltion
  │ buffer should be displayed in other window use least recent one."
  │   (let* ((window (if (memq (mct--completion-category)
  │ 			   rde-completion-categories-other-window)
  │ 		     (get-lru-window (selected-frame) nil nil)
  │ 		   (get-mru-window (selected-frame) nil nil))))
  │     (window--display-buffer buffer window 'reuse alist)))
  │ 
  │ (setq mct-display-buffer-action
  │       (quote ((display-buffer-reuse-window
  │ 	       rde-display-mct-buffer-pop-up-if-apropriate
  │ 	       rde-display-mct-buffer-apropriate-window))))
  │ 
  │ (defun rde-mct-show-completions ()
  │   "Instantly shows completion candidates for categories listed in
  │ `rde-completion-categories-show-candidates-on-setup'."
  │   (unless (memq (mct--completion-category)
  │ 		rde-completion-categories-not-show-candidates-on-setup)
  │     (setq-local mct-minimum-input 0)
  │     (mct--live-completions)))
  │ 
  │ (add-hook 'minibuffer-setup-hook 'rde-mct-show-completions)
  └────


[rde project] <https://git.sr.ht/~abcdw/rde>


10 Extensions
═════════════

  MCT only tweaks the default minibuffer.  To get more out of it,
  consider these exceptionally well-crafted extras:

  [Consult] by Daniel Mendler
        Adds several commands that make interacting with the minibuffer
        more powerful.  There also are multiple packages that build on
        it, such as [consult-dir] by Karthik Chikmagalur and
        [consult-notmuch] by José Antonio Ortega Ruiz.

  [Embark] by Omar Antolín Camarena
        Provides configurable contextual actions for completions and
        many other constructs inside buffers.  A genius package!

  [Marginalia] by Daniel and Omar
        Displays informative annotations for all known types of
        completion candidates.

  [Orderless] by Omar
        A completion style that matches a variety of patterns (regexp,
        flex, initialism, etc.) regardless of the order they appear in.

  [all-the-icons-completion] by Itai Y. Efrat
        Glue code that adds icons from the `all-the-icons' package to
        the `*Completions*' buffer.  It can make things prettier and/or
        more informative, while it can also be combined with Marginalia.

  MCT does support the use-case of `completion-in-region'.  This is the
  kind of completion session that does not involve the minibuffer and is
  instead about in-buffer text expansion.  However, you may prefer:

  [Corfu] by Daniel Mendler
        An interface for the `completion-in-region' which uses a child
        frame (basically a pop-up) at the position of the cursor to
        display candidates.  As with all of Daniel’s packages, Corfu
        aims for a clean implementation that does the right thing by
        being consistent with core Emacs mechanisms.

  [Cape] also by Daniel
        Additional `completion-at-point-functions' (CAPFs) that extend
        those of core Emacs.  These backends can be used by packages
        that visualise `completion-in-region' such as Corfu and MCT.


[Consult] <https://github.com/minad/consult/>

[consult-dir] <https://github.com/karthink/consult-dir>

[consult-notmuch] <https://codeberg.org/jao/consult-notmuch>

[Embark] <https://github.com/oantolin/embark/>

[Marginalia] <https://github.com/minad/marginalia>

[Orderless] <https://github.com/oantolin/orderless/>

[all-the-icons-completion]
<https://github.com/iyefrat/all-the-icons-completion>

[Corfu] <https://github.com/minad/corfu/>

[Cape] <https://github.com/minad/cape>

10.1 Enable Consult previews
────────────────────────────

  One of the nice features of the Consult package is the ability to
  preview the candidate at point.  All we need to enable it in the
  `*Completions*' buffer is the following snippet:

  ┌────
  │ (add-hook 'completion-list-mode-hook #'consult-preview-at-point-mode)
  └────


10.2 Avoid conflict between MCT and Corfu
─────────────────────────────────────────

  Daniel Mendler’s `corfu' package provides an alternative to the
  `mct-region-mode' ([MCT in the minibuffer and in regular buffers]).
  Given that MCT’s implementation is a global minor-mode, chances are
  that users of both will run into weird issues with conflicting
  functionality.  The following snippet from Corfu’s README can be added
  to user configuration files to avoid any potential trouble when using
  commands such as `eval-expression' (bound to `M-:' by default):

  ┌────
  │ (defun corfu-in-minibuffer ()
  │   "Enable Corfu in the minibuffer only if Mct/Vertico are not active."
  │   (unless (or (mct--minibuffer-p) vertico--input)
  │     (corfu-mode 1)))
  │ 
  │ (add-hook 'minibuffer-setup-hook #'corfu-in-minibuffer 1)
  └────


[MCT in the minibuffer and in regular buffers] See section 3.11


11 Alternatives
═══════════════

  In the grand scheme of things, it may be helpful to think of MCT as
  proof-of-concept on how the default Emacs completion can become more
  expressive.  MCT’s value rests in its potential to inspire developers
  to (i) patch Emacs so that its out-of-the-box completion is more
  interactive, and (ii) expose the shortcomings in the current
  implementation of the `*Completions*' buffer, which should again
  provide an impetus for further changes to Emacs.  Otherwise, MCT is
  meant for users who can tolerate the status quo and simply want a thin
  layer of interactivity for minibuffer completion, in-buffer
  completion, and their intersection with the Completions’ buffer.

  Like MCT, these alternatives provide a thin layer of functionality
  over the built-in infrastructure.  Unlike MCT, they are not
  constrained by the design of the `*Completions*' buffer and
  concomitant functionality.  They all make for a natural complement to
  the standard Emacs experience (also [Extensions]).

  [Vertico] by Daniel Mendler
        this is a more mature and feature-rich package with a large user
        base and a highly competent maintainer.

        Vertico has some performance optimizations on how candidates are
        sorted and presented, which means that it displays results right
        away without any noticeable performance penalty.  Whereas MCT
        does not change the underlying behaviour of how candidates are
        displayed.  As such, MCT will be slower in scenaria where there
        are lots of candidates because core Emacs lacks those
        optimizations.  One such case is with the `describe-symbol'
        (`C-h o') prompt.  If the user asks for the completions’ buffer
        without inputting any character (so without narrowing the list),
        there will be a noticeable delay before the buffer is rendered.
        This is mitigated in MCT by the requirement for
        `mct-minimum-input', though the underlying mechanics remain
        intact.

        In terms of the interaction model, the main difference between
        Vertico and MCT is that the former uses the minibuffer by
        default and shows the completions there.  The minibuffer is
        expanded to show the candidates in a vertical list.  Whereas MCT
        keeps the `*Completions*' buffer and the minibuffer as separate
        entities, the way standard Emacs does it.

        The presence of a fully fledged buffer means that the user can
        invoke all relevant commands at their disposal, such as to write
        the buffer to a file for future review, use Isearch to move
        around, copy a string or rectangle to a register, and so on.
        Also, the placement of such a buffer is configurable (as with
        all buffers—though refer, in particular, to
        `mct-display-buffer-action').

        Vertico has official extensions which can make it work exactly
        like MCT without any of MCT’s drawbacks.  These extensions can
        also expand Vertico’s powers such as by providing granular
        control over the exact style of presentation for any given
        completion category (e.g. display Imenu in a separate buffer,
        show the `switch-to-buffer' list horizontally in the minibuffer,
        and present `find-file' in a vertical list—whatever the user
        wants).

        All things considered, there is no compelling reason why one may
        prefer MCT over Vertico in terms of the available functionality:
        Vertico is better.

  [Elmo - Embark Live MOde for Emacs] by Karthik Chikmagalur
        this package is best described as a sibling of MCT both in terms
        of its functionality and overall interaction model.  In fact,
        the cyclic motions that are at the core of the MCT experience
        were first developed as part of my personal Emacs setup to cycle
        between the minibuffer and Embark’s “live completions” buffer.
        That was until Emacs28 got some refinements to the presentation
        of the `*Completions*' buffer which allowed for a vertical,
        single-column view.

        Elmo can, in principle, have identical functionality with MCT,
        given that the only substantive difference is that the former
        uses an Embark buffer to show live-updating completions, while
        the latter relies on the generic `*Completions*' buffer.

        For users who are on Emacs 27 and who need a single-column view,
        Elmo is a better choice because MCT can only display such a view
        on Emacs 28 or higher (though it has been meticulously tested
        with the grid views of Emacs 27 and should work perfectly fine
        with them).

  Icomplete and fido-mode (built-in, multiple authors)
        Icomplete is closer in spirit to Vertico, as it too uses the
        minibuffer to display completion candidates.  By default, it
        presents the list horizontally, though there exists
        `icomplete-vertical-mode' (and `fido-vertical-mode').

        For our purposes, Icomplete and Fido are the same in terms of
        the paradigm they follow.  The latter is a re-spin of the
        former, as it adjusts certain variables and binds some commands
        for the convenience of the end-user.  `fido-mode' and its
        accoutrements are defined in `icomplete.el'.

        What MCT borrows from Icomplete is the `mct-backward-updir'
        command, the tidying of the shadowed file paths, and ideas for
        the input delay (explained elsewhere in this document).
        Internally, I also learnt how to extend local keymaps by
        studying `icomplete.el'.

        I had used Icomplete for several months before moving to what
        now has become `mct.el'.  I think it is excellent at providing a
        thin layer over the built-in infrastructure.


[Extensions] See section 10

[Vertico] <https://github.com/minad/vertico>

[Elmo - Embark Live MOde for Emacs] <https://github.com/karthink/elmo>


12 Acknowledgements
═══════════════════

  MCT is meant to be a collective effort.  Every bit of help matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to code or documentation
        Daniel Mendler, James Norman Vladimir Cash, José Antonio Ortega
        Ruiz, Juri Linkov, Philip Kaludercic.

  Ideas and user feedback
        Andrew Tropin, Benjamin (@zealotrush), Case Duckworth, Jonathan
        Irving, José Antonio Ortega Ruiz, Kostadin Ninev, Manuel Uberti,
        Philip Kaludercic, Theodor Thornhill, Tomasz Hołubowicz, Z.Du.
        As well as users: danrobi11.

  Packaging
        Andrew Tropin and Nicolas Goaziou (Guix).

  Inspiration for certain features
        `icomplete.el' (built-in—multiple authors), Daniel Mendler
        (`vertico'), Omar Antolín Camarena (`embark',
        `live-completions'), Štěpán Němec (`stripes.el').


13 Official sources
═══════════════════

  Manual
        <https://protesilaos.com/emacs/mct>
  Change log
        <https://protesilaos.com/emacs/mct-changelog>
  Source code
        <https://gitlab.com/protesilaos/mct>


14 GNU Free Documentation License
═════════════════════════════════


15 Indices
══════════

15.1 Function index
───────────────────


15.2 Variable index
───────────────────


15.3 Concept index
──────────────────
