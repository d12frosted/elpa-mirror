RMSBolt is a package to provide assembly or bytecode output for a source
code input file.

It currently supports: C/C++, OCaml, Haskell, Python, Java, Go, PHP, D,
Pony, Zig, Swift, Emacs Lisp, and (limited) Common Lisp.

Adding support for more languages, if they have an easy manual compilation
path from source->assembly/bytecode with debug information, should be much
easier than in other alternatives.

It's able to do this by:
1. Compiling changes automatically, adding options which cause the compiler
to output assembly/bytecode with debug information (or by using objdump)
2. Parse assembly/bytecode to create a map from it to the original source
3. Strip out unneeded information from bytecode to only show useful code
4. Provide an interface for highlighting the matched assembly/bytecode line
to the source and vice versa

Tweakables:
RMSBolt is primarily configured with Emacs local variables. This lets you
change compiler and rmsbolt options simply by editing a local variable block.

Notable options:
`rmsbolt-command': determines the prefix of the compilation command to use.
`rmsbolt-default-directory': determines the default-drectory to compile from.
`rmsbolt-disassemble': disassemble from a compiled binary with objdump, if supported.
`rmsbolt-filter-*': Tweak filtering of binary output.
`rmsbolt-asm-format': Choose between intel att, and other syntax if supported.
`rmsbolt-demangle': Demangle the output, if supported.

For more advanced configuration (to the point where you can override almost
all of RMSbolt yourself), you can set `rmsbolt-language-descriptor' with a
replacement language spec.

Please see the readme at https://gitlab.com/jgkamat/rmsbolt for
more information!

Thanks:
Inspiration and some assembly parsing logic was adapted from Matt Godbolt's
compiler-explorer: https://github.com/mattgodbolt/compiler-explorer and
Jonas Konrad's javap: https://github.com/yawkat/javap.
