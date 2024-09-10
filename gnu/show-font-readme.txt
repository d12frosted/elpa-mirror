                       ━━━━━━━━━━━━━━━━━━━━━━━━━━
                        SHOW-FONT: PREVIEW FONTS

                          Protesilaos Stavrou
                          info@protesilaos.com
                       ━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for the Emacs package called `show-font' (or `show-font.el'),
and provides every other piece of information pertinent to it.

The documentation furnished herein corresponds to stable version 0.1.0,
released on 2024-09-10.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 0.2.0-dev.

⁃ Package name (GNU ELPA): `show-font'
⁃ Official manual: <https://protesilaos.com/emacs/show-font>
⁃ Change log: <https://protesilaos.com/emacs/show-font-changelog>
⁃ Git repository: <https://github.com/protesilaos/show-font>
⁃ Backronym: Show How Outlines Will Feature Only in Non-TTY.

If you are viewing the README.org version of this file, please note that
the GNU ELPA machinery automatically generates an Info manual out of it.

Table of Contents
─────────────────

1. Overview
2. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
3. Sample configuration
4. Acknowledgements
5. COPYING
6. GNU Free Documentation License
7. Indices
.. 1. Function index
.. 2. Variable index
.. 3. Concept index


1 Overview
══════════

  With `show-font' the user has the means to preview fonts inside of
  Emacs. This can be done in the following ways:

  • The command `show-font-select-preview' uses the minibuffer to
    completion with completion for a font on the system. The selected
    font is then displayed in a bespoke buffer.

  • The command `show-font-list' produces a list with all the fonts
    available on the system each font on display is styled with its
    given character set.

  • The `show-font-mode' is a major mode that gets activated when the
    user visits a `.ttf' or `.otf' file. It will preview with the font,
    if it is installed on the system, else it will provide a helpful
    message and an option to install the font (NOTE 2024-09-10: this
    only works on Linux).

  The previews include a pangram, which is controlled by the user option
  `show-font-pangram'. The default value is a playful take on the more
  familiar “the quick brown fox jumps over the lazy dog” phrase. Users
  can select among a few presets, or define their own custom string.

  The function `show-font-pangram-p' is available for those who wish to
  experiment with writing their own pangrams (it is not actually limited
  to the Latin alphabet).

  The user option `show-font-character-sample' provides a more complete
  character set that is intended for use in full buffer previews (i.e.
  not in the list of fonts). It can be set to any string. The default
  value is a set of alphanumeric characters that are commonly used in
  programming: a good monospaced font should render all of them
  unambiguously.

  Finally, the following faces control the appearance of various
  elements.

  • `show-font-small'

  • `show-font-regular'

  • `show-font-medium'

  • `show-font-large'

  • `show-font-title'

  • `show-font-title-small'

  • `show-font-misc'

  • `show-font-button'


2 Installation
══════════════




2.1 GNU ELPA package
────────────────────

  The package is available as `show-font'.  Simply do:

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


2.2 Manual installation
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
  │ # Clone this repo, naming it "show-font"
  │ git clone https://github.com/protesilaos/show-font show-font
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/show-font")
  └────

  Everything is in place to set up the package.


3 Sample configuration
══════════════════════

  ┌────
  │ (require 'show-font)
  │ 
  │ (define-key global-map (kbd "C-c s f") #'show-font-select-preview)
  │ (define-key global-map (kbd "C-c s l") #'show-font-list)
  └────


4 Acknowledgements
══════════════════

  `show-font' is meant to be a collective effort. Every bit of help
  matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to code or the manual
        Eli Zaretskii, Philip Kaludercic, Swapnil Mahajan.

  Ideas and/or user feedback
        Darryl Hebbes, Perry Metzger.


5 COPYING
═════════

  Copyright (C) 2023 Free Software Foundation, Inc.

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
