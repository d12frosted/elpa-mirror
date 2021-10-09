Lets you auto-format source code in many languages using the same
command for all languages, instead of learning a different Emacs
package and formatting command for each language.

Just do M-x format-all-buffer and it will try its best to do the
right thing.  To auto-format code on save, use the minor mode
format-all-mode.  Please see the documentation for that function
for instructions.

Supported languages:

- Angular/Vue (prettier)
- Assembly (asmfmt)
- ATS (atsfmt)
- Awk (gawk)
- Bazel Starlark (buildifier)
- BibTeX (Emacs)
- C/C++/Objective-C (clang-format, astyle)
- C# (clang-format, astyle)
- Cabal (cabal-fmt)
- Clojure/ClojureScript (node-cljfmt)
- CMake (cmake-format)
- Crystal (crystal tool format)
- CSS/Less/SCSS (prettier)
- Cuda (clang-format)
- D (dfmt)
- Dart (dartfmt, dart-format)
- Dhall (dhall format)
- Dockerfile (dockfmt)
- Elixir (mix format)
- Elm (elm-format)
- Emacs Lisp (Emacs)
- F# (fantomas)
- Fish Shell (fish_indent)
- Fortran Free Form (fprettify)
- Gleam (gleam format)
- GLSL (clang-format)
- Go (gofmt, goimports)
- GraphQL (prettier)
- Haskell (brittany, fourmolu, hindent, ormolu, stylish-haskell)
- HTML/XHTML/XML (tidy)
- Java (clang-format, astyle)
- JavaScript/JSON/JSX (prettier, standard)
- Jsonnet (jsonnetfmt)
- Kotlin (ktlint)
- LaTeX (latexindent, auctex)
- Ledger (ledger-mode)
- Lua (lua-fmt, prettier plugin)
- Markdown (prettier)
- Nix (nixpkgs-fmt, nixfmt)
- OCaml (ocp-indent)
- Perl (perltidy)
- PHP (prettier plugin)
- Protocol Buffers (clang-format)
- PureScript (purty, purs-tidy)
- Python (black, yapf)
- R (styler)
- Racket (raco-fmt)
- Reason (bsrefmt)
- ReScript (rescript)
- Ruby (rubocop, rufo, standardrb)
- Rust (rustfmt)
- Scala (scalafmt)
- Shell script (beautysh, shfmt)
- Snakemake (snakefmt)
- Solidity (prettier plugin)
- SQL (pgformatter, sqlformat)
- Svelte (prettier plugin)
- Swift (swiftformat)
- Terraform (terraform fmt)
- TOML (prettier plugin)
- TypeScript/TSX (prettier)
- V (v fmt)
- Verilog (iStyle)
- YAML (prettier)

You will need to install external programs to do the formatting.
If `format-all-buffer` can't find the right program, it will try to
tell you how to install it.

Many of the external formatters support configuration files in the
source code directory to control their formatting.  Please see the
documentation for each formatter.

New external formatters can be added easily if they can read code
from standard input and format it to standard output.  Feel free to
submit a pull request or ask for help in GitHub issues.
