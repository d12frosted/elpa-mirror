f90-ts-mode is a major mode for editing Fortran 90/2003 (and newer) source
files, based on Emacs's built-in tree-sitter support (requires Emacs 30+)

Recently changed, added or improved:
  [09-2026] Tested with Emacs 31.1 and tree-sitter 0.26.

  [08-2026] `f90-ts-shift-line-break' as combined break/join function added.
  [08-2026] Defcustom `f90-ts-font-lock-error` replaced by
            `f90-ts-font-lock-error-show'.  Errors are now always fontified
            by `f90-ts-font-lock-error-face'.  The new defcustom
            `f90-ts-font-lock-error-show' can be used to turn ERROR node
            highlighting on and off, or the number of lines to be highlighted
            for each ERROR node.
  [08-2026] Jump-to-rightmost-position (within fill-column) to the
            interactive fill operation added.
  [08-2026] Mark region operations fixed: always consider trimmed region
            of nodes.  Some nodes like a whole "subroutine..end subroutine"
            block contains a trailing newline, which should not be
            considered.  Not consequently trimming all spans broke some mark
            region operations.
  [08-2026] About, README and MANUAL entries in the fortran and transient
            popup menu to view information about the mode added.
  [08-2026] Additional font-locking for error regions added.  This can be
            customized by `f90-ts-font-lock-error' and
            `f90-ts-font-lock-error-face'.
  [08-2026] Smart end completion of coarray "change team ... end team"
            blocks fixed.  It was wrongly assumed that the end statement is
            "end change team".

  [07-2026] Inherit attribute of some font lock faces fixed.
  [07-2026] Alignment of unary expressions with leading minus or plus
            improved.

Features:
  - Almost all statements up to F2023
  - Syntax highlighting, including syntactically incorrect code
  - Indentation of lines, regions, multiline statements and structure blocks
  - Alignment for multiline statements with rotation and other options
  - Smart end completion
  - Configurable leading ampersand and statement label positions
  - Breaking and joining of continued lines
  - Filling and rebalancing of lines or regions (with rightmost breakpoint
    selection or interactive break and join session)
  - (Un)commenting regions with configurable prefixes and indentation rules
  - Special comments like doc strings and separators
    (syntax highlighting and indentation options)
  - Keyword highlighting in comments (like TODO, Remark etc.)
  - OpenMP and preprocessor directives
  - Coarray keywords and statements
  - Region selection based on tree-sitter nodes
  - Imenu and a Fortran menu in the menu bar
  - Navigation (defun, things, Xref, side panel tree)

Features can be found by the fortran menu or a transient popup bound
to the key C-c C-f.

Installation requires the tree-sitter Fortran grammar, which can be found at
  https://github.com/stadelmanma/tree-sitter-fortran

Basic setup with use-package:

  (use-package f90-ts-mode
    :mode ("\\.f90\\'" . f90-ts-mode))

See the README and MANUAL at https://github.com/mscfd/emacs-f90-ts-mode
for full documentation on options, keybindings, etc.

Bugs and features:
  https://github.com/mscfd/emacs-f90-ts-mode/issues

Note: Emacs 30.x must be linked against tree-sitter 0.25.x at runtime.
Emacs 31 supports 0.26. The mode runs in both configurations.
For details see MANUAL at https://github.com/mscfd/emacs-f90-ts-mode
