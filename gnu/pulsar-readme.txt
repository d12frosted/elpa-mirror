	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	      PULSAR.EL: PULSE HIGHLIGHT LINE ON DEMAND OR
		     AFTER RUNNING SELECT FUNCTIONS

			  Protesilaos Stavrou
			  info@protesilaos.com
	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `pulsar' (or `pulsar.el'), and provides every other piece of
information pertinent to it.

The documentation furnished herein corresponds to stable version 0.2.0,
released on 2022-03-16.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 0.3.0-dev.

Table of Contents
─────────────────

1. COPYING
2. Overview
3. Installation
4. Sample configuration
5. Integration with other packages
6. Acknowledgements
7. GNU Free Documentation License
8. Indices
.. 1. Function index
.. 2. Variable index
.. 3. Concept index


1 COPYING
═════════

  Copyright (C) 2022 Free Software Foundation, Inc.

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


2 Overview
══════════

  This is a small package that temporarily highlights the current line
  after a given function is invoked.  The affected functions are defined
  in the user option `pulsar-pulse-functions'.  What Pulsar does is set
  up an advice so that those functions run a hook after they are called.
  The pulse effect is added there (`pulsar-after-function-hook').

  To remove the advice and disable Pulsar altogether, evaluate this
  form: `(pulsar-setup 'reverse)'.  The `pulsar-setup' function can be
  used manually to install the advice on the relevant functions, though
  it is strongly encouraged to use `customize-set-variable' for the user
  option `pulsar-pulse-functions' and let Emacs set up everything
  correctly (that user option has a special custom setter function).

  The duration of the highlight is determined by `pulsar-delay'.  How
  smooth the effect is depends on `pulsar-iterations'.  While the
  applicable face is specified in `pulsar-face'.

  To disable the pulse but keep the highlight, set `pulsar-pulse' to
  nil.  The current line will remain highlighted until another command
  is invoked.

  To highlight the current line on demand, use the `pulsar-pulse-line'
  command.  When `pulsar-pulse' is non-nil (the default), its highlight
  will pulse before fading away.  Whereas the `pulsar-highlight-line'
  command never pulses the line: the highlight stays in place as if
  `pulsar-pulse' is nil.

  Pulsar depends on the built-in `pulse.el' library.

  Why the name “pulsar”?  It sounds like “pulse” and is a recognisable
  word.  Though if you need a backronym, consider “Pulsar Unquestionably
  Luminates, Strictly Absent the Radiation”.


3 Installation
══════════════

  Pulsar is not in any package archive for the time being, though I plan
  to submit it to GNU ELPA (as such, any non-trivial patches require
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
  │ # Clone this repo, naming it "pulsar"
  │ git clone https://gitlab.com/protesilaos/pulsar.git pulsar
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/pulsar")
  └────

  Everything is in place to set up the package.


4 Sample configuration
══════════════════════

  Remember to read the doc string of each of these variables.

  ┌────
  │ (require 'pulsar)
  │ 
  │ (pulsar-setup)
  │ 
  │ (customize-set-variable
  │  'pulsar-pulse-functions ; Read the doc string for why not `setq'
  │  '(recenter-top-bottom
  │    move-to-window-line-top-bottom
  │    reposition-window
  │    bookmark-jump
  │    other-window
  │    delete-window
  │    delete-other-windows
  │    forward-page
  │    backward-page
  │    scroll-up-command
  │    scroll-down-command
  │    windmove-right
  │    windmove-left
  │    windmove-up
  │    windmove-down
  │    windmove-swap-states-right
  │    windmove-swap-states-left
  │    windmove-swap-states-up
  │    windmove-swap-states-down
  │    tab-new
  │    tab-close
  │    tab-next
  │    org-next-visible-heading
  │    org-previous-visible-heading
  │    org-forward-heading-same-level
  │    org-backward-heading-same-level
  │    outline-backward-same-level
  │    outline-forward-same-level
  │    outline-next-visible-heading
  │    outline-previous-visible-heading
  │    outline-up-heading))
  │ 
  │ (setq pulsar-pulse t)
  │ (setq pulsar-delay 0.055)
  │ (setq pulsar-iterations 10)
  │ (setq pulsar-face 'pulsar-magenta)
  │ 
  │ ;; pulsar does not define any key bindings.  This is just a sample that
  │ ;; respects the key binding conventions.  Evaluate:
  │ ;;
  │ ;;     (info "(elisp) Key Binding Conventions")
  │ ;;
  │ ;; The author uses C-x l for `pulsar-pulse-line' and C-x L for
  │ ;; `pulsar-highlight-line'.
  │ (let ((map global-map))
  │   (define-key map (kbd "C-c h p") #'pulsar-pulse-line)
  │   (define-key map (kbd "C-c h h") #'pulsar-highlight-line))
  └────


5 Integration with other packages
═════════════════════════════════

  Beside `pulsar-pulse-line', Pulsar defines a few functions that can be
  added to hooks that are provided by other packages.

  There are two functions to recenter and then pulse the current line:
  `pulsar-recenter-top' and `pulsar-recenter-middle'.

  There also exists `pulsar-reveal-entry' which displays the hidden
  contents of an Org or Outline heading.  It can be used in tandem with
  the aforementioned recentering functions.

  Example use-cases:

  ┌────
  │ ;; integration with the `consult' package:
  │ (add-hook 'consult-after-jump-hook #'pulsar-recenter-top)
  │ (add-hook 'consult-after-jump-hook #'pulsar-reveal-entry)
  │ 
  │ ;; integration with the built-in `imenu':
  │ (add-hook 'imenu-after-jump-hook #'pulsar-recenter-top)
  │ (add-hook 'imenu-after-jump-hook #'pulsar-reveal-entry)
  └────


6 Acknowledgements
══════════════════

  Pulsar is meant to be a collective effort.  Every bit of help matters.

  Author/maintainer
        Protesilaos Stavrou.

  Ideas and user feedback
        Mark Barton, Petter Storvik, and user kb.


7 GNU Free Documentation License
════════════════════════════════


8 Indices
═════════

8.1 Function index
──────────────────


8.2 Variable index
──────────────────


8.3 Concept index
─────────────────
