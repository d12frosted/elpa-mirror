This package makes Emacs VC operations fast(er).

The Vc-Defer package aims to make Emacs faster by deferring
non-essential work related to Emacs' built in "VC" mode, with a
minimum negative impact.  In particular, all VC commands should
still work normally when invoked explicitly, even in buffers that
Emacs has not yet determined the VC state for.

Usage is simple: require the package, configure the list of
problematic backends (there are no defaults), and enable
`vc-defer-mode' (a global mode).  For example:

  (require 'vc-defer)
  (add-to-list 'vc-defer-backends 'Hg)
  (vc-defer-mode)

...or a similar use-package incantation:

  (use-package vc-defer
    :config
    (add-to-list 'vc-defer-backends 'Hg)
    (vc-defer-mode))

The `vc-defer' customization group used for a similar effect.

Regardless of the configuration approach, when `vc-defer-mode' is
on, opening files no longer enables VC mode for the set of
configured backends.  Instead, the per-file status in those
backends are determined on a deferred, as needed, basis.  The VC
status will no longer be displayed in the mode line (at least,
until the first VC command is issued), but basic operations like
`find-file' will be fast.  Emacs will still be slow when VC
functionality is actually used, but at that point the performance
issue will make more sense to the user.

; Background

Emacs' built in VC implementation slows Emacs down.  This is most
evident when the VC backend is slow.  The code refreshes
information displayed in the mode line synchronously whenever a
file is loaded.  The rest of the VC subsystem is designed with this
assumption; there is no support for deferring this work until the
user explicitly invokes a command actually requires the status.

Evidence that users find this annoying is easy to find.

A thread in r/emacs on Reddit claimed that disabling VC mode was
"The biggest performance improvement to Emacs I've made in years":
http://redd.it/4c0mi3, and it amounts to:

  (remove-hook 'find-file-hooks 'vc-find-file-hook)

This hack, however totally disables VC mode for the affected files.
For example, later invoking "M-x vc-diff" results in an error.

VC has a few supported ways of disabling itself, which are
preferable to the above.  Customizing the `vc-ignore-dir-regexp'
variable can be used to disable it on a directory basis, and
customizing the `vc-handled-backends' variable can be used to
disable some or all backends entirely.  Neither approach is
satisfactory if the user still wants to use VC commands!

There are other threads.  "Git slows Emacs to Death" at
https://stackoverflow.com/questions/6724471/git-slows-down-emacs-to-death-how-to-fix-this
and its companion piece "Mercurial slows Emacs to Death" at
https://stackoverflow.com/questions/17323841/mercurial-slows-emacs-to-death-when-opening-saving-files.
In each case, I find it telling that the user(s) did not find it
easy to diagnose and mitigate the performance issues for
themselves, which suggests that Emacs could do better here.  There
may be some hope to fix this problem in Emacs itself.  See
https://lists.gnu.org/archive/html/emacs-devel/2016-02/msg00440.html.

Until then, this little hack can ease the pain.
