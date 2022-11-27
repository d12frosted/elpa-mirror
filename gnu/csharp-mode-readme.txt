Table of Contents
─────────────────

1. Development status of this mode
2. csharp-mode
.. 1. Main features
.. 2. tree-sitter support
..... 1. Using and evolving the tree-sitter functionality.
.. 3. Usage
3. Attribution
.. 1. New focus
4. ELPA
5. License


[file:https://github.com/emacs-csharp/csharp-mode/workflows/Build%20&%20Test/badge.svg?branch=master]
[file:https://melpa.org/packages/csharp-mode-badge.svg]
[file:https://stable.melpa.org/packages/csharp-mode-badge.svg]
[file:https://elpa.gnu.org/packages/csharp-mode.svg]


[file:https://github.com/emacs-csharp/csharp-mode/workflows/Build%20&%20Test/badge.svg?branch=master]
<https://github.com/emacs-csharp/csharp-mode/actions>

[file:https://melpa.org/packages/csharp-mode-badge.svg]
<https://melpa.org/#/csharp-mode>

[file:https://stable.melpa.org/packages/csharp-mode-badge.svg]
<https://stable.melpa.org/#/csharp-mode>

[file:https://elpa.gnu.org/packages/csharp-mode.svg]
<https://elpa.gnu.org/packages/csharp-mode.html>


1 Development status of this mode
═════════════════════════════════

  This mode is now strictly in maintenance mode.  That means that /no/
  new features will be added, and the mode itself will be moved into
  core.  Thus development of support for C# will continue in core Emacs.
  However, this repo will continue being available from (M)ELPA for some
  time for backwards compatibility.  If you are running Emacs 29 or
  larger you are advised to remove this package and rely on what's in
  core.  Bug reports should be directed to the Emacs bug tracker after
  Emacs 29 is released.


2 csharp-mode
═════════════

  This is a mode for editing C# in emacs. It's using CC mode or
  [tree-sitter] for highlighting and indentation.


[tree-sitter] <https://github.com/ubolonton/emacs-tree-sitter>

2.1 Main features
─────────────────

  • font-lock and indent of C# syntax including:
    • all c# keywords and major syntax
    • attributes that decorate methods, classes, fields, properties
    • enum types
    • #if/#endif #region/#endregion
    • instance initializers
    • anonymous functions and methods
    • verbatim literal strings (those that begin with @)
    • generics
  • intelligent insertion of matched pairs of curly braces.
  • compilation-mode support for msbuild, devenv and xbuild.


2.2 tree-sitter support
───────────────────────

  You can enable experimental tree sitter support for indentation and
  highlighting using
  ┌────
  │ (use-package tree-sitter :ensure t)
  │ (use-package tree-sitter-langs :ensure t)
  │ (use-package tree-sitter-indent :ensure t)
  │ 
  │ (use-package csharp-mode
  │   :ensure t
  │   :config
  │   (add-to-list 'auto-mode-alist '("\\.cs\\'" . csharp-tree-sitter-mode)))
  └────
  If you are using this, clearly state so if you find any issues.

  Note that we don't depend on tree-sitter yet, so you have to manually
  install the packages involved.  The simplest way is to use the
  provided snippet above.


2.2.1 Using and evolving the tree-sitter functionality.
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  `tree-sitter' introduces a minor mode called `tree-sitter-debug-mode'
  where you can look at the actual syntax tree it produces.  If and when
  you spot missing or wrong syntax highlighting, look at how the
  patterns are written in `csharp-tree-sitter-mode.el', then submit a pr
  with a couple new ones added.  When testing and debugging this, it is
  actually as simple as `M-x eval-buffer' on
  `csharp-tree-sitter-mode.el', then `M-x revert-buffer' in the file you
  are testing.  It should update and show the correct syntax
  highlighting.


  So the development cycle is:
  • Spot missing syntax highlighting
  • View AST with `tree-sitter-debug-mode'
  • Locate offending part
  • Add new pattern
  • `M-x eval-buffer' in `csharp-tree-sitter-mode.el'
  • `M-x revert-buffer' inside your `some-test-file.cs'


2.3 Usage
─────────

  This package is currently available on both ELPA and MELPA. Install
  using `M-x package-install<RET>csharp-mode'.

  Once installed the package should be automatically used for files with
  a '.cs'-extension.

  Note: This package is also available on [MELPA-stable] for those who
  don't want or need bleeding edge development-versions.

  For a better experience you may want to enable electric-pair-mode when
  editing C#-files.  To do so, add the following to your .emacs-file:

  ┌────
  │ (defun my-csharp-mode-hook ()
  │   ;; enable the stuff you want for C# here
  │   (electric-pair-mode 1)       ;; Emacs 24
  │   (electric-pair-local-mode 1) ;; Emacs 25
  │   )
  │ (add-hook 'csharp-mode-hook 'my-csharp-mode-hook)
  └────

  For further mode-specific customization, `M-x customize-group RET
  csharp RET' will show available settings with documentation.

  For more advanced and IDE-like functionality we recommend using
  csharp-mode together with [lsp-mode] or [eglot]


[MELPA-stable] <http://stable.melpa.org/>

[lsp-mode] <https://github.com/emacs-lsp/lsp-mode>

[eglot] <https://github.com/joaotavora/eglot>


3 Attribution
═════════════

  This repo was a fork of the code originally developed by Dylan
  R. E. Moonfire and further maintained by Dino Chiesa as hosted on
  [Google code].


[Google code] <https://code.google.com/p/csharpmode/>

3.1 New focus
─────────────

  The original csharp-mode repo contained lots of different code for
  lots of different purposes, some finished, some not, some
  experimental, some not. Basiaclly things like ASPX-mode, TFS-mode,
  code completion backends, etc.

  All this original code can still be found in the [extras-branch], but
  we have decided to go for a more focused approach and to throw out all
  dead or unused code, code we wont be maintaining.

  The goal: That what we package in csharp-mode actually works and works
  well.


[extras-branch] <https://github.com/josteink/csharp-mode/tree/extras>


4 ELPA
══════

  This package aims to stay as close to mainline emacs as it can.  As
  such, paperwork with the FSF is needed for contributions of
  significant size.


5 License
═════════

  The original project was licensed under [GPL v2+], but after a rewrite
  in September 2020, it was relicensed to GPLv3+


[GPL v2+] <https://www.gnu.org/licenses/gpl-2.0.html>
