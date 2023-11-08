Lets you auto-format source code in many languages using the same
command for all languages, instead of learning a different Emacs
package and formatting command for each language.

Just do M-x format-all-buffer and it will try its best to do the
right thing.  To auto-format code on save, use the minor mode
format-all-mode.  Please see the documentation for that function
for instructions.

Supported languages:

- Angular (prettier)
- Assembly (asmfmt)
- ATS (atsfmt)
- Awk (gawk)
- Bazel Starlark (buildifier)
- Beancount (bean-format)
- BibTeX (Emacs)
- C/C++/Objective-C (clang-format, astyle)
- C# (clang-format, astyle, csharpier)
- Cabal (cabal-fmt)
- Caddyfile (caddy fmt)
- Clojure/ClojureScript (zprint, node-cljfmt)
- CMake (cmake-format)
- Crystal (crystal tool format)
- CSS/Less/SCSS (prettier, prettierd)
- Cuda (clang-format)
- D (dfmt)
- Dart (dartfmt, dart-format)
- Dhall (dhall format)
- Dockerfile (dockfmt)
- Elixir (mix format)
- Elm (elm-format)
- Emacs Lisp (Emacs)
- Erb (erb-format)
- Erlang (efmt)
- F# (fantomas)
- Fish Shell (fish_indent)
- Fortran Free Form (fprettify)
- Gleam (gleam format)
- GLSL (clang-format)
- Go (gofmt, goimports)
- GraphQL (prettier, prettierd)
- Haskell (brittany, fourmolu, hindent, ormolu, stylish-haskell)
- HCL (hclfmt)
- HTML/XHTML/XML (tidy)
- Hy (Emacs)
- Java (clang-format, astyle)
- JavaScript/JSON/JSX (prettier, standard, prettierd, deno)
- Jsonnet (jsonnetfmt)
- Kotlin (ktlint)
- LaTeX (latexindent, auctex)
- Ledger (ledger-mode)
- Lua (lua-fmt, stylua, prettier plugin)
- Markdown (prettier, prettierd, deno)
- Meson (muon fmt)
- Nginx (nginxfmt)
- Nix (nixpkgs-fmt, nixfmt, alejandra)
- OCaml (ocp-indent, ocamlformat)
- Perl (perltidy)
- PHP (prettier plugin)
- Protocol Buffers (clang-format)
- PureScript (purty, purs-tidy)
- Python (black, isort, ruff format, yapf)
- R (styler)
- Racket (raco-fmt)
- Reason (bsrefmt)
- ReScript (rescript)
- Ruby (rubocop, rufo, standardrb, stree)
- Rust (rustfmt)
- Scala (scalafmt)
- Shell script (beautysh, shfmt)
- Snakemake (snakefmt)
- Solidity (prettier plugin)
- SQL (pgformatter, sqlformat)
- Svelte (prettier plugin)
- Swift (swiftformat)
- Terraform (terraform fmt)
- TOML (prettier plugin, taplo fmt)
- TypeScript/TSX (prettier, ts-standard, prettierd, deno)
- V (v fmt)
- Vue (prettier, prettierd)
- Verilog (iStyle, Verible)
- YAML (prettier, prettierd)
- Zig (zig)

You will need to install external programs to do the formatting.
If `format-all-buffer` can't find the right program, it will try to
tell you how to install it.

Many of the external formatters support configuration files in the
source code directory to control their formatting.  Please see the
documentation for each formatter.

New external formatters can be added easily if they can read code
from standard input and format it to standard output.  Feel free to
submit a pull request or ask for help in GitHub issues.
