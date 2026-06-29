evil-visualstar
===============

This is a port of one of the many visual-star plugins for Vim to work with [evil-mode](https://bitbucket.org/lyro/evil/wiki/Home).

installation
============

Install `evil-visualstar` from [MELPA][1].

usage
=====

Add `(global-evil-visualstar-mode)` to your configuration.

Make a visual selection with `v` or `V`, and then hit `*` to search that selection forward, or `#` to search that selection backward.

If the `evil-visualstar/persistent` option is not nil, visual-state will
remain in effect, allowing for repeated `*` or `#`.

Note that you than have to exit visualstar-mode before hitting a
direction key to avoid extending the selection.

[1]: http://melpa.org
