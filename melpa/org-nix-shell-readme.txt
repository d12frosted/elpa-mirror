
Use a buffer-local nix-shell environment in org-babel src blocks.

Basic Usage:

First create a nix shell derivation in a named src block.

#+name: nix-shell
#+begin_src nix
  { pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    buildInputs = [
      pkgs.hello
    ];
  }
#+end_src

We run source blocks with the shell using a special :nix-shell header argument.

#+begin_src sh :nix-shell "nix-shell"
hello
#+end_src

Then, if `org-nix-shell-mode' is enabled, the shell environment is seamlessly loaded
when executing a src block or exporting.

The :nix-shell header argument is like any other org-mode header argument and can be
configured with:

       #+PROPERTY: header-args :nix-shell "nix-shell"

   or in a property drawer like:

       * Org Header
       :PROPERTIES:
       :header-args: :nix-shell "nix-shell"
       :END:

See `demo.org' for more.

