――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――


1 Introduction
══════════════

        The experience of dirvish is surreal and even bizarre
        after all these years of trying to use dired. Like how
        professionals make their craft look easy, dirvish does
        something similar with how it builds on dired. Dirvish is
        paradoxical in that it provides a completely different
        experience while still fundamentally being dired at its
        core.

        – @noctuid ([source])

  Dirvish is an improved version of the Emacs inbuilt package [Dired].
  It not only gives Dired an appealing and highly customizable user
  interface, but also comes together with almost all possible parts
  required for full usability as a modern file manager.


[source] <https://github.com/alexluigit/dirvish/issues/34>

[Dired]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Dired.html>


2 Screenshots
═════════════

  [https://user-images.githubusercontent.com/16313743/189978788-900b3de7-b3e5-42a6-9f28-426e1e80c314.png]

  [https://user-images.githubusercontent.com/16313743/189978802-f6fb09ea-13a2-4dc9-828b-992523d51dd5.png]

  [https://user-images.githubusercontent.com/16313743/190370038-1d64a7aa-ac1c-4436-a2a3-05cd801de0a4.png]


[https://user-images.githubusercontent.com/16313743/189978788-900b3de7-b3e5-42a6-9f28-426e1e80c314.png]
<https://user-images.githubusercontent.com/16313743/189978788-900b3de7-b3e5-42a6-9f28-426e1e80c314.png>

[https://user-images.githubusercontent.com/16313743/189978802-f6fb09ea-13a2-4dc9-828b-992523d51dd5.png]
<https://user-images.githubusercontent.com/16313743/189978802-f6fb09ea-13a2-4dc9-828b-992523d51dd5.png>

[https://user-images.githubusercontent.com/16313743/190370038-1d64a7aa-ac1c-4436-a2a3-05cd801de0a4.png]
<https://user-images.githubusercontent.com/16313743/190370038-1d64a7aa-ac1c-4436-a2a3-05cd801de0a4.png>


3 Prerequisites
═══════════════

  This package requires `GNU ls' (`gls' on macOS), and /optionally/:

  ⁃ `fd' as a faster alternative to `find'
  ⁃ `imagemagick' for image preview
  ⁃ `poppler' | `pdf-tools' for pdf preview
  ⁃ `ffmpegthumbnailer' for video preview
  ⁃ `mediainfo' for audio/video metadata generation
  ⁃ `tar' and `unzip' for archive files preview


   Toggle install instructions

  macOS
  ┌────
  │ brew install coreutils fd poppler ffmpegthumbnailer mediainfo imagemagick
  └────

  Debian-based
  ┌────
  │ apt install fd-find poppler-utils ffmpegthumbnailer mediainfo imagemagick tar unzip
  └────

  Arch-based
  ┌────
  │ pacman -S fd poppler ffmpegthumbnailer mediainfo imagemagick tar unzip
  └────

  FreeBSD
  ┌────
  │ pkg install gnuls fd-find poppler ffmpegthumbnailer ImageMagick7 gtar
  └────

  Windows (untested)
  ┌────
  │ # install via Scoop: https://scoop.sh/
  │ scoop install coreutils fd poppler imagemagick unzip
  └────


4 Installation
══════════════

  Dirvish is available on [Melpa].  Just type `M-x package-install RET
  dirvish RET' into Emacs 27.1+.  `el-get' users can get the recipe from
  [here].

  For straight.el users, it is simply:
  ┌────
  │ (straight-use-package 'dirvish)
  └────


[Melpa] <https://melpa.org/#/dirvish>

[here] <https://github.com/alexluigit/dirvish/issues/90>


5 Quickstart
════════════

  After installation, let Dirvish take over Dired globally:
  ┌────
  │ (dirvish-override-dired-mode)
  └────

  ⁃ `M-x dirvish RET'

    Welcome to Dirvish!  Press `?' for help.

  ⁃ `M-x dired' | `dired-jump' | … `RET'

    Dirvish takes care all of your Dired entries.

  ⁃ `M-x dirvish-dwim RET'

    If the selected window is the only window, open Dirvish, otherwise
    open Dired.


6 Resources
═══════════

  ⁃ [Customizing]
  ⁃ [Extensions]
  ⁃ [Related projects]
  ⁃ [Changelog]
  ⁃ [Absolute beginner's guide]
  ⁃ [Discussions]


[Customizing] <file:docs/CUSTOMIZING.org>

[Extensions] <file:docs/EXTENSIONS.org>

[Related projects] <file:docs/COMPARISON.org>

[Changelog] <file:docs/CHANGELOG.org>

[Absolute beginner's guide] <file:docs/EMACS-NEWCOMERS.org>

[Discussions] <https://github.com/alexluigit/dirvish/discussions>


7 Acknowledgements
══════════════════

  This package took inspiration from the terminal file manager [ranger]
  and [treemacs] from Alexander Miller.  Some of the extensions was
  initially a rewrite of packages provided by [dired-hacks]. These
  extensions have been greatly enhanced in comparison to the original
  versions.

  Thanks Fox Kiester (@noctuid) for the awesome [summary] of Dirvish.

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
  [file:https://melpa.org/packages/dirvish-badge.svg]
  [file:https://stable.melpa.org/packages/dirvish-badge.svg]
  [file:https://github.com/alexluigit/dirvish/actions/workflows/melpazoid.yml/badge.svg]


[ranger] <https://github.com/ranger/ranger>

[treemacs] <https://github.com/Alexander-Miller/treemacs>

[dired-hacks] <https://github.com/Fuco1/dired-hacks>

[summary] <https://github.com/alexluigit/dirvish/issues/34>

[Fox Kiester] <https://github.com/noctuid>

[JD Smith] <https://github.com/jdtsmith>

[karthink] <https://github.com/karthink>

[gcv] <https://github.com/gcv>

[aikrahguzar] <https://github.com/aikrahguzar>

[Daniel Mendler] <https://github.com/minad>

[vim-dirvish] <https://github.com/justinmk/vim-dirvish>

[file:https://melpa.org/packages/dirvish-badge.svg]
<https://melpa.org/#/dirvish>

[file:https://stable.melpa.org/packages/dirvish-badge.svg]
<https://stable.melpa.org/#/dirvish>

[file:https://github.com/alexluigit/dirvish/actions/workflows/melpazoid.yml/badge.svg]
<https://github.com/alexluigit/dirvish/actions/workflows/melpazoid.yml>
