	    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	     MINIBUFFER AND COMPLETIONS IN TANDEM (MCT.EL)

			  Protesilaos Stavrou
			  info@protesilaos.com
	    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `mct' (or `mct.el' and variants), and provides every other
piece of information pertinent to it.

The documentation furnished herein corresponds to stable version 0.4.0,
released on 2022-01-19.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 0.5.0-dev.

Table of Contents
─────────────────

1. COPYING
2. Overview of MCT
.. 1. MCT in the minibuffer and in regular buffers
3. Usage
.. 1. Cyclic behaviour for mct-minibuffer-mode
.. 2. Selecting candidates with mct-minibuffer-mode
.. 3. Other commands for mct-minibuffer-mode
.. 4. Interaction model of mct-region-mode
4. Installation
.. 1. Install the package
.. 2. Manual installation method
5. Sample setup
6. Keymaps
7. User-level tweaks or custom code
.. 1. MCT in the current or the other window
8. Extensions
.. 1. Enable Consult previews
9. Alternatives
10. Acknowledgements
11. Official sources
12. GNU Free Documentation License
13. Indices
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

  Customization options control the input threshold
  (`mct-minimum-input') and the delay between live updates
  (`mct-live-update-delay').  Similarly, a blocklist and a passlist for
  commands are on offer:

  ⁃ The blocklist (`mct-completion-blocklist') disables the
    live-updating functionality for the functions specified therein.
  ⁃ The passlist (`mct-completion-passlist') always shows the
    Completions’ buffer for the designated function without accounting
    for the minimum input threshold.

  The user option `mct-live-completion' controls the overall behaviour
  of the Completions’ buffer:

  ⁃ When nil, the user has to manually request completions, using the
    regular activating commands.  The Completions’ buffer is never
    updated live to match user input.  Updating has to be handled
    manually.  This is like the out-of-the-box minibuffer completion
    experience.

  ⁃ When set to the value `visible', the Completions’ buffer is live
    updated only if it is visible.  The actual display of the
    completions is still handled manually.  For this reason, the
    `visible' style does not read the `mct-minimum-input', meaning that
    it will always try to live update the visible completions,
    regardless of input length.

  ⁃ When non-nil (the default), the Completions’ buffer is automatically
    displayed once the `mct-minimum-input' is met and is hidden if the
    input drops below that threshold.  While visible, the buffer is
    updated live to match the user’s input.

  ⁃ Note that every function in the `mct-completion-passlist' ignores
    this option altogether.  This means that every such command will
    always show the Completions’ buffer automatically and will always
    update its contents live.  Same principle for every function
    declared in the `mct-completion-blocklist', which will always
    disable both the automatic display and live updating of the
    Completions’ buffer.

  Other customizations:

  ⁃ `mct-hide-completion-mode-line' to hide the mode line of the
    `*Completions*' buffer.  This removes the separation between it and
    the minibuffer, further contributing to the idea of a unified space
    between the two.
  ⁃ `mct-remove-shadowed-file-name' to clear shadowed file names when
    `file-name-shadow-mode' is enabled.  This means that in prompts that
    use file paths (such as `find-file') when you start in, say,
    `~/Git/mct.el' and type `~/' the previous file path is removed and
    only the new one is inserted.  Whereas the default is to keep the
    original file name visible yet “shadowed” by a different color.
  ⁃ `mct-show-completion-line-numbers' to always display line numbers in
    the Completions’ buffer.  This can be helpful to get a sense of the
    length of the completion candidates’ list.  Though note that line
    numbers are displayed ephemerally while using the
    `mct-choose-completion-number' command, which is bound to `M-g M-g'
    in either the minibuffer or the `*Completions*' buffer.
  ⁃ `mct-apply-completion-stripes' applies alternating background colors
    in the Completions’ buffer.  This is only tested with the
    `modus-themes' and will only work nicely if the main background is
    pure black or white—other themes would need to add support for the
    faces we define or, at least, users must modify the `mct-stripe'
    face.


[Basic usage] See section 3

2.1 MCT in the minibuffer and in regular buffers
────────────────────────────────────────────────

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


[Extensions] See section 8

[Alternatives] See section 9

[Interaction model of mct-region-mode] See section 3.4


3 Usage
═══════

  This section outlines the various patterns of interaction that MCT
  establishes.  Note that completion covers two distinct cases, which
  are reflected in the design of MCT: (i) in the minibuffer and (ii) for
  in-buffer completion ([MCT in the minibuffer and in regular buffers]).
  Most of this section is about the former scenario, which uses the
  `mct-minibuffer-mode'.  The `mct-region-mode' is less featureful by
  comparison.


[MCT in the minibuffer and in regular buffers] See section 2.1

3.1 Cyclic behaviour for mct-minibuffer-mode
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


[Interaction model of mct-region-mode] See section 3.4


3.2 Selecting candidates with mct-minibuffer-mode
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


[Cyclic behaviour for in-buffer completion] See section 3.4


3.3 Other commands for mct-minibuffer-mode
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


[Extensions] See section 8


3.4 Interaction model of mct-region-mode
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

  The only customization option for `mct-region-mode' pertains to the
  presentation of the `*Completions*': `mct-region-completions-format'.
  By default, it uses the same style as `mct-completions-format', though
  it can be configured to, for example, display candidates in a grid
  with either of the `horizontal' or `vertical' values (on Emacs 27,
  candidates are always displayed in a grid, as the `one-column' layout
  was introduced in Emacs 28).


[Cyclic behaviour in the minibuffer] See section 3.1


4 Installation
══════════════

4.1 Install the package
───────────────────────

  `mct' is available on the official GNU ELPA archive for users of Emacs
  version 27 or higher.  One can install the package without any further
  configuration.  The following commands shall suffice:

  ┌────
  │ M-x package-refresh-contents
  │ M-x package-install RET mct
  └────


4.2 Manual installation method
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


5 Sample setup
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
  │ (setq mct-remove-shadowed-file-names t) ; works when `file-name-shadow-mode' is enabled
  │ (setq mct-hide-completion-mode-line t)
  │ (setq mct-show-completion-line-numbers nil)
  │ (setq mct-apply-completion-stripes t)
  │ (setq mct-minimum-input 3)
  │ (setq mct-live-update-delay 0.6)
  │ (setq mct-completions-format 'one-column)
  │ 
  │ ;; NOTE: `mct-completion-blocklist' can be used for commands with lots
  │ ;; of candidates, depending also on how low `mct-minimum-input' is.
  │ ;; With the settings shown here this is not required, otherwise I would
  │ ;; use something like this:
  │ ;;
  │ ;; (setq mct-completion-blocklist
  │ ;;       '( describe-symbol describe-function describe-variable
  │ ;;          execute-extended-command insert-char))
  │ (setq mct-completion-blocklist nil)
  │ 
  │ ;; This is for commands that should always pop up the completions'
  │ ;; buffer.  It circumvents the default method of waiting for some user
  │ ;; input (see `mct-minimum-input') before displaying and updating the
  │ ;; completions' buffer.
  │ (setq mct-completion-passlist
  │       '(imenu
  │ 	Info-goto-node
  │ 	Info-index
  │ 	Info-menu
  │ 	vc-retrieve-tag))
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


6 Keymaps
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


7 User-level tweaks or custom code
══════════════════════════════════

  In this section we cover custom code that builds on what MCT offers.


7.1 MCT in the current or the other window
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


8 Extensions
════════════

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

8.1 Enable Consult previews
───────────────────────────

  One of the nice features of the Consult package is the ability to
  preview the candidate at point.  All we need to enable it in the
  `*Completions*' buffer is the following snippet:

  ┌────
  │ (add-hook 'completion-list-mode-hook #'consult-preview-at-point-mode)
  └────


9 Alternatives
══════════════

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


[Extensions] See section 8

[Vertico] <https://github.com/minad/vertico>

[Elmo - Embark Live MOde for Emacs] <https://github.com/karthink/elmo>


10 Acknowledgements
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
        Philip Kaludercic, Theodor Thornhill.

  Inspiration for certain features
        `icomplete.el' (built-in—multiple authors), Daniel Mendler
        (`vertico'), Omar Antolín Camarena (`embark',
        `live-completions'), Štěpán Němec (`stripes.el').


11 Official sources
═══════════════════

  Manual
        <https://protesilaos.com/emacs/mct>
  Change log
        <https://protesilaos.com/emacs/mct-changelog>
  Source code
        <https://gitlab.com/protesilaos/mct>


12 GNU Free Documentation License
═════════════════════════════════


13 Indices
══════════

13.1 Function index
───────────────────


13.2 Variable index
───────────────────


13.3 Concept index
──────────────────
