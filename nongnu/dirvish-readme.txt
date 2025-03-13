――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――


1 Introduction
══════════════

  Dirvish enhances Emacs' built-in Dired mode, providing a visually
  appealing and highly customizable interface.  More than just a
  facelift, Dirvish delivers a comprehensive suite of features,
  transforming Dired into a modern and fully functional file manager.

        The experience of dirvish is surreal and even bizarre
        after all these years of trying to use dired. Like how
        professionals make their craft look easy, dirvish does
        something similar with how it builds on dired. Dirvish is
        paradoxical in that it provides a completely different
        experience while still fundamentally being dired at its
        core.

        – Special thanks to @noctuid for [this summary of Dirvish]


[this summary of Dirvish]
<https://github.com/alexluigit/dirvish/issues/34>


2 Screenshots
═════════════

  [https://user-images.githubusercontent.com/16313743/190370038-1d64a7aa-ac1c-4436-a2a3-05cd801de0a4.png]

  [https://user-images.githubusercontent.com/16313743/189978788-900b3de7-b3e5-42a6-9f28-426e1e80c314.png]

  [https://user-images.githubusercontent.com/16313743/189978802-f6fb09ea-13a2-4dc9-828b-992523d51dd5.png]


[https://user-images.githubusercontent.com/16313743/190370038-1d64a7aa-ac1c-4436-a2a3-05cd801de0a4.png]
<https://user-images.githubusercontent.com/16313743/190370038-1d64a7aa-ac1c-4436-a2a3-05cd801de0a4.png>

[https://user-images.githubusercontent.com/16313743/189978788-900b3de7-b3e5-42a6-9f28-426e1e80c314.png]
<https://user-images.githubusercontent.com/16313743/189978788-900b3de7-b3e5-42a6-9f28-426e1e80c314.png>

[https://user-images.githubusercontent.com/16313743/189978802-f6fb09ea-13a2-4dc9-828b-992523d51dd5.png]
<https://user-images.githubusercontent.com/16313743/189978802-f6fb09ea-13a2-4dc9-828b-992523d51dd5.png>


3 Installation
══════════════

  Dirvish is available from [Nongnu-Elpa] and [Melpa].  You can install
  it directly via `M-x package-install RET dirvish RET' on Emacs 28.1+.
  After installation, activate Dirvish globally with `M-x
  dirvish-override-dired-mode RET'.


[Nongnu-Elpa] <https://elpa.nongnu.org/nongnu/dirvish.html>

[Melpa] <https://melpa.org/#/dirvish>


4 Quickstart
════════════

  ⁃ `M-x dirvish RET'

    Welcome to Dirvish!  Use your favorite dired commands here, press
    `q' to quit.

  ⁃ `M-x dirvish-dwim RET'

    Works the same as `dirvish' when the selected window is the only
    window; otherwise, it avoids occupying the entire frame.

  ⁃ `M-x dirvish-dispatch RET'

    This is a help/cheatsheet menu powered by `transient.el', the same
    library used to implement keyboard-driven menus in Magit and many
    Dirvish extensions.  If you prefer this interaction style, consider
    binding these menus to `dirvish-mode-map'.  See [example config] for
    details.


[example config] <file:docs/CUSTOMIZING.org>


5 Documentation
═══════════════

  For more dirvish customization options and features, see our
  documentation:

  ⁃ [Customizing]
  ⁃ [Extensions]
  ⁃ [FAQ]
  ⁃ [Absolute beginner's guide]


[Customizing] <file:docs/CUSTOMIZING.org>

[Extensions] <file:docs/EXTENSIONS.org>

[FAQ] <file:docs/FAQ.org>

[Absolute beginner's guide] <file:docs/EMACS-NEWCOMERS.org>


6 Resources
═══════════

  To delve deeper into Dirvish, explore these resources:

  ⁃ [Related projects]
  ⁃ [Changelog]
  ⁃ [Discussions]


[Related projects] <file:docs/COMPARISON.org>

[Changelog] <file:docs/CHANGELOG.org>

[Discussions] <https://github.com/alexluigit/dirvish/discussions>


7 Acknowledgements
══════════════════

  This package draws inspiration from the terminal file manager
  [ranger].  Some extensions began as rewrites of packages from
  [dired-hacks], but have since been significantly enhanced.

  *Code contributions*:



  *Useful advice and discussions*:

  • [Fox Kiester]
  • [JD Smith]
  • [karthink]
  • [gcv]
  • [aikrahguzar]
  • [Daniel Mendler]

  The name *dirvish* is a tribute to [vim-dirvish].
  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
  [file:https://elpa.nongnu.org/nongnu/dirvish.svg]
  [file:https://melpa.org/packages/dirvish-badge.svg]
  [file:https://stable.melpa.org/packages/dirvish-badge.svg]
  [file:https://github.com/alexluigit/dirvish/actions/workflows/melpazoid.yml/badge.svg]


[ranger] <https://github.com/ranger/ranger>

[dired-hacks] <https://github.com/Fuco1/dired-hacks>

[Fox Kiester] <https://github.com/noctuid>

[JD Smith] <https://github.com/jdtsmith>

[karthink] <https://github.com/karthink>

[gcv] <https://github.com/gcv>

[aikrahguzar] <https://github.com/aikrahguzar>

[Daniel Mendler] <https://github.com/minad>

[vim-dirvish] <https://github.com/justinmk/vim-dirvish>

[file:https://elpa.nongnu.org/nongnu/dirvish.svg]
<https://elpa.nongnu.org/nongnu/dirvish.html>

[file:https://melpa.org/packages/dirvish-badge.svg]
<https://melpa.org/#/dirvish>

[file:https://stable.melpa.org/packages/dirvish-badge.svg]
<https://stable.melpa.org/#/dirvish>

[file:https://github.com/alexluigit/dirvish/actions/workflows/melpazoid.yml/badge.svg]
<https://github.com/alexluigit/dirvish/actions/workflows/melpazoid.yml>
