
Lightweight “electric” popup directory browser.

Features:
- Popup buffer: *Electric Directory* (reused every time).
- Header line shows the current directory (abbreviated).
- RET on a file opens it and exits; RET on a directory drills into it.
- d deletes file/dir at point (with prompt) and refreshes in place.
- ~ deletes backup/autosave files (*~ and #*#) and refreshes.
- Backspace (DEL) goes up one directory level.
- SPC or q quits and restores your previous window layout.
- With a prefix argument, run plain `list-directory`.

Installation:

Manual:
  (require 'electric-list-directory)
  ;; Bind to C-x C-d (Note: this replaces the default `list-directory` binding):
  (global-set-key (kbd "C-x C-d") #'electric-list-directory)

With use-package:
  (use-package electric-list-directory
    :bind ("C-x C-d" . electric-list-directory))  ;; Replaces default `list-directory`

Usage:
  M-x electric-list-directory
