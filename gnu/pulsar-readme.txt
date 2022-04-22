	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	      PULSAR.EL: PULSE HIGHLIGHT LINE ON DEMAND OR
		     AFTER RUNNING SELECT FUNCTIONS

			  Protesilaos Stavrou
			  info@protesilaos.com
	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `pulsar' (or `pulsar.el'), and provides every other piece of
information pertinent to it.

The documentation furnished herein corresponds to stable version 0.3.0,
released on 2022-04-08.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 0.4.0-dev.

⁃ Homepage: <https://protesilaos.com/emacs/pulsar>.
⁃ Git repository: <https://git.sr.ht/~protesilaos/pulsar>.
⁃ Mailing list: <https://lists.sr.ht/~protesilaos/pulsar>.

Table of Contents
─────────────────

1. COPYING
2. Overview
3. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
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
  in the user option `pulsar-pulse-functions' and the effect takes place
  when either `pulsar-mode' (buffer-local) or `pulsar-global-mode' is
  enabled.

  There is no need to add all functions that affect the active window to
  the `pulsar-pulse-functions'.  Instead, set the user option
  `pulsar-pulse-on-window-change' to a non-nil value.  It will pulse the
  current line whenever the active window changes (it is part of
  0.4.0-dev).

  The overall duration of the highlight is determined by a combination
  of `pulsar-delay' and `pulsar-iterations'.  The latter determines the
  number of blinks in a pulse, while the former sets their delay in
  seconds before they fade out.  The applicable face is specified in
  `pulsar-face'.

  To disable the pulse but keep the temporary highlight, set the user
  option `pulsar-pulse' to nil.  The current line will remain
  highlighted until another command is invoked.

  To highlight the current line on demand, use the `pulsar-pulse-line'
  command.  When `pulsar-pulse' is non-nil (the default), its highlight
  will pulse before fading away.  Whereas the `pulsar-highlight-line'
  command never pulses the line: the highlight stays in place as if
  `pulsar-pulse' is nil.

  A do-what-I-mean command is also on offer: `pulsar-highlight-dwim'.
  It highlights the current line line like `pulsar-highlight-line'.  If
  the region is active, it applies its effect there.  The region may
  also be a rectangle (internally they differ from ordinary regions).

  To help users differentiate between the pulse and highlight effects,
  the user option `pulsar-highlight-face' controls the presentation of
  the `pulsar-highlight-line' and `pulsar-highlight-dwim' commands.  By
  default, this variable is the same as `pulsar-face'.

  Pulsar depends on the built-in `pulse.el' library.

  Why the name “pulsar”?  It sounds like “pulse” and is a recognisable
  word.  Though if you need a backronym, consider “Pulsar Unquestionably
  Luminates, Strictly Absent the Radiation”.


3 Installation
══════════════




3.1 GNU ELPA package
────────────────────

  The package is available as `pulsar'.  Simply do:

  ┌────
  │ M-x package-refresh-contents
  │ M-x package-install
  └────


  And search for it.


3.2 Manual installation
───────────────────────

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
  │ git clone https://git.sr.ht/~protesilaos/pulsar pulsar
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
  │ (setq pulsar-pulse-functions
  │       ;; NOTE 2022-04-09: The commented out functions are from before
  │       ;; the introduction of `pulsar-pulse-on-window-change'.  Try that
  │       ;; instead.
  │       '(recenter-top-bottom
  │ 	move-to-window-line-top-bottom
  │ 	reposition-window
  │ 	;; bookmark-jump
  │ 	;; other-window
  │ 	;; delete-window
  │ 	;; delete-other-windows
  │ 	forward-page
  │ 	backward-page
  │ 	scroll-up-command
  │ 	scroll-down-command
  │ 	;; windmove-right
  │ 	;; windmove-left
  │ 	;; windmove-up
  │ 	;; windmove-down
  │ 	;; windmove-swap-states-right
  │ 	;; windmove-swap-states-left
  │ 	;; windmove-swap-states-up
  │ 	;; windmove-swap-states-down
  │ 	;; tab-new
  │ 	;; tab-close
  │ 	;; tab-next
  │ 	org-next-visible-heading
  │ 	org-previous-visible-heading
  │ 	org-forward-heading-same-level
  │ 	org-backward-heading-same-level
  │ 	outline-backward-same-level
  │ 	outline-forward-same-level
  │ 	outline-next-visible-heading
  │ 	outline-previous-visible-heading
  │ 	outline-up-heading))
  │ 
  │ (setq pulsar-pulse-on-window-change t)
  │ (setq pulsar-pulse t)
  │ (setq pulsar-delay 0.055)
  │ (setq pulsar-iterations 10)
  │ (setq pulsar-face 'pulsar-magenta)
  │ (setq pulsar-highlight-face 'pulsar-yellow)
  │ 
  │ (pulsar-global-mode 1)
  │ 
  │ ;; OR use the local mode for select mode hooks
  │ 
  │ (dolist (hook '(org-mode-hook emacs-lisp-mode-hook))
  │   (add-hook hook #'pulsar-mode))
  │ 
  │ ;; pulsar does not define any key bindings.  This is just a sample that
  │ ;; respects the key binding conventions.  Evaluate:
  │ ;;
  │ ;;     (info "(elisp) Key Binding Conventions")
  │ ;;
  │ ;; The author uses C-x l for `pulsar-pulse-line' and C-x L for
  │ ;; `pulsar-highlight-line'.
  │ ;;
  │ ;; You can replace `pulsar-highlight-line' with the command
  │ ;; `pulsar-highlight-dwim'.
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

  Contributions to the code or manual
        Aymeric Agon-Rambosson, Daniel Mendler, Ivan Popovych, JD Smith.

  Ideas and user feedback
        Mark Barton, Petter Storvik, Rudolf Adamkovič, Toon Claes, and
        user kb.


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
