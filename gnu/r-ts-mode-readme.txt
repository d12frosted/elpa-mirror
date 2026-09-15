1 R Tree Sitter Mode for Emacs
══════════════════════════════

  Version 1.2.0

  [file:https://melpa.org/packages/r-ts-mode-badge.svg]

  The code for this package has been extracted from the original [ESR]
  repository, which has been migrated to a new location under the
  Codeberg organization [R for Emacs], created to promote Emacs packages
  for R. Read more at the end of this readme.


[file:https://melpa.org/packages/r-ts-mode-badge.svg]
<https://melpa.org/#/r-ts-mode>

[ESR] <https://codeberg.org/teoten/esr>

[R for Emacs] <https://codeberg.org/R-for-emacs>


2 Dependencies
══════════════

  The most important requirement is to have Emacs built with treesitter
  support. You can find details on how to compile Emacs on the [Official
  Documentation], although we recommend checking the article from
  [mastering emacs].

  Then you need to add the language grammar for R. The options are:

  • Compile with [treesitter functionality] from the git repository of
    [tresitter.r].
  • Download the grammars for your system from [tree-sitter-langs] and
    copy the R grammar to `~/.emacs.d/tree-sitter/' and rename it as
    `libtree-sitter-r.extension'.
  • Install the R package [treesitter.r] and call the function
    `r-ts-mode-prepare-binaries-from-r-library' to move the binaries to
    `.emacs.d' directory (supported only for Windows and Linux, feel
    free to test in Mac OS and help us include it).

  For the last option you need to load the module `r-ts-setup'. See more
  details in the [Usage] section.


[Official Documentation]
<https://www.gnu.org/software/emacs/manual/html_node/efaq/Compiling-and-installing-Emacs.html>

[mastering emacs]
<https://www.masteringemacs.org/article/how-to-get-started-tree-sitter>

[treesitter functionality]
<https://www.gnu.org/software/emacs/manual/html_node/elisp/Language-Grammar.html>

[tresitter.r] <https://github.com/r-lib/tree-sitter-r>

[tree-sitter-langs]
<https://github.com/emacs-tree-sitter/tree-sitter-langs/releases>

[treesitter.r]
<https://cran.r-project.org/web/packages/treesitter.r/index.html>

[Usage] See section 3


3 Usage
═══════

3.1 R source code
─────────────────

  After installing the package and making sure the R tree-sitter grammar
  is available, open an `.R' file and enable `r-ts-mode':

  ┌────
  │ (require 'r-ts-mode)
  │ (add-to-list 'auto-mode-alist '("\\.R\\'" . r-ts-mode))
  └────

  `r-ts-mode' provides tree-sitter based syntax highlighting,
  indentation, imenu support, and navigation for R source files.

  If the R grammar is not installed yet, you can copy the parser binary
  from the `treesitter.r' R package into Emacs’ tree-sitter directory:

  ┌────
  │ (require 'r-ts-mode)
  │ (r-ts-mode-prepare-binaries-from-r-library "R")
  └────


3.2 Use as a tree sitter mode for ESS
─────────────────────────────────────

  Set the variable `r-ts-mode-inherit-ess' to true and start using
  treesitter with ESS by calling `r-ts-mode' from R buffers. It is
  important to set this variable before `r-ts-mode' is loaded. With
  `straight' you can add it to the `:init' section. With default Emacs
  you can use `with-eval-after-load'. Here is an example:

  ┌────
  │ (with-eval-after-load 'treesit
  │   (when (treesit-language-available-p 'r)
  │     (with-eval-after-load 'r-ts-mode
  │       (setq r-ts-mode-inherit-ess t)
  │       (push '(ess-r-mode . r-ts-mode) major-mode-remap-alist))))
  └────


3.3 Roxygen
───────────

  Roxygen support is provided through `r-ts-roxygen-mode'. It provides
  syntax highlighting and CAPF for Roxygen tags.

  From version 1.1.3, `r-ts-roxygen-mode' is not automatically loaded by
  default. The module is provided as part of the package, but it has to
  be loaded explicitly.

  ┌────
  │ ;; Load Roxygen support after r-ts-mode
  │ (with-eval-after-load
  │     'r-ts-mode
  │   (require 'r-ts-roxygen)
  │   (add-hook 'r-ts-mode-hook #'r-ts-roxygen-mode))
  └────


3.4 Preparing the grammar from R package
────────────────────────────────────────

  As mentioned in the [Dependencies] section, there are 3 main known
  strategies to install the grammars. If you have installed the R
  package [treesitter.r] you can use
  `r-ts-mode-prepare-binaries-from-r-library'. You need to load the
  module `r-ts-setup' first, and then you can call the function
  interactively (e.g., `M-x r-ts-mode-prepare-binaries-from-r-library').

  ┌────
  │ ;; Loading r-ts-setup module
  │ (require 'r-ts-setup)
  │ 
  │ ;; Then evaluate the function, or call it interactively
  │ (r-ts-mode-prepare-binaries-from-r-library)
  └────


[Dependencies] See section 2

[treesitter.r]
<https://cran.r-project.org/web/packages/treesitter.r/index.html>


4 Original code and R for Emacs
═══════════════════════════════

4.1 ESR
───────

  `r-ts-mode' started following the logic of ESS in which a major mode
  not only sets the rules for the language, but also defines interaction
  with the R console, CAPF, xref, linters and more. Soon I came to
  realize that this is not the right model and decided to change it. At
  first, everything was kept in ESR, but the code related to tree sitter
  was segregated into a different module. However, the major mode was
  still receiving too much responsibility and the name, `r-ts-mode' was
  not exactly just a tree sitter major mode for R. Therefore, I took the
  decision to separate it completely into its own package that
  specializes Emacs for editing R code, while the rest of the
  functionality should be delegated to ESR via minor mode(s).

  The idea of having it as a separated package was in my head almost
  since the creation of ESR, mainly because I wanted to have an
  `r-ts-mode' that could be easily shared and used without the rest of
  ESR, something that ESS has never offered. Having it as part of ESR
  would force the users who only want to benefit from the tree sitter
  parser, to install a complete package that they might not
  need. Additionally to that, I received a few comments about trying to
  make `r-ts-mode' part of core Emacs, something that cannot be possible
  as long as it was part of ESR.


4.1.1 Main changes
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The philosophy following the separation from ESR is that only the file
  `r-ts-mode.el' is necessary for the major mode. And it deals with tree
  sitter related functionality only. Therefore, functionality for
  Roxygen documentation and for setting up the grammar from the R
  library have been moved to separated modules, none of which is
  automatically loaded. See more details in the [Usage] section.

  Aside of that, regular maintenance has been given: some refactoring
  into a more functional programming approach, inclusion of the first
  file for unit test, and other preparation to be submitted to MELPA and
  ELPA.


[Usage] See section 3


4.2 R for Emacs
───────────────

  [R-for-emacs] is a new Codeberg Organization to act as a collection of
  packages and information for the use of R in Emacs. Currently it
  contains only 3 packages, but the plan is to grow it into a full
  ecosystem, not only of packages and functionality, but also resources
  and information specific to the use of R on Emacs.


[R-for-emacs] <https://codeberg.org/R-for-emacs/>
