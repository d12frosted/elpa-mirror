On-the-fly syntax checking for GNU Emacs 24.

Flycheck is a modern on-the-fly syntax checking extension for GNU Emacs,
intended as replacement for the older Flymake extension which is part of GNU
Emacs.

Flycheck automatically checks buffers for errors while you type, and reports
warnings and errors directly in the buffer and in an optional IDE-like error
list.

It comes with a rich interface for custom syntax checkers and other
extensions, and has already many 3rd party extensions adding new features.

Please read the online manual at http://www.flycheck.org for more
information.  You can open the manual directly from Emacs with `M-x
flycheck-manual'.

# Setup

Flycheck works best on Unix systems.  It does not officially support Windows,
but tries to maintain Windows compatibility and should generally work fine on
Windows, too.

To enable Flycheck add the following to your init file:

   (add-hook 'after-init-hook #'global-flycheck-mode)

Flycheck will then automatically check buffers in supported languages, as
long as all necessary tools are present.  Use `flycheck-verify-setup' to
troubleshoot your Flycheck setup.
