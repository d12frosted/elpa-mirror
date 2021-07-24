This is a convenient language bundle for the Emacs package `tree-sitter'. It
serves as an interim distribution mechanism, until `tree-sitter' is
widespread enough for language-specific major modes to incorporate its
functionalities.

For each supported language, this package provides:

1. Pre-compiled grammar binaries for 3 major platforms: macOS, Linux and
   Windows, on x86_64. In the future, `tree-sitter-langs' may provide tooling
   for major modes to do this on their own.

2. Optional highlighting patterns. This is mainly intended for major modes
   that are not aware of `tree-sitter'. A language major mode that wants to
   use `tree-sitter' for syntax highlighting should instead provide the query
   patterns on its own, using the mechanisms defined by `tree-sitter-hl'.

3. Optional query patterns for other minor modes that provide high-level
   functionalities on top of `tree-sitter', such as code folding, evil text
   objects... As with highlighting patterns, major modes that are directly
   aware of `tree-sitter' should provide the query patterns on their own.
