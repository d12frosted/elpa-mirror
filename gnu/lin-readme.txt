                      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                       LIN IS NOTICEABLE (LIN.EL)

                          Protesilaos Stavrou
                          info@protesilaos.com
                      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the specifics of
`lin.el'.

The documentation furnished herein corresponds to stable version 2.0.0,
released on 2026-02-12.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 2.1.0-dev.

⁃ Package name (GNU ELPA): `lin'
⁃ Official manual: <https://protesilaos.com/emacs/lin>
⁃ Change log: <https://protesilaos.com/emacs/lin-changelog>
⁃ Git repositories:
  ⁃ GitHub: <https://github.com/protesilaos/lin>
  ⁃ GitLab: <https://gitlab.com/protesilaos/lin>
⁃ Backronym: LIN Is Noticeable.

Table of Contents
─────────────────

1. COPYING
2. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
3. Sample configuration
4. Overview
5. Integration with the GNOME accent color picker
6. Acknowledgements
7. GNU Free Documentation License
8. Indices
.. 1. Function index
.. 2. Variable index
.. 3. Concept index


1 COPYING
═════════

  Copyright (C) 2021-2026 Free Software Foundation, Inc.

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


2 Installation
══════════════

2.1 GNU ELPA package
────────────────────

  The package is available as `lin'.  Simply do:

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
  │ # Clone this repo, naming it "lin"
  │ git clone https://github.com/protesilaos/lin lin
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/lin")
  └────

  Everything is in place to set up the package.


3 Sample configuration
══════════════════════

  ┌────
  │ (use-package lin
  │   :ensure t
  │   :config
  │   (setopt lin-face 'lin-blue) ; check doc string for alternative styles
  │ 
  │   (lin-global-mode 1)
  │ 
  │   ;; If you are using the GNOME desktop and want to synchronise the
  │   ;; `lin-face' with GNOME's accent colour:
  │   (lin-gnome-accent-color-mode 1))
  └────

  Check out Christian Tietze’s blog post on integrating Lin with
  Neotree: <https://christiantietze.de/posts/2022/03/hl-line-priority/>.


4 Overview
══════════

  Lin is a stylistic enhancement for Emacs’ built-in `hl-line-mode'.  It
  remaps the `hl-line' face (or equivalent) buffer-locally to a style
  that is optimal for major modes where line selection is the primary
  mode of interaction.

  The idea is that `hl-line-mode' cannot work equally well for contexts
  with competing priorities: (i) line selection, or (ii) simple line
  highlight.  In the former case, the current line needs to be made
  prominent because it carries a specific meaning of some significance
  in the given context: the user has to select a line.  Whereas in the
  latter case, the primary mode of interaction does not revolve around
  the line highlight itself: it may be because the focus is on editing
  text or reading through the buffer’s contents, so the current line
  highlight is more of a reminder of the point’s location on the
  vertical axis.

  `lin-mode' enables `hl-line-mode' in the current buffer and remaps the
  appropriate face to the `lin-face' ([Integration with the GNOME accent
  color picker]).  The `lin-global-mode' follows the same principle,
  though it applies to all hooks specified in the user option
  `lin-mode-hooks'.

  Users can select their preferred style by customizing the user option
  `lin-face'. Options include the faces `lin-red', `lin-green',
  `lin-yellow', `lin-blue' (default), `lin-magenta', `lin-cyan',
  `lin-purple', `lin-orange', `lin-slate', `lin-mac',
  `lin-red-override-fg', `lin-green-override-fg',
  `lin-yellow-override-fg', `lin-blue-override-fg',
  `lin-magenta-override-fg', `lin-cyan-override-fg',
  `lin-purple-override-fg', `lin-orange-override-fg',
  `lin-slate-override-fg' `lin-mac-override-fg', or any other face that
  preferably has a background attribute. The Lin faces with the
  `-override-fg' suffix set a foreground value which replaces that of
  the underlying text. Whereas the others only specify a background
  attribute.

  The user option `lin-remap-current-line-number' controls whether to
  apply the Lin style also to the currently highlighted line number.
  Line numbers come from the built-in `display-line-numbers-mode'.


[Integration with the GNOME accent color picker] See section 5


5 Integration with the GNOME accent color picker
════════════════════════════════════════════════

  The GNOME desktop environment provides a setting to pick an accent
  color. This is then applied by applications to add a personal touch to
  the user’s experience. Lin can now read this color and automatically
  update all the buffers it is enabled in via the minor mode
  `lin-gnome-accent-color-mode'.

  When `lin-gnome-accent-color-mode' is enabled, Lin reads the accent
  color of GNOME and sets the corresponding Lin face. For example, if
  the user picks red in the GNOME settings, the `lin-face' will be set
  to `lin-red'.

  The user option `lin-gnome-accent-color-override-foreground' controls
  whether the faces that correspond to GNOME accent colors should
  override the underlying text color or not. This is useful for improved
  color contrast. The default is to not override the foreground. Setting
  `lin-gnome-accent-color-override-foreground' to non-`nil' changes that
  so, for example, the `lin-face' will be set to `lin-red-override-fg'.


6 Acknowledgements
══════════════════

  Lin is meant to be a collective effort.  Every bit of help matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to code or documentation
        Christian Tietze, Damien Cassou, Federico Stilman, Gautier
        Ponsinet, Kai von Fintel, Nicolas De Jaeghere, Simon Pugnet.


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
