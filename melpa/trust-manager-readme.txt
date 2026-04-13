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

By default, `trust-manager-mode' also adds a mode line indicator in
untrusted buffers where risky features may have been disabled.
The default indicator is a `?' shown in red.  You can customize or
disable this indicator via the `trust-manager-untrusted-indicator'
user option, and the face with the same name.
Since only some features require trust, not every untrusted buffer
needs your attention, only those in which the lack of trust matters.
The user option `trust-manager-trust-indicator-buffer-condition'
controls in which untrusted buffers indicator is shown.  By default
it specifies only Emacs Lisp buffers, because several Emacs Lisp
editing features, including on-the-fly diagnostics, require trust.
