           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              ALTCAPS: APPLY ALTERNATING LETTER CASING TO
                       CONVEY SARCASM OR MOCKERY

                          Protesilaos Stavrou
                          info@protesilaos.com
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `altcaps' (or `altcaps.el'), and provides every other piece
of information pertinent to it.

The documentation furnished herein corresponds to stable version 1.3.0,
released on 2025-01-28.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 1.4.0-dev.

⁃ Package name (GNU ELPA): `altcaps'
⁃ Official manual: <https://protesilaos.com/emacs/altcaps>
⁃ Change log: <https://protesilaos.com/emacs/altcaps-changelog>
⁃ Git repositories:
  ⁃ GitHub: <https://github.com/protesilaos/altcaps>
  ⁃ GitLab: <https://gitlab.com/protesilaos/altcaps>
⁃ Backronyms: Alternating Letters Transform Casual Asides to Playful
  Statements.  ALTCAPS Lets Trolls Convert Aphorisms to Proper
  Shitposts.

Table of Contents
─────────────────

1. COPYING
2. Overview
3. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
4. Sample configuration
5. Acknowledgements
6. GNU Free Documentation License
7. Indices
.. 1. Function index
.. 2. Variable index
.. 3. Concept index


1 COPYING
═════════

  Copyright (C) 2022-2025 Free Software Foundation, Inc.

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

  Transform words to alternating letter casing in order to convey
  sarcasm or mockery.  For example, convert this:

  ┌────
  │ I respect the authorities
  └────


  To this:

  ┌────
  │ i ReSpEcT tHe AuThOrItIeS
  └────


  The `altcaps' package thus makes you more effective at textual
  communication.  Plus, you appear sophisticated.  tRuSt Me.

  Use any of the following commands to achieve the desired results:

  `altcaps-word'
        Convert word to alternating letter casing.  With optional `NUM'
        as a numeric prefix argument, operate on `NUM' words forward,
        defaulting to 1.  If `NUM' is negative, do so backward.  When
        `NUM' is a negative prefix without a number, it is interpreted
        -1.

  `altcaps-region'
        Convert region words between `BEG' and `END' to alternating
        case.  `BEG' and `END' are buffer positions.  When called
        interactively, these are automatically determined as the active
        region’s boundaries, else the space between `mark' and `point'.

  `altcaps-dwim'
        Convert to alternating letter casing Do-What-I-Mean style.  With
        an active region, call `altcaps-region'.  Else invoke
        `altcaps-word' with optional `NUM', per that command’s
        functionality (read its documentation).

  The user option `altcaps-force-character-casing' forces the given
  letter casing for specified characters.  Its value is an alist of
  `(STRING . CASE)' pairs.  `STRING' is a string with a single
  character, while `CASE' is the `upcase' or `downcase' symbol (code
  sample further below).

  The idea is to always render certain characters in lower or upper
  case, in consideration of their legibility in context.  For example,
  the default altcaps algorithm produces this:

  ┌────
  │ iLlIcIt IlLiBeRaL sIlLiNeSs
  └────


  Whereas if the value of this variable declares `i' to always be
  lowercase and `L' uppercase, then we get this:

  ┌────
  │ iLLiCiT iLLiBeRaL siLLiNeSs
  └────


  The code to do this:

  ┌────
  │ (setq altcaps-force-character-casing
  │       '(("i" . downcase)
  │ 	("l" . upcase)))
  └────


3 Installation
══════════════




3.1 GNU ELPA package
────────────────────

  The package is available as `altcaps'.  Simply do:

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
  │ # Clone this repo, naming it "altcaps"
  │ git clone https://github.com/protesilaos/altcaps altcaps
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/altcaps")
  └────

  Everything is in place to set up the package.


4 Sample configuration
══════════════════════

  ┌────
  │ (require 'altcaps)
  │ 
  │ ;; Force letter casing for certain characters (for legibility).
  │ (setq altcaps-force-character-casing
  │       '(("i" . downcase)
  │ 	("l" . upcase)))
  │ 
  │ ;; We do not bind any keys, but you are free to do so:
  │ (define-key global-map (kbd "C-x C-a") #'altcaps-dwim)
  │ 
  │ ;; The commands we provide:
  │ ;;
  │ ;; - `altcaps-word'
  │ ;; - `altcaps-region'
  │ ;; - `altcaps-dwim'
  └────

  With `use-package':

  ┌────
  │ (use-package altcaps
  │   :ensure t
  │   :bind
  │   ("C-x C-a" . altcaps-dwim)
  │   :config
  │   ;; Optionally force letter casing for certain characters (for legibility).
  │   (setq altcaps-force-character-casing
  │       '(("i" . downcase)
  │ 	("l" . upcase))))
  └────


5 Acknowledgements
══════════════════

  aLtCaPs is meant to be a collective effort.  Every bit of help
  matters.

  Author/maintainer
        Protesilaos Stavrou.

  Ideas and/or user feedback
        Cédric Barreteau.

  Cédric is the author of an `altcaps'-inspired package for NeoVim, from
  whence I got the idea of forcing a given letter case for certain
  characters (I do it with the `altcaps-force-character-casing' user
  option): <https://github.com/cbarrete/nvim-altcaps>.


6 GNU Free Documentation License
════════════════════════════════


7 Indices
═════════

7.1 Function index
──────────────────


7.2 Variable index
──────────────────


7.3 Concept index
─────────────────
