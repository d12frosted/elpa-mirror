Helix keybindings in Emacs.

Helix Mode is a minor mode that emulates Helix editor keybindings
in Emacs.  Helix is a modal text editor with keybindings similar to
vi, but with some noteworthy differences. Helix Mode supports a
small subset of Helix functionality with the goal of recreating the
editor navigation/selection experience in Helix while leaving the
hard problems (like directory navigation and searching) to Emacs.

Usage:

Enable Helix mode globally (for all buffers besides minibuffers):

  (helix-mode)

Or enable it locally in specific buffers:

  (helix-normal-mode 1)

Normal mode is the default mode. You can return to it by pressing
ESC.  Enter insert mode by pressing 'i' (insert before cursor) or
'a' (insert after cursor).

Key Features:

- Modal editing with normal and insert modes
- Helix-style movement commands (hjkl, w/e/b, f/t, etc.)
- Selection-first model for editing
- Goto mode (g prefix) for quick navigation
- Space mode (SPC prefix) for project commands
- Window mode (C-w prefix) for window management
- Typable commands (invoked with :)

Extending Helix Mode:

Add custom keybindings:

  (helix-define-key 'space "w" #'my-custom-function)

Valid states: insert, normal, space, view, goto, window

Define custom typable commands:

  (helix-define-typable-command "format" #'format-all-buffer)
