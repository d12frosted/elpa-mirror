           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
             PULSAR.EL: HIGHLIGHT LINE AUTOMATICALLY AFTER
                        SOME CHANGE OR ON DEMAND

                          Protesilaos Stavrou
                          info@protesilaos.com
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `pulsar' (or `pulsar.el'), and provides every other piece of
information pertinent to it.

The documentation furnished herein corresponds to stable version 1.3.0,
released on 2025-11-30.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 1.4.0-dev.

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
2. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
3. Sample configuration
.. 1. Use pulsar with next-error
.. 2. Use pulsar in the minibuffer
4. Overview
5. Style of a pulse effect
6. Temporary static highlights
7. Permanent static highlights
8. More ways to create automatic pulse effects
9. Resolve function aliases
10. Omit hidden buffers
11. Convenience functions
12. Integration with other packages
13. Acknowledgements
14. GNU Free Documentation License
15. Indices
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


2 Installation
══════════════

2.1 GNU ELPA package
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
  │ # Clone this repo, naming it "pulsar"
  │ git clone https://github.com/protesilaos/pulsar pulsar
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/pulsar")
  └────

  Everything is in place to set up the package.


3 Sample configuration
══════════════════════

  Remember to read the doc string of each of these variables or
  functions.

  ┌────
  │ (use-package pulsar
  │   :ensure t
  │   :bind
  │   ( :map global-map
  │     ("C-x l" . pulsar-pulse-line) ; overrides `count-lines-page'
  │     ("C-x L" . pulsar-highlight-permanently-dwim)) ; or use `pulsar-highlight-temporarily-dwim'
  │   :init
  │   (pulsar-global-mode 1)
  │   :config
  │   (setq pulsar-delay 0.055)
  │   (setq pulsar-iterations 5)
  │   (setq pulsar-face 'pulsar-green)
  │   (setq pulsar-region-face 'pulsar-yellow)
  │   (setq pulsar-highlight-face 'pulsar-magenta))
  └────


3.1 Use pulsar with next-error
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


3.2 Use pulsar in the minibuffer
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


[Convenience functions] See section 11


4 Overview
══════════

  This is a small Emacs package that automatically highlights the
  current line after certain functions are invoked. It can also
  highlight a line or region on demand. The idea is to make it easier to
  find where the point is, what was affected, and also to bring
  attention to something in a buffer.

  When `pulsar-mode' is enabled in the current buffer, a pulsing
  highlight effect will be produced after any command listed in the user
  option `pulsar-pulse-functions'. The `pulsar-global-mode' has the same
  effect in all buffers ([More ways to create automatic pulse effects]).


[More ways to create automatic pulse effects] See section 8


5 Style of a pulse effect
═════════════════════════

  The pulse’s duration is influenced by the user option `pulsar-delay'.
  The greater the value, the longer the highlight will stay on display.
  The user option `pulsar-iterations' controls through how many steps
  does the produced pulse colour go through before it fades away.

  All pulse effects are done with the user option `pulsar-face'. Any
  face with a background attribute can be used for this purpose. Pulsar
  defines several such faces, namely, `pulsar-generic' (the default
  value), `pulsar-red', `pulsar-green', `pulsar-yellow', `pulsar-blue',
  `pulsar-magenta', `pulsar-cyan'.


6 Temporary static highlights
═════════════════════════════

  The command `pulsar-highlight-pulse' will produce a pulse effect on
  demand. This is independent of `pulsar-mode' and all the conditions
  for automatically creating a pulse.

  Unlike pulses which disappear after some time, it is possible to
  create temporary static highlights that stay in place until another
  command is performed. The `pulsar-highlight-temporarily' will produce
  such a static highlight for the active region or current line.

  The user option `pulsar-highlight-face' controls which face is used
  for static highlight (temporary or permanent). By default, it is the
  same as the `pulsar-face', which is for pulse effects, but can be
  assigned to a different face to help differentiate pulses from static
  highlights ([Style of a pulse effect]).


[Style of a pulse effect] See section 5


7 Permanent static highlights
═════════════════════════════

  The command `pulsar-highlight-permanently' adds a permanent static
  highlight to the current line. The effect stays in place even after
  the point moves. When the region is active, the highlight is applied
  from the beginning to the end of the region. Otherwise the highlight
  is applied to the current line.

  The command `pulsar-highlight-permanently-remove' removes permanent
  static highlights from the active region or current line. This command
  operates on the entire buffer when it is called with a universal
  prefix argument (`C-u' by default).

  The command `pulsar-highlight-permanently-dwim' adds a permanent
  static highlight if there is none or removes it if there is one. It
  operates on the currently active region or line at point.

  Permanent static highlights are rendered with the face specified in
  the user option `pulsar-highlight-face'. It is the same used for their
  temporary counterparts ([Temporary static highlights]).


[Temporary static highlights] See section 6


8 More ways to create automatic pulse effects
═════════════════════════════════════════════

  The `pulsar-mode' and `pulsar-global-mode' perform an automatic pulse
  after a function in the `pulsar-pulse-functions' is called
  ([Overview]).  They can do the same in more cases.

  Region-related changes
        Pulsar can also produce an effect over a specific region. This
        is useful to, for example, highlight the area covered by text
        that is pasted in the buffer. The user option
        `pulsar-pulse-region-functions' defines a list of functions that
        are region-aware in this regard. The default value covers
        copyring, pasting, and undoing/redoing.
  Window-related changes
        The pulse effect can be created whenever there is a change to
        the window layout. This includes the selection, addition,
        deletion, orr resize of windows in a frame. Users can opt in to
        this feature by setting `pulsar-pulse-on-window-change' to a
        non-`nil' value.

  The user option `pulsar-region-face' sets the face that is used for
  region-related pulses. By default, it is the same as the `pulsar-face'
  ([Style of a pulse effect]).


[Overview] See section 4

[Style of a pulse effect] See section 5


9 Resolve function aliases
══════════════════════════

  By default, Pulsar does not try to resolve and act on a function’s
  aliases ([Overview]). It only works with the exact symbols it is
  given.  If those aliases are not added to the `pulsar-pulse-functions'
  and/or `pulsar-pulse-region-functions', they will not produce a pulse
  effect ([More ways to create automatic pulse effects]).

  The user option `pulsar-resolve-pulse-function-aliases' can be set to
  a non-`nil' value to make Pulsar check for the aliases of all the
  function symbols it is aware of and act on them accordingly.


[Overview] See section 4

[More ways to create automatic pulse effects] See section 8


10 Omit hidden buffers
══════════════════════

  The user option `pulsar-inhibit-hidden-buffers' controls whether
  Pulsar is active in hidden buffers. These are buffers that users
  normally do not interact with and are not displayed in the interface
  of the various buffer-switching commands. When this user option is set
  to `nil', Pulsar will work in those buffers as well ([Overview]).


[Overview] See section 4


11 Convenience functions
════════════════════════

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


12 Integration with other packages
══════════════════════════════════

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


13 Acknowledgements
═══════════════════

  Pulsar is meant to be a collective effort.  Every bit of help matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to the code or manual
        Abdelhak Bougouffa, Aymeric Agon-Rambosson, Bahman Movaqar,
        Daniel Mendler, Ivan Popovych, JD Smith, Maxim Dunaevsky, Ryan
        Kaskel, shipmints, ukiran03.

  Ideas and user feedback
        Anwesh Gangula, Diego Alvarez, Duy Nguyen, Koloszár Gergely,
        Matthias Meulien, Mark Barton, Petter Storvik, Ronny Randen,
        Rudolf Adamkovič, Toon Claes, and users djl, kb.


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
