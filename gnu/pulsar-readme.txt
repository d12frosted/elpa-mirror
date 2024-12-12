           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              PULSAR.EL: PULSE HIGHLIGHT LINE ON DEMAND OR
                     AFTER RUNNING SELECT FUNCTIONS

                          Protesilaos Stavrou
                          info@protesilaos.com
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `pulsar' (or `pulsar.el'), and provides every other piece of
information pertinent to it.

The documentation furnished herein corresponds to stable version 1.2.0,
released on 2024-12-12.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 1.3.0-dev.

⁃ Package name (GNU ELPA): `pulsar'
⁃ Official manual: <https://protesilaos.com/emacs/pulsar>
⁃ Change log: <https://protesilaos.com/emacs/pulsar-changelog>
⁃ Git repositories:
  ⁃ GitHub: <https://github.com/protesilaos/pulsar>
  ⁃ GitLab: <https://gitlab.com/protesilaos/pulsar>
⁃ Backronym: Pulsar Unquestionably Luminates, Strictly Absent the
  Radiation.

Table of Contents
─────────────────

1. COPYING
2. Overview
.. 1. Convenience functions
3. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
4. Sample configuration
.. 1. Use pulsar with next-error
.. 2. Use pulsar in the minibuffer
5. Integration with other packages
6. Acknowledgements
7. GNU Free Documentation License
8. Indices
.. 1. Function index
.. 2. Variable index
.. 3. Concept index


1 COPYING
═════════

  Copyright (C) 2022-2024 Free Software Foundation, Inc.

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

  By default, Pulsar does not try to behave the same way for a
  function’s aliases. If those are not added explicitly to the
  `pulsar-pulse-functions', they will not have a pulse effect. However,
  the user option `pulsar-resolve-pulse-function-aliases' can be set to
  a non-nil value to change this behaviour, meaning that Pulsar will
  cover a function’s aliases even if those are not explicitly added to
  the `pulsar-pulse-functions'.

  Pulsar can also produce an effect over a specific region. This is
  useful to, for example, highlight the area covered by text that is
  pasted in the buffer. The user option `pulsar-pulse-region-functions'
  defines a list of functions that are region-aware in this regard. The
  default value covers copyring, pasting, and undoing/redoing.

  The pulse effect also happens whenever there is a change to the window
  layout. This includes the selection, addition, deletion, resize of
  windows in a frame. Users who do not want this to happen can set the
  user option `pulsar-pulse-on-window-change' to a nil value.

  The overall duration of the highlight is determined by a combination
  of `pulsar-delay' and `pulsar-iterations'.  The latter determines the
  number of blinks in a pulse, while the former sets their delay in
  seconds before they fade out.  The applicable face is specified in
  `pulsar-face'.

  To disable the pulse but keep the temporary highlight, set the user
  option `pulsar-pulse' to nil.  The current line will remain
  highlighted until another command is invoked.

  The user option `pulsar-inhibit-hidden-buffers' controls whether
  Pulsar is active in hidden buffers. These are buffers that users
  normally do not interact with and are not displayed in the interface
  of the various buffer-switching commands. When this user option is
  nil, `pulsar-mode' will work in those buffers as well.

  To highlight the current line on demand, use the `pulsar-pulse-line'
  command.  When `pulsar-pulse' is non-nil (the default), its highlight
  will pulse before fading away.  Whereas the `pulsar-highlight-line'
  command never pulses the line: the highlight stays in place as if
  `pulsar-pulse' is nil.

  The command `pulsar-pulse-region' pulses the active region. The effect
  of the pulse is controlled by the aforementioned user options, namely,
  `pulsar-delay', `pulsar-iterations', `pulsar-face'.

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


2.1 Convenience functions
─────────────────────────

  Depending on the user’s workflow, there may be a need for differently
  colored pulses.  These are meant to provide an ad-hoc deviation from
  the standard style of the command `pulsar-pulse-line' (which is
  governed by the user option `pulsar-face').  Pulsar thus provides the
  following for the user’s convenience:

  • `pulsar-pulse-line-red'

  • `pulsar-pulse-line-green'

  • `pulsar-pulse-line-yellow'

  • `pulsar-pulse-line-blue'

  • `pulsar-pulse-line-magenta'

  • `pulsar-pulse-line-cyan'

  These can be called with `M-x', assigned to a hook and/or key binding,
  or be incorporated in custom functions.


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

  GNU ELPA provides the latest stable release.  Those who prefer to
  follow the development process in order to report bugs or suggest
  changes, can use the version of the package from the GNU-devel ELPA
  archive.  Read:
  <https://protesilaos.com/codelog/2022-05-13-emacs-elpa-devel/>.


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
  │ git clone https://github.com/protesilaos/pulsar pulsar
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
  │ ;; Check the default value of `pulsar-pulse-functions'.  That is where
  │ ;; you add more commands that should cause a pulse after they are
  │ ;; invoked
  │ 
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


4.1 Use pulsar with next-error
──────────────────────────────

  By default, the `n' and `p' keys in Emacs’ compilation buffers
  (e.g. the results of a `grep' search) produce a highlight for the
  locus of the given match.  Due to how the code is implemented, we
  cannot use Pulsar’s standard mechanism to trigger a pulse after the
  match is highlighted.  Instead, the user must add this to their
  configuration in lieu of a Pulsar-level solution that “just works”:

  ┌────
  │ (add-hook 'next-error-hook #'pulsar-pulse-line)
  └────


4.2 Use pulsar in the minibuffer
────────────────────────────────

  Due to how the minibuffer works, the user cannot rely on the user
  option `pulse-pulse-functions' to automatically pulse in that context.
  Instead, the user must add a function to the `minibuffer-setup-hook':
  it will trigger a pulse as soon as the minibuffer shows up:

  ┌────
  │ (add-hook 'minibuffer-setup-hook #'pulsar-pulse-line)
  └────

  The `pulsar-pulse-line' function will use the default Pulsar face, per
  the user option `pulsar-face'.

  A convenience function can also be used ([Convenience functions]).
  The idea is to apply a different color than the one applied by
  default.  For example:

  ┌────
  │ (add-hook 'minibuffer-setup-hook #'pulsar-pulse-line-blue)
  └────


[Convenience functions] See section 2.1


5 Integration with other packages
═════════════════════════════════

  Beside `pulsar-pulse-line', Pulsar defines a few functions that can be
  added to hooks that are provided by other packages.

  There are two functions to recenter and then pulse the current line:
  `pulsar-recenter-top' and `pulsar-recenter-center' (alias
  `pulsar-recenter-middle').

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
        Abdelhak Bougouffa, Aymeric Agon-Rambosson, Bahman Movaqar,
        Daniel Mendler, Ivan Popovych, JD Smith, Maxim Dunaevsky, Ryan
        Kaskel, shipmints, ukiran03.

  Ideas and user feedback
        Anwesh Gangula, Diego Alvarez, Duy Nguyen, Mark Barton, Petter
        Storvik, Ronny Randen, Rudolf Adamkovič, Toon Claes, and users
        djl, kb.


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
