                             _____________

                                HELM-EXT

                              Junpeng Qiu
                             _____________


Table of Contents
_________________

1 Skipping Dots
2 ZShell Like Path Expansion
3 Auto Path Expansion
4 Use Header Line for Minibuffer Completions
5 Other Tools
6 WARNING


Extensions to [helm], which I find useful but are unlikely to be
accepted in the upstream.

A collection of dirty hacks for helm!


[helm] https://github.com/emacs-helm/helm


1 Skipping Dots
===============

  When entering an *NON-EMPTY* directory using `helm-find-files', skip
  the first two entries, `.' and `..'. But if the directory is *EMPTY*,
  the selection remains unchanged (still at the position of `.').

  To enable it:
  ,----
  | (helm-ext-ff-enable-skipping-dots t)
  `----

  Demo (note that the selection skips the first two entries, `.' and
  `..' when the directory is non-empty): [./screencasts/skip-dots.gif]

  It is also possible to "hide" the first two entries by recentering the
  first line. Use the following code to enable such behavior:
  ,----
  | (setq helm-ext-ff-skipping-dots-recenter t)
  `----

  Demo: [./screencasts/skip-dots-recenter.gif]

  You can see from the demo that the first two entries are just visually
  "hiden". You can still use `C-p' to move the selection to them.


2 ZShell Like Path Expansion
============================

  This enables zsh-style path expansion in Helm. For example, type
  `/h/q/f/b' and then execute the persistent action, the pattern expands
  to `/home/qjp/foo/bar', `/home/qjp/foo1/bar1/' etc. Select the
  candidate using the helm interface.

  To enable it:
  ,----
  | (helm-ext-ff-enable-zsh-path-expansion t)
  `----

  Demo: [./screencasts/zsh-expansion.gif]

  Here is an [old blog] of mine dicussing about this feature. Note that
  now helm already has the ability to search the directory recursively
  using the `locate' command as the backend, which is quite different.
  For me, I prefer my own approach since it feels more consistent when I
  switch between `zsh' and `helm'.


[old blog]
http://cute-jumper.github.io/emacs/2015/11/17/let-helm-support-zshlike-path-expansion


3 Auto Path Expansion
=====================

  This feature is an improved version of the zsh-style path expansion.
  The expansion is performed /ON-THE-FLY/ as you're typing the pattern!

  To enable it:
  ,----
  | (helm-ext-ff-enable-auto-path-expansion t)
  `----

  (If you choose to enable this feature, then you don't need the
  previous zsh-path-expansion.)

  Demo: [./screencasts/auto-expansion.gif]

  To be improved: remove the restriction of only performing prefix
  matching in each level, making the matching behave more "fuzzily".


4 Use Header Line for Minibuffer Completions
============================================

  After enabling `helm-mode', hitting `TAB' in the minibuffer when using
  commands like `eval-expression' (`M-:') can also trigger the helm
  interface, but the problem is that the minibuffer is reused to enter
  the pattern so that we can't see the previous input in the minibuffer.
  So, instead of reusing the minibuffer to enter the pattern, use the
  header line to enter the pattern when the completion is triggered from
  the minibuffer.

  To enable it:
  ,----
  | (helm-ext-minibuffer-enable-header-line-maybe t)
  `----

  Demo: [./screencasts/minibuffer-header.gif]


5 Other Tools
=============

  [ace-jump-helm-line] can be used for quick navigation in the helm
  window, which uses [avy] behind the scenes. Helm itself also has a
  lightweight alternative called `helm-linum-relative-mode' (type `C-x
  number' to select a candidate).


[ace-jump-helm-line] https://github.com/cute-jumper/ace-jump-helm-line

[avy] https://github.com/abo-abo/avy


6 WARNING
=========

  *These are dirty hacks and it is highly likely that something may be
  BROKEN after the helm updates!*
