# Beframe (beframe.el) for GNU Emacs

Isolate buffers per frame, else "beframe" them.

`beframe` enables a frame-oriented Emacs workflow where each frame has
access to the list of buffers visited therein.  In the interest of
brevity, we call buffers that belong to frames "beframed".  Beframing
is achieved in two main ways:

1. By calling the command `beframe-switch-buffer`.  It is like the
   standard `switch-to-buffer` except the list of candidates is
   limited to those that the current frame knows about.

2. By enabling the global minor mode `beframe-mode`.  It sets the
   `read-buffer-function` to one that filters buffers per frame.  As
   such, commands like `switch-to-buffer`, `next-buffer`, and
   `previous-buffer` automatically work in a beframed way.

+ Package name (GNU ELPA): `beframe`
+ Official manual: <https://protesilaos.com/emacs/beframe>
+ Git repo on SourceHut: <https://git.sr.ht/~protesilaos/beframe>
  - Mirrors:
    + GitHub: <https://github.com/protesilaos/beframe>
    + GitLab: <https://gitlab.com/protesilaos/beframe>
+ Mailing list: <https://lists.sr.ht/~protesilaos/general-issues>
+ Backronym: Buffers Encapsulated in Frames Realise Advanced
  Management of Emacs.
