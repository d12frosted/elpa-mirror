   A major mode for editing Extempore code. See the Extempore
   project page at http://github.com/digego/extempore for more
   details.

 Installation

   Available through MELPA:

   M-x `package-install' RET `extempore-mode' RET

   If you don't want to get it from MELPA, just download the file and
   use `package-install-file'

   (package-install-file "/path/to/extempore-mode.el")


 Configuration

   (optional) if you don't want to have to answer the "directory" prompt
   every time you call `extempore-run', you can set the `extempore-path'
   variable (either in your init file or through the customisation interface)

   (setq extempore-path "/path/to/extempore/")


 Usage

   The most important commands are

     M-x `extempore-connect' (C-c C-j)

     Connect the current extempore-mode buffer to a running
     Extempore process - this is necessary to begin sending code
     for evaluation. An Extempore process may have multiple
     connected buffers, and each buffer can be connected to
     multiple Extempore processes. If called with a prefix arg,
     disconnect current buffer.

     M-x `switch-to-extempore' (C-c C-z)

     Switch to the Extempore process buffer running in Emacs. If
     not currently running, prompt to start one.

     M-x `extempore-send-definition' (C-c C-c, C-M-x)

     Send the Extempore form under point (or a whole region, if
     region is active) to all Extempore processes connected to the
     current buffer.

     M-x `extempore-repl' (C-c C-c, C-M-x)

     Create an Extempore REPL buffer.

 History

   Adapted from: scheme.el by Bill Rozas and Dave Love
   Also includes some work done by Hector Levesque and Andrew Sorensen

 Caveats

   extempore-mode requires Emacs 24, because it inherits from
   prog-mode (via lisp-mode)
