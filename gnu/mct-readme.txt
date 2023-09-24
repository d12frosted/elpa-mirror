               ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                MINIBUFFER CONFINES TRANSCENDED (MCT.EL)

                          Protesilaos Stavrou
                          info@protesilaos.com
               ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `mct' (or `mct.el' and variants), and provides every other
piece of information pertinent to it.

The documentation furnished herein corresponds to stable version 1.0.0,
released on 2023-09-24.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 1.1.0-dev.

⁃ Package name (GNU ELPA): `mct'
⁃ Official manual: <https://protesilaos.com/emacs/mct>
⁃ Change log: <https://protesilaos.com/emacs/mct-changelog>
⁃ Git repo on SourceHut: <https://git.sr.ht/~protesilaos/mct>
  • Mirrors:
    ⁃ GitHub: <https://github.com/protesilaos/mct>
    ⁃ GitLab: <https://gitlab.com/protesilaos/mct>
⁃ Mailing list: <https://lists.sr.ht/~protesilaos/general-issues>
⁃ Backronym: Minibuffer Confines Transcended; Minibuffer and Completions
  in Tandem.

If you are viewing the README.org version of this file, please note that
the GNU ELPA machinery automatically generates an Info manual out of it.

Table of Contents
─────────────────

1. COPYING
2. Overview of MCT
3. Customizations
.. 1. Live completion
.. 2. Minimum input threshold
.. 3. Delay between live updates
.. 4. Live updates per command or completion category
..... 1. Passlist for commands or completion categories
..... 2. Blocklist for commands or completion categories
..... 3. Known completion categories
..... 4. Find completion category
.. 5. Size boundaries of the Completions
.. 6. Dynamic completion tables in mct-mode
.. 7. Hide the Completions mode line
.. 8. Remove shadowed file paths
.. 9. MCT in the minibuffer and completion in regular buffers
4. Usage
.. 1. Cyclic behaviour for mct-mode
.. 2. Selecting candidates with mct-mode
5. Installation
.. 1. Install the package
.. 2. Manual installation method
6. Sample setup
7. Keymaps
8. User-level tweaks or custom code
.. 1. Sort completion candidates on Emacs 29
.. 2. Indicator for completing-read-multiple
.. 3. Ido-style navigation through directories
9. Third-party extensions
.. 1. Enable Consult previews
10. Alternatives
11. Acknowledgements
12. Official sources
13. GNU Free Documentation License
14. Indices
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
  and `*Completions*' buffer of Emacs 28 (or higher) so that they work
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


3.1 Live completion
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

[Minimum input threshold] See section 3.2

[Passlist for commands or completion categories] See section 3.4.1

[Blocklist for commands or completion categories] See section 3.4.2

[Size boundaries of the Completions] See section 3.5


3.2 Minimum input threshold
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


[Live updates per command or completion category] See section 3.4


3.3 Delay between live updates
──────────────────────────────

  Brief: Delay in seconds before updating the Completions’ buffer.

  Symbol: `mct-live-update-delay' (`number' type)

  The delay in seconds between live updates of the Completions’ buffer.
  The default value is `0.3'.

  This variable is ignored for commands or completion categories that
  are specified in the `mct-completion-passlist' and
  `mct-completion-blocklist'.

  [Live updates per command or completion category].


[Live updates per command or completion category] See section 3.4


3.4 Live updates per command or completion category
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


[Live completion] See section 3.4.2

[Minimum input threshold] See section 3.2

[Delay between live updates] See section 3.3

3.4.1 Passlist for commands or completion categories
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

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

  When the `mct-completion-blocklist' and the `mct-completion-passlist'
  are in conflict, the former takes precedence.

  [Known completion categories].


[Known completion categories] See section 3.4.3


3.4.2 Blocklist for commands or completion categories
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

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

  When the `mct-completion-blocklist' and the `mct-completion-passlist'
  are in conflict, the former takes precedence.

  Perhaps a less drastic measure is to set `mct-minimum-input' to an
  appropriate value.  Or better use `mct-completion-passlist'.

  [Known completion categories].


[Known completion categories] See section 3.4.3


3.4.3 Known completion categories
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

  [Find completion category].


[Find completion category] See section 3.4.4


3.4.4 Find completion category
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  While using a command that provides a minibuffer prompt, type `M-:'
  (the `eval-expression' command) and evaluate
  `(mct--completion-category)'.  It will return the completion category,
  if any.  Note that this only works when the variable
  `enable-recursive-minibuffers' is non-nil.

  To review echo area messages, use `C-h e' (`view-echo-area-messages').

  [Known completion categories].


[Known completion categories] See section 3.4.3


3.5 Size boundaries of the Completions
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


[Live completion] See section 3.1


3.6 Dynamic completion tables in mct-mode
─────────────────────────────────────────

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

  [Selecting candidates with mct-mode].

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


[Live completion] See section 3.1

[Selecting candidates with mct-mode] See section 4.2

[Blocklist for commands or completion categories] See section 3.4.2


3.7 Hide the Completions mode line
──────────────────────────────────

  Brief: Do not show a mode line in the Completions’ buffer.

  Symbol: `mct-hide-completion-mode-line' (`boolean' type)

  By default, the `*Completions*' buffer has its own mode line, just
  like every other window.  Set this user option to non-nil to remove
  the mode line.


3.8 Remove shadowed file paths
──────────────────────────────

  Brief: Delete shadowed parts of file names from the minibuffer.

  Symbol: `mct-remove-shadowed-file-names' (`boolean' type)

  When the built-in `file-name-shadow-mode' is enabled and this user
  option is non-nil, MCT will delete the part of the file path that is
  shadowed (meaning that it is overriden) by the given input.

  For example, if the user types `~/' after a long path name, everything
  preceding the `~/' is removed so the interactive selection process
  starts again from the user’s `$HOME'.


3.9 MCT in the minibuffer and completion in regular buffers
───────────────────────────────────────────────────────────

  Emacs draws a distinction between two types of completion sessions:

  ⁃ Completion where the minibuffer is involved (such as to switch
    buffers or find a file).

  ⁃ Completion in a regular buffer to expand the text before point.  The
    minibuffer is not active.  We call this “in-buffer completion” or
    allude to the underlying function: `completion-in-region'.

  The former scenario is what MCT has supported since its inception.
  Enable `mct-mode' to get started.  There was a time where MCT also
  supported in-buffer completion but this was discontinued in version
  `1.0.0' of the package as Emacs 29 gained the requisite capabilities.
  To get the familiar MCT key bindings for in-buffer completion, use
  these in your init file:

  ┌────
  │ ;; Get the key bindings
  │ (let ((map completion-in-region-mode-map))
  │   (define-key map (kbd "C-n") #'minibuffer-next-completion)
  │   (define-key map (kbd "C-p") #'minibuffer-previous-completion)
  │   (define-key map (kbd "RET") #'minibuffer-choose-completion))
  │ 
  │ ;; Tweak the appearance
  │ (setq completions-format 'one-column)
  │ (setq completion-show-help nil)
  │ (setq completion-auto-help t)
  │ 
  │ ;; Optionally, tweak the appearance further
  │ (setq completions-detailed t)
  │ (setq completion-show-inline-help nil)
  │ (setq completions-max-height 6)
  │ (setq completions-highlight-face 'completions-highlight)
  └────

  Note that the in-buffer completions will produce a new buffer window
  below the current one.  Some users find this intrusive.  In such a
  case, the use of a popup box is better.  Consider the `corfu' package
  by Daniel Mendler, which uses such a popup ([Alternatives]).


[Alternatives] See section 10


4 Usage
═══════

  This section outlines the various patterns of interaction that MCT
  establishes.


4.1 Cyclic behaviour for mct-mode
─────────────────────────────────

  When `mct-mode' is enabled, some new keymaps are activated which add
  commands for cycling between the minibuffer and the completions.
  Suppose the following standard layout:

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


4.2 Selecting candidates with mct-mode
──────────────────────────────────────

  There are several ways to select a completion candidate with
  `mct-mode'.

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
  5. In prompts that allow the selection of multiple candidates
     (internally via the `completing-read-multiple' function) using
     `M-RET' (`mct-choose-completion-dwim') in the `*Completions*' will
     append the candidate at point to the list of selections and keep
     the completions available so that another item may be selected.
     Any of the aforementioned applicable methods can confirm the final
     selection.  If, say, you want to pick a total of three candidates,
     do `M-RET' for the first two and `RET'
     (`mct-choose-completion-exit') for the last one.  In contexts that
     are not CRM-powered, the `M-RET' has the same effect as `TAB'
     (`mct-choose-completion-no-exit').

     [Indicator for completing-read-multiple].
  6. When point is at the minibuffer, select the current candidate in
     the completions buffer with `C-RET' (`mct-complete-and-exit'),
     which has the same effect as first completing with `TAB' and then
     immediately exit the minibuffer with the completed candidate as the
     selected one.
  7. Emacs 28 has the ability to group candidates inside the
     completions’ buffer under headings.  For example, the Consult
     package makes use of those ([Third-party extensions]).  MCT
     provides motions that jump between such headings, placing the point
     at the first candidate right below the heading’s text.  Use `M-n'
     (`mct-next-completion-group') and `M-p'
     (`mct-previous-completion-group') to move to the next or previous
     one, respectively (also work with they keys for `forward-paragraph'
     and `backward-paragraph').  Both commands accept an optional
     numeric argument.  For the sake of avoiding surprises, these
     commands do not cycle between the completions and the minibuffer:
     they stop at the first or last heading.


[Indicator for completing-read-multiple] See section 8.2

[Third-party extensions] See section 9


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
  │ git clone https://git.sr.ht/~protesilaos/mct mct
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
  │ (mct-mode 1)
  └────

  And with more options:

  ┌────
  │ (require 'mct)
  │ 
  │ (setq mct-completion-window-size (cons #'mct-frame-height-third 1))
  │ (setq mct-remove-shadowed-file-names t) ; works when `file-name-shadow-mode' is enabled
  │ (setq mct-hide-completion-mode-line t)
  │ (setq mct-minimum-input 3)
  │ (setq mct-live-completion t)
  │ (setq mct-live-update-delay 0.6)
  │ (setq mct-persist-dynamic-completion t)
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
  │ (mct-mode 1)
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
  │ (setq history-length 500)
  │ (setq history-delete-duplicates t)
  │ (setq savehist-save-minibuffer-history t)
  │ (add-hook 'after-init-hook #'savehist-mode)
  │ 
  │ ;;; Third-party extensions
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


7 Keymaps
═════════

  MCT defines its own keymaps, which extend those that are active in the
  minibuffer and the `*Completions*' buffer, respectively:

  ⁃ `mct-completion-list-mode-map'
  ⁃ `mct-minibuffer-local-completion-map'

  You can invoke `describe-keymap' to learn more about them.

  If you want to edit any key bindings, do it in these keymaps, not in
  those they extend and override (the names of the original ones are the
  same as above, minus the `mct-' prefix).


8 User-level tweaks or custom code
══════════════════════════════════

  In this section we cover custom code that builds on what MCT offers.


8.1 Sort completion candidates on Emacs 29
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
  │ 		    (< (length c1) (length c2))))))
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


[Known completion categories] See section 3.4.3


8.2 Indicator for completing-read-multiple
──────────────────────────────────────────

  Previous versions of MCT would prepend a `[CRM]' tag to the minibuffer
  prompt of commands powered by `completing-read-multiple'.  While this
  is a nice usability enhancement, it is not specific to MCT and thus
  should not be part of `mct.el'.  Use this in your init file instead:

  ┌────
  │ ;; Add prompt indicator to `completing-read-multiple'.  We display
  │ ;; [`completing-read-multiple': <separator>], e.g.,
  │ ;; [`completing-read-multiple': ,] if the separator is a comma.  This
  │ ;; is adapted from the README of the `vertico' package by Daniel
  │ ;; Mendler.  I made some small tweaks to propertize the segments of
  │ ;; the prompt.
  │ (defun crm-indicator (args)
  │   (cons (format "[`crm-separator': %s]  %s"
  │ 		(propertize
  │ 		 (replace-regexp-in-string
  │ 		  "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
  │ 		  crm-separator)
  │ 		 'face 'error)
  │ 		(car args))
  │ 	(cdr args)))
  │ 
  │ (advice-add #'completing-read-multiple :filter-args #'crm-indicator)
  └────


8.3 Ido-style navigation through directories
────────────────────────────────────────────

  Older versions of MCT had a command for file navigation that would
  delete the whole directory component before point, effectively going
  back up one directory.  While the functionality can be useful, it is
  not integral to the MCT experience and thus should not belong in
  `mct.el'.  Add this to your own configuration file instead:

  ┌────
  │ ;; Adaptation of `icomplete-fido-backward-updir'.
  │ (defun my-backward-updir ()
  │   "Delete char before point or go up a directory."
  │   (interactive nil mct-mode)
  │   (cond
  │    ((and (eq (char-before) ?/)
  │ 	 (eq (mct--completion-category) 'file))
  │     (when (string-equal (minibuffer-contents) "~/")
  │       (delete-minibuffer-contents)
  │       (insert (expand-file-name "~/"))
  │       (goto-char (line-end-position)))
  │     (save-excursion
  │       (goto-char (1- (point)))
  │       (when (search-backward "/" (minibuffer-prompt-end) t)
  │ 	(delete-region (1+ (point)) (point-max)))))
  │    (t (call-interactively 'backward-delete-char))))
  │ 
  │ (define-key minibuffer-local-filename-completion-map (kbd "DEL") #'my-backward-updir)
  └────


9 Third-party extensions
════════════════════════

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

  MCT does not support the use-case of `completion-in-region'.  This is
  the kind of completion session that is done inside the buffer and does
  not involve the minibuffer.  However, you may prefer:

  [Corfu] by Daniel Mendler
        An interface for the `completion-in-region' which uses a child
        frame (basically a pop-up) at the position of the cursor to
        display candidates.  As with all of Daniel’s packages, Corfu
        aims for a clean implementation that does the right thing by
        being consistent with core Emacs mechanisms.

  [Cape] also by Daniel
        Additional `completion-at-point-functions' (CAPFs) that extend
        those of core Emacs.  These backends can be used by packages
        that visualise `completion-in-region'.


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

9.1 Enable Consult previews
───────────────────────────

  One of the nice features of the Consult package is the ability to
  preview the candidate at point.  All we need to enable it in the
  `*Completions*' buffer is the following snippet:

  ┌────
  │ (add-hook 'completion-list-mode-hook #'consult-preview-at-point-mode)
  └────


10 Alternatives
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

        What MCT borrows from Icomplete is for the input delay
        (explained elsewhere in this document).  Internally, I also
        learnt how to extend local keymaps by studying `icomplete.el'.

        I had used Icomplete for several months before moving to what
        now has become `mct.el'.  I think it is excellent at providing a
        thin layer over the built-in infrastructure.


[Extensions] See section 9

[Vertico] <https://github.com/minad/vertico>


11 Acknowledgements
═══════════════════

  MCT is meant to be a collective effort.  Every bit of help matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to code or documentation
        Daniel Mendler, James Norman Vladimir Cash, José Antonio Ortega
        Ruiz, Juri Linkov, Philip Kaludercic, Tomasz Hołubowicz.

  Ideas and user feedback
        Andrew Tropin, Benjamin (@zealotrush), Case Duckworth, Chris
        Burroughs, Jonathan Irving, José Antonio Ortega Ruiz, Kostadin
        Ninev, Manuel Uberti, Morgan Willcock, Philip Kaludercic,
        Theodor Thornhill, Tomasz Hołubowicz, Z.Du.  As well as users:
        danrobi11.

  Packaging
        Andrew Tropin and Nicolas Goaziou (Guix).

  Inspiration for certain features
        `icomplete.el' (built-in—multiple authors), Daniel Mendler
        (`vertico'), Omar Antolín Camarena (`embark',
        `live-completions').


12 Official sources
═══════════════════

  Manual
        <https://protesilaos.com/emacs/mct>
  Change log
        <https://protesilaos.com/emacs/mct-changelog>
  Source code
        <https://git.sr.ht/~protesilaos/mct>
  Mailing list
        <https://lists.sr.ht/~protesilaos/mct>


13 GNU Free Documentation License
═════════════════════════════════


14 Indices
══════════

14.1 Function index
───────────────────


14.2 Variable index
───────────────────


14.3 Concept index
──────────────────
