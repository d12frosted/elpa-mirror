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
- Bazel Starlark (buildifier)
- BibTeX (emacs)
- C/C++/Objective-C (clang-format)
- Cabal (cabal-fmt)
- Clojure/ClojureScript (node-cljfmt)
- CMake (cmake-format)
- Crystal (crystal tool format)
- CSS/Less/SCSS (prettier)
- D (dfmt)
- Dart (dartfmt)
- Dhall (dhall format)
- Dockerfile (dockfmt)
- Elixir (mix format)
- Elm (elm-format)
- Emacs Lisp (emacs)
- Fish Shell (fish_indent)
- Fortran 90 (fprettify)
- Gleam (gleam format)
- Go (gofmt)
- GraphQL (prettier)
- Haskell (brittany, hindent, stylish-haskell)
- HTML/XHTML/XML (tidy)
- Java (clang-format)
- JavaScript/JSON/JSX (prettier, standard)
- Jsonnet (jsonnetfmt)
- Kotlin (ktlint)
- LaTeX (latexindent)
- Ledger (ledger-mode)
- Lua (lua-fmt, prettier plugin-lua)
- Markdown (prettier)
- Nix (nixfmt)
- OCaml (ocp-indent)
- Perl (perltidy)
- PHP (prettier plugin-php)
- Protocol Buffers (clang-format)
- PureScript (purty)
- Python (black, yapf)
- R (styler)
- Reason (bsrefmt)
- Ruby (rufo)
- Rust (rustfmt)
- Scala (scalafmt)
- Shell script (beautysh, shfmt)
- Snakemake (snakefmt)
- Solidity (prettier prettier-plugin-solidity)
- SQL (pgformatter, sqlformat)
- Swift (swiftformat)
- Terraform (terraform fmt)
- TOML (prettier prettier-plugin-toml)
- TypeScript/TSX (prettier)
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
