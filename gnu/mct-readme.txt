	    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	     MINIBUFFER AND COMPLETIONS IN TANDEM (MCT.EL)

			  Protesilaos Stavrou
			  info@protesilaos.com
	    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `mct.el', and provides every other piece of information
pertinent to it.

The documentation furnished herein corresponds to stable version 0.1.0,
released on 2021-10-22.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 0.2.0-dev.

Table of Contents
─────────────────

1. COPYING
2. Overview of mct.el
3. Basic usage
.. 1. Cyclic behaviour
.. 2. Selecting candidates
4. Installation
5. Sample setup
6. Keymaps
7. Extensions
8. Alternatives
9. GNU Free Documentation License
10. Indices
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


2 Overview of mct.el
════════════════════

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

  Customisation options control the input threshold
  (`mct-minimum-input') and the delay between live updates
  (`mct-live-update-delay').  Similarly, a blocklist and a passlist for
  commands are on offer:

  ⁃ The blocklist (`mct-completion-blocklist') disables the
    live-updating functionality for the commands specified therein.

  ⁃ The passlist (`mct-completion-passlist') always shows the
    Completions’ buffer for the designated command without accounting
    for the minimum input threshold.

  Other customisations:

  ⁃ `mct-hide-completion-mode-line' to hide the mode line of the
    `*Completions*' buffer.  This removes the separation between it and
    the minibuffer, further contributing to the idea of a unified space
    between the two.

  ⁃ `mct-remove-shadowed-file-name' to clear shadowed file names when
    `file-name-shadow-mode' is enabled.  This means that in prompts that
    use file paths (such as `find-file') when you start in, say,
    `~/Git/mct.el' and type `~/' the previous file path is removed and
    only the new one is inserted.  Whereas the default is to keep the
    original file name visible yet “shadowed” by a different colour.

  ⁃ `mct-show-completion-line-numbers' to always display line numbers in
    the Completions’ buffer.  This can be helpful to get a sense of the
    length of the completion candidates’ list.  Though note that line
    numbers are displayed ephemerally while using the
    `mct-choose-completion-number' command, which is bound to `M-g M-g'
    in either the minibuffer or the `*Completions*' buffer.

  ⁃ `mct-apply-completion-stripes' applies alternative background
    colours in the Completions’ buffer.  This is only tested with the
    `modus-themes' and will only work nicely if the main background is
    pure black or white—other themes would need to add support for the
    faces we define or, at least, users must modify the `mct-stripe'
    face.


[Basic usage] See section 3


3 Basic usage
═════════════

3.1 Cyclic behaviour
────────────────────

  When `mct-mode' is enabled, some new keymaps are activated which add
  commands for cycling between the minibuffer and the completions.
  Suppose the following standard layout:

  ┌────
  │ -----------------
  │ |               |
  │ |               |
  │ |               |
  │ |  Buffer       |
  │ |               |
  │ |               |
  │ |               |
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
  bindings perform a regular line motion.  The commands are
  `mct-previous-completion-or-mini' and `mct-next-completion-or-mini'.

  The display of the `*Completions*' can be toggled at any time from
  inside the minibuffer with `C-l' (mnemonic is “[l]ist completions” and
  the command is `mct-list-completions-toggle').


3.2 Selecting candidates
────────────────────────

  There are several ways to select a completion candidate.

  1. Suppose that you are typing `mod' with the intent to select the
     `modus-themes.el' buffer.  To complete the first candidate follow
     up `mod' with the `TAB' key.  This is how you would do it with the
     default minibuffer.  If done fast enough, no completions will be
     shown (depending on your minimum input threshold and the
     live-update delay).

  2. Upon cycling through the completions, type `RET' to select the
     candidate at point and exit the minibuffer.  This works for all
     types of completion prompts.

  3. For certain contexts where selecting a candidate does not
     necessarily mean that the process has to be finalised (e.g. when
     using `find-file') selection in the `*Completions*' buffer can be
     done with `TAB' which completes the item at point but does not exit
     the minibuffer.  The command is instead renewed to update the list
     of completions with the new candidates.

  4. Select a candidate by its line number by typing `M-g M-g' in either
     the minibuffer or the `*Completions*' buffer.  This calls the
     command `mct-choose-completion-number' which internally enables
     line numbers and always makes the completions’ buffer visible.

  5. In prompts that allow the selection of multiple candidates
     (internally via the `completing-read-multiple' function) a `[CRM]'
     label is added to the text of the prompt.  The user thus knows that
     pressing `M-RET' in the `*Completions*' will append the candidate
     at point to the list of selections and keep the completions
     available so that another item may be selected.  Any of the
     aforementioned applicable methods can confirm the final selection.
     If, say, you want to pick a total of three candidates, do `M-RET'
     for the first two and `RET' for the last one.  In contexts that are
     not CRM-powered, the `M-RET' has the same effect as `RET'.

     NOTE 2021-10-22: this assumes the `crm-separator' to be constant
     (the comma `,' character) but some commands `let' bind it to
     something else, so the behaviour does not work as expected.  One
     such case is `org-set-tags-command' which uses `:' as a separator.

  6. Type `M-e' (`mct-edit-completion') in the completions’ buffer to
     place the current candidate in the minibuffer, without exiting the
     session.  This allows you to edit the text before confirming it.


4 Installation
══════════════

  MCT is not in any package archive for the time being, though I plan to
  submit it to GNU ELPA (as such, any non-trivial patches require
  copyright assignment to the Free Software Foundation).  Users can rely
  on `straight.el', `quelpa', or equivalent to fetch the source.  Below
  are the essentials for those who prefer the manual method.

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
  │ git clone https://gitlab.com/protesilaos/mct.el.git mct
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/")
  └────

  Everything is in place to set up the package.


5 Sample setup
══════════════

  Minimal setup:

  ┌────
  │ (require 'mct)
  │ (mct-mode 1)
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
  │ (mct-mode 1)
  └────

  Other useful extras from the Emacs source code:

  ┌────
  │ (setq enable-recursive-minibuffers t)
  │ (setq minibuffer-eldef-shorten-default t)
  │ 
  │ (file-name-shadow-mode 1)
  │ (minibuffer-depth-indicate-mode 1)
  │ (minibuffer-electric-default-mode 1)
  └────


6 Keymaps
═════════

  MCT defines its own keymaps, which extend those that are active in the
  minibuffer and the `*Completions*' buffer, respectively:

  ⁃ `mct-completion-list-mode-map'
  ⁃ `mct-minibuffer-local-completion-map'
  ⁃ `mct-minibuffer-local-filename-completion-map'

  You can invoke `describe-keymap' to learn more about them.

  If you want to edit any key bindings, do it in those keymaps, not in
  those they extend and override (the names of the original ones are the
  same as above, minus the `mct-' prefix).


7 Extensions
════════════

  MCT only tweaks the default minibuffer.  To get more out of it,
  consider these exceptionally well-crafted extras:

  `consult'
        Adds several commands that make interacting with the minibuffer
        more powerful.  There also are several packages that build on
        it, such as `consult-dir'.
  `embark'
        Provides configurable contextual actions for completions and
        many other constructs inside buffers.
  `marginalia'
        Displays informative annotations for all known types of
        completion candidates.
  `orderless'
        A completion style that matches a variety of patterns (regexp,
        flex, initialism, etc.) regardless of the order they appear in.


8 Alternatives
══════════════

  The only alternative I have used that is conceptually close to MCT is
  `vertico'.  Vertico is a more mature and feature-rich package, while
  its maintainer, Daniel Mendler, is an accomplished programmer.
  Whereas MCT is mostly an excuse to practice my Elisp skills.


9 GNU Free Documentation License
════════════════════════════════


10 Indices
══════════

10.1 Function index
───────────────────


10.2 Variable index
───────────────────


10.3 Concept index
──────────────────
