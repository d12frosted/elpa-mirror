---------------------------------------------------------------------
Full information can be found on GitHub:
https://github.com/bmag/emacs-purpose/wiki
---------------------------------------------------------------------

Purpose is a package that introduces the concept of a "purpose" for
windows and buffers, and then helps you maintain a robust window
layout easily.

Installation and Setup:
Install Purpose from MELPA, or download it manually from GitHub. If
you download manually, add these lines to your init file:
   (add-to-list 'load-path "/path/to/purpose")
   (require 'window-purpose)
To activate Purpose at start-up, add this line to your init file:
   (purpose-mode)

Purpose Configuration:
Customize `purpose-user-mode-purposes', `purpose-user-name-purposes',
`purpose-user-regexp-purposes' and
`purpose-use-default-configuration'.

Basic Usage:
1. Load/Save window/frame layout (see `purpose-load-window-layout',
   `purpose-save-window-layout', etc.)
2. Use regular switch-buffer functions - they will not mess your
   window layout (Purpose overrides them).
3. If you don't want a window's purpose/buffer to change, dedicate
   the window:
   C-c , d: `purpose-toggle-window-purpose-dedicated'
   C-c , D: `purpose-toggle-window-buffer-dedicated'
4. To use a switch-buffer function that ignores Purpose, prefix it
   with C-u. For example, [C-u C-x b] calls
   `switch-buffer-without-purpose'.
