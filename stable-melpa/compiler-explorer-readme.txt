
; compiler-explorer.el

Package that provides a simple client for [compiler
explorer][compiler-explorer] service.


; Usage

M-x `compiler-explorer' is the main entry point.  It will ask you
for a language and display source&compilation buffers.  Type
something in the source buffer; the compilation buffer will
automatically update with compiled asm code.  Another buffer
displays output of the compiled and executed program.

M-x `compiler-explorer-set-compiler' changes the compiler for
current session.

M-x `compiler-explorer-set-compiler-args' sets compilation options.

M-x `compiler-explorer-add-library' asks for a library version and
adds it to current compilation.  M-x
`compiler-explorer-remove-library' removes them.

M-x `compiler-explorer-set-execution-args' sets the arguments for
the executed program.

M-x `compiler-explorer-set-input' reads a string from minibuffer
that will be used as input for the executed program.

M-x `compiler-explorer-new-session' kills the current session and
creates a new one, asking for source language.

M-x `compiler-explorer-previous-session' lets you cycle between
previous sessions.

M-x `compiler-explorer-make-link' generates a link for current
compilation so it can be opened in a browser and shared.

M-x `compiler-explorer-layout' cycles between different layouts.


[compiler-explorer]: https://godbolt.org/
