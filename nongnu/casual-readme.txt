[file:https://melpa.org/packages/casual-badge.svg]
[file:https://stable.melpa.org/packages/casual-badge.svg]


[file:https://melpa.org/packages/casual-badge.svg]
<https://melpa.org/#/casual>

[file:https://stable.melpa.org/packages/casual-badge.svg]
<https://stable.melpa.org/#/casual>


1 Casual
════════

  Casual is a project to re-imagine the primary user interface for Emacs
  using keyboard-driven menus.

  Emacs has many commands that are easy to forget if not used
  frequently. Menus are a user interface (UI) affordance that offers
  discoverability and recognition. While menus are commonly associated
  with mouse-driven UI, the inclusion of [Transient] in Emacs core
  allows for building menus that are keyboard-driven instead. This
  appeals to users that prefer keyboard-driven workflows.

  Casual organizes itself primarily around the different built-in modes
  Emacs provides. For each mode Casual supports, there is a bespoke
  designed library of Transient menus for that mode's command set.

  Casual has no aims to be a mutually exclusive user interface. All
  existing user interfaces to commands (keybinding, mini-buffer prompt,
  mouse menus) are still available to the user.

  To learn more about the motivations and design considerations for
  Casual as well as seeing it at work, please watch the presentation
  [“Re-imagining the Emacs User Experience with Casual Suite”] from
  EmacsConf 2024.

  Please refer to the [Casual User Guide] for detailed information about
  it. This user guide is available both in Emacs Info and HTML formats.


[Transient] <https://github.com/magit/transient>

[“Re-imagining the Emacs User Experience with Casual Suite”]
<https://emacsconf.org/2024/talks/casual/>

[Casual User Guide] <https://kickingvegas.github.io/casual>


2 Requirements
══════════════

  Casual requires Emacs 29.1+, Transient 0.9.0+, csv-mode 1.27+.

  Certain menus require more installed software:

  • Casual Dired: GNU Coreutils
  • Casual Image: ImageMagick 6+


3 Install
═════════

  In Emacs, a “mode” is analogous to an “app” in that it is a grouping
  of related features. Installation of Casual is done on a per-mode
  basis.

  [Installation instructions for the different modes supported by Casual
  can be found in the Casual User Guide].


[Installation instructions for the different modes supported by Casual
can be found in the Casual User Guide]
<https://kickingvegas.github.io/casual/Install.html>


4 Asks
══════

  As Casual is new, we are looking for early adopters! Your [feedback]
  is welcome as it will likely impact Casual's evolution, particularly
  with regards to UI.


[feedback] <https://github.com/kickingvegas/casual/discussions>


5 Development
═════════════

  For users who wish to help contribute to Casual or personally
  customize it for their own usage, please read the .


6 Sponsorship
═════════════

  It costs money to make, enhance, and maintain Casual as ideologically
  free software. If you enjoy using Casual, please buy me a coffee to
  help support its development and maintenance.

  [file:docs/images/default-yellow.png]


[file:docs/images/default-yellow.png]
<https://www.buymeacoffee.com/kickingvegas>


7 See Also
══════════

  While the package `casual' focuses on user interfaces for built-in
  Emacs modes, there are other third party packages which receive the
  “Casual” treatment. Two such packages are:

  • [Casual Avy] (Elisp package: `casual-avy')
    • An interface for the highly capable Avy navigation package.
  • [Casual Symbol Overlay] (Elisp package: `casual-symbol-overlay')
    • An interface for the Symbol Overlay package.

  Users interested in getting all current and future Casual interfaces
  for both built-in and third party packages should install [Casual
  Suite], which includes all of the above packages including `casual'.


[Casual Avy] <https://github.com/kickingvegas/casual-avy>

[Casual Symbol Overlay]
<https://github.com/kickingvegas/casual-symbol-overlay>

[Casual Suite] <https://github.com/kickingvegas/casual-suite>


8 Acknowledgments
═════════════════

  A heartfelt thanks to all the contributors to [Transient], [Magit],
  [Org Mode], and [Emacs]. This package would not be possible without
  your efforts.


[Transient] <https://github.com/magit/transient>

[Magit] <https://magit.vc>

[Org Mode] <https://orgmode.org>

[Emacs] <https://www.gnu.org/software/emacs/>
