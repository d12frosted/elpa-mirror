This library provides the `trust-manager-mode' minor mode, which
helps you manage trusted directories with minimal configuration.
It is intended to streamline the management of `trusted-content',
added in Emacs 30 as a new security measure.

Just enable `trust-manager-mode' in your init file and you should
be good to go.  The mode focuses on per-project trust designation.
It asks you whether you trust a project the first time you visit a
file in that project, and remembers your choices across sessions.
Your trusted/untrusted projects are stored in the user option
`trust-manager-trust-alist'.  If you change your mind about some
project, just customize this user option; you can do so directly
or via the utility command `trust-manager-customize'.  You may also
customize `trust-manager-trust-alist' to designate some directories
as trusted or untrusted before actually visiting files in them.

Another utility command is `trust-manager-set-project-trust', which
lets you mark any project as trusted or untrusted, not necessarily
the current project.  The command `trust-manager-set-file-trust' is
similar, except that it supports arbitrary files/directories,
rather than just projects.

In addition, `trust-manager-mode' integrates with the command
`project-forget-project' such that when you "forget" a project,
its directory stops being trusted and its entry in
`trust-manager-trust-alist' is cleared.

`trust-manager-mode' also integrates with Dired: when the mode is
enabled, you can use C-c C-t in a Dired buffer to trust one or more
files/directories; similarly, C-c C-u can be used for untrusting.

By default, `trust-manager-mode' also adds a mode line indicator in
untrusted buffers where risky features may have been disabled.
The default indicator is a `?' shown in red.  You can click on the
indicator to mark the buffer as trusted (it runs the command
`trust-manager-trust-this-buffer', which you can run directly too).
You can also customize or disable this indicator via the
`trust-manager-untrusted-indicator' user option, and the face with
the same name.

Since only some features require trust, not every untrusted buffer
needs your attention, only those in which the lack of trust matters.
The user option `trust-manager-trust-indicator-buffer-condition'
controls in which untrusted buffers the indicator is shown.
By default it specifies only Emacs Lisp buffers, because several
Emacs Lisp editing features, including on-the-fly diagnostics,
require trust.

When `trust-manager-mode' marks a previously untrusted buffer as
trusted, e.g. when you click on the untrusted buffer mode line
indicator, it runs the hook `trust-manager-now-trusted-hook'.
By default, `trust-manager-mode' uses this hook to re-enable the
Emacs Lisp Flymake backend for on-the-fly diagnostics.

`trust-manager-mode' can also extend Emacs's trust system to secure
additional potentially risky features; the user option
`trust-manager-secure-additional-features' says which features
`trust-manager-mode' should hook into.  By default, this option is
set to integrate trust into Emacs's file-local variables feature,
such that file-specified modes and variable values are ignored in
untrusted buffers.