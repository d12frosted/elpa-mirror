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

  [https://user-images.githubusercontent.com/16313743/187678438-18c2032c-d937-4417-aca7-c59d72dcf38b.png]

  [https://user-images.githubusercontent.com/16313743/187436132-f15cdbf7-ed05-47ed-aa08-37c64baca2c0.png]

  [https://user-images.githubusercontent.com/16313743/187674778-20aad9d6-0398-4a95-a10f-f01ab164d454.png]


[https://user-images.githubusercontent.com/16313743/187678438-18c2032c-d937-4417-aca7-c59d72dcf38b.png]
<https://user-images.githubusercontent.com/16313743/187678438-18c2032c-d937-4417-aca7-c59d72dcf38b.png>

[https://user-images.githubusercontent.com/16313743/187436132-f15cdbf7-ed05-47ed-aa08-37c64baca2c0.png]
<https://user-images.githubusercontent.com/16313743/187436132-f15cdbf7-ed05-47ed-aa08-37c64baca2c0.png>

[https://user-images.githubusercontent.com/16313743/187674778-20aad9d6-0398-4a95-a10f-f01ab164d454.png]
<https://user-images.githubusercontent.com/16313743/187674778-20aad9d6-0398-4a95-a10f-f01ab164d454.png>


3 Prerequisites
═══════════════

  This package requires `GNU ls' (`gls' on some OSs), and /optionally/:

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


6 Resources
═══════════

  ⁃ [Customizing]
  ⁃ [Extensions]
  ⁃ [Related projects]
  ⁃ [Changelog]
  ⁃ [Discussions]


[Customizing] <file:docs/CUSTOMIZING.org>

[Extensions] <file:docs/EXTENSIONS.org>

[Related projects] <file:docs/COMPARISON.org>

[Changelog] <file:docs/CHANGELOG.org>

[Discussions] <https://github.com/alexluigit/dirvish/discussions>


7 Acknowledgements
══════════════════

  Thanks Fox Kiester (@noctuid) for the awesome [summary] of Dirvish.

  The name *dirvish* is a tribute to [vim-dirvish].
  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
  [file:https://melpa.org/packages/dirvish-badge.svg]
  [file:https://stable.melpa.org/packages/dirvish-badge.svg]
  [file:https://github.com/alexluigit/dirvish/actions/workflows/melpazoid.yml/badge.svg]


[summary] <https://github.com/alexluigit/dirvish/issues/34>

[vim-dirvish] <https://github.com/justinmk/vim-dirvish>

[file:https://melpa.org/packages/dirvish-badge.svg]
<https://melpa.org/#/dirvish>

[file:https://stable.melpa.org/packages/dirvish-badge.svg]
<https://stable.melpa.org/#/dirvish>

[file:https://github.com/alexluigit/dirvish/actions/workflows/melpazoid.yml/badge.svg]
<https://github.com/alexluigit/dirvish/actions/workflows/melpazoid.yml>
