                           ━━━━━━━━━━━━━━━━━
                            KEYMAP-POPUP.EL
                           ━━━━━━━━━━━━━━━━━


A macro that defines a keymap with embedded descriptions and a popup to
display them.

`One definition, two uses: direct key dispatch and interactive menu.'

Unlike `transient', the result is a real keymap built on stock Emacs
primitives (`defvar-keymap', `set-transient-map', `menu-item' filters):
`where-is', `describe-bindings', `keymap-set', and normal keymap
composition all work without special-casing.  Plain data end-to-end – no
EIEIO, no parallel command registry.  Sub-prefix state and infix
arguments are deliberately out of scope; for those, use transient.


1 Installation
══════════════

  Requires Emacs 29.1+.  No external dependencies.

  ┌────
  │ (add-to-list 'load-path "/path/to/keymap-popup")
  │ (require 'keymap-popup)
  └────

  Or with `use-package':

  ┌────
  │ (use-package keymap-popup
  │   :ensure t)
  └────


2 Quick start
═════════════

  ┌────
  │ (keymap-popup-define my-commands-map
  │   "My commands."
  │   :group "Edit"
  │   "c" ("Comment" comment-dwim)
  │   "r" ("Rename" rename-file)
  │   :group "View"
  │   "g" ("Refresh" revert-buffer)
  │   "q" ("Quit" quit-window))
  │ 
  │ ;; Use as a normal keymap:
  │ (keymap-set some-mode-map "C-c m" my-commands-map)
  │ 
  │ ;; Or show the popup directly:
  │ (keymap-popup my-commands-map)
  └────

  Press `h' in the keymap to open the popup. Press `q' to dismiss.


3 Features
══════════

  • `:switch' – buffer-local toggle with `[on]/[off]' display
  • `:keymap' – sub-menu with stack navigation (`q' / `C-g' pops back)
  • `:stay-open' – command executes without dismissing the popup
  • `:inapt-if' – grays out and blocks entries based on a predicate
  • `:c-u' – prefix argument mode (`C-u' highlights eligible entries)
  • `:if' – conditionally hide entries
  • `:group' / `:row' – column layout
  • Dynamic descriptions via lambdas
  • `keymap-popup-annotate' – add popup descriptions to existing keymaps
  • `keymap-popup-attach' – attach descriptions built from runtime data


4 Documentation
═══════════════

  Full usage – special bindings, sub-menus, annotating keymaps like
  `dired-mode-map', display backends, customization – lives in the [user
  manual], also available as an Info manual (`make doc').


[user manual] <file:docs/keymap-popup.org>


5 Development
═════════════

  The repository flake pins Nixpkgs and provides Emacs, GNU Make,
  Texinfo, and package-lint.  Public Make targets enter the development
  shell automatically when Nix is available:

  ┌────
  │ make dev
  │ make doc
  └────

  Enter the same environment manually with `nix develop'.  Run the
  sandboxed package build, tests, lint checks, and manual build with:

  ┌────
  │ nix flake check
  └────

  Set `USE_NIX=0' to run a Make target directly in the current
  environment.
