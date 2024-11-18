The **compile-angel** package automatically byte-compiles and native-compiles
Emacs Lisp libraries. It offers:
- (compile-angel-on-load-mode): Global mode that compiles .el files before
  they are loaded.
- (compile-angel-on-save-local-mode): Local mode that compiles .el files
  whenever the user saves them.

These modes **speed up Emacs by ensuring all libraries are byte-compiled and
native-compiled**. Byte-compilation reduces the overhead of loading Emacs
Lisp code at runtime, while native compilation optimizes performance by
generating machine code specific to your system.

The author used to be an auto-compile user, but several of his .el files were
not being compiled by auto-compile, which caused Emacs to become slow due to
the lack of native compilation. The author experimented for an extended
period and the result of those hours of research and testing became a package
called compile-angel.
