                     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      DOOM-GAME.EL - DOOM ON EMACS
                     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This is [DOOM] running inside Emacs via a native module. The port is
based on [doomgeneric] such that only a handful of functions like
`DG_DrawFrame' need to be [implemented in C] with some [Elisp code as
glue]. It uses the native Canvas API which is part of the Emacs 32
source tree, and also available for download as [patch] for Emacs
31. See further links and resources related to Canvas below.


[DOOM] <https://github.com/id-Software/DOOM>

[doomgeneric] <https://github.com/ozkl/doomgeneric>

[implemented in C] <file:doomgeneric_emacs.c>

[Elisp code as glue] <file:doom-game.el>

[patch] <https://github.com/minad/emacs-canvas-patch>


1 Running DOOM
══════════════

1.1 Prerequisites
─────────────────

  In order to run DOOM, you need an Emacs 32 with Canvas support. On
  Emacs 31 first apply the [Canvas patch] to the Emacs source and
  recompile Emacs.

  Furthermore DOOM data files are needed. These files have the extension
  `*.wad'. On Debian you can for example install the packages
  [doom-wad-shareware] (original `doom1.wad') or [freedoom]
  (`freedoom1.wad'). On other distributions install the equivalent
  packages or download the files from the Debian website and extract the
  respective WAD files.

  The WAD files need to be placed in the current directory where Emacs
  is started or in the directory `/usr/share/games/doom/'. Furthermore a
  custom path to the wad file can be specified via the customization
  option `doom-args'.


[Canvas patch] <https://github.com/minad/emacs-canvas-patch>

[doom-wad-shareware]
<https://packages.debian.org/stable/doom-wad-shareware>

[freedoom] <https://packages.debian.org/stable/freedoom>


1.2 Installing as package
─────────────────────────

  Install via `M-x package-install RET doom-game RET' from [ELPA]. After
  the installation, invoke `M-x doom'. Compilation output and error
  messages will appear in the ephemeral `_*doom-log*' buffer.


[ELPA] <https://elpa.nongnu.org/nongnu/doom-game.html>


1.3 Running from source
───────────────────────

  Clone this repository and execute the command `make'. This will
  download the DOOM source, compile the native Emacs module, and then
  start DOOM in `emacs -Q'. Error messages will appear in the ephemeral
  `_*doom-log*' buffer.


2 Canvas links
══════════════

  • [bug#80281]
  • [doom-on-emacs]
  • [emacs-canvas-patch]
  • [emacs-shader-demo]
  • [Pale and other demos]


[bug#80281] <https://debbugs.gnu.org/cgi/bugreport.cgi?bug=80281>

[doom-on-emacs] <https://github.com/minad/doom-on-emacs>

[emacs-canvas-patch] <https://github.com/minad/emacs-canvas-patch>

[emacs-shader-demo] <https://github.com/minad/emacs-shader-demo>

[Pale and other demos]
<https://tusharhero.codeberg.page/emacs-pale-canvas-and-stuff-demos.html>
