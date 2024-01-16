


0.0.1 Version 0.3
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌


1 About
═══════

  Major mode for editing [Devicetree] files.

  Features:
  • Font Lock
  • Indent
  • IMenu


[Devicetree] <http://www.devicetree.org/>


2 Installation
══════════════

2.1 With guix
─────────────

  ┌────
  │ guix package -f guix.scm
  └────


2.2 From source
───────────────

  Clone this repo.
  ┌────
  │ (use-package graphql-ts-mode
  │   :ensure nil
  │   :load-path "PATH TO WHICH THE REPOSITORY WAS CLONED"
  │   :init
  │   (with-eval-after-load 'treesit
  │     (add-to-list 'treesit-language-source-alist
  │ 		 '(devicetree "https://github.com/joelspadin/tree-sitter-devicetree"))))
  └────
  This requires a working C compiler.


3 License
═════════

  GPLv3
