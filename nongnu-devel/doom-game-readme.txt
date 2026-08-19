                            ━━━━━━━━━━━━━━━
                             DOOM ON EMACS
                            ━━━━━━━━━━━━━━━


This is [DOOM] running inside Emacs via a native module. The port is
based on [doomgeneric] such that only a handful of functions like
`DG_DrawFrame' need to be [implemented in C] with some [Elisp code as
glue]. It uses the native Canvas API which is part of the Emacs 32
source tree, and also available for download as [patch] for Emacs
31. See further Canvas links below.


[DOOM] <https://github.com/id-Software/DOOM>

[doomgeneric] <https://github.com/ozkl/doomgeneric>

[implemented in C] <file:doomgeneric_emacs.c>

[Elisp code as glue] <file:doom-game.el>

[patch] <https://github.com/minad/emacs-canvas-patch>


1 Running DOOM
══════════════

  In order to run DOOM, you need an Emacs 32 with Canvas support. On
  Emacs 31 first apply the Canvas patch to the Emacs source and
  recompile Emacs. Then execute `make' to download the DOOM source,
  compile the native Emacs module and start DOOM in Emacs. You will need
  a WAD file which contains the game data. The file `doom1.wad' is
  freely available. Error messages will appear in the `*doom-log*'
  buffer.


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
