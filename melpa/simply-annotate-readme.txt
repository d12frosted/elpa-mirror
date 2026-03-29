
A lightweight annotation system for Emacs that allows you to add
persistent notes to any text file without modifying the original
content.  Enhanced with threading, collaboration, and org-mode
integration.  Requires Emacs 28.1+, no external dependencies.

Quick Start (use-package):

  (use-package simply-annotate
    :bind-keymap ("C-c a" . simply-annotate-command-map)
    :hook (find-file-hook . simply-annotate-mode))

  (with-eval-after-load 'simply-annotate
    (add-hook 'dired-mode-hook #'simply-annotate-dired-mode))

Quick Start (require):

  (require 'simply-annotate)
  (global-set-key (kbd "C-c a") simply-annotate-command-map)
  (add-hook 'find-file-hook #'simply-annotate-mode)
  (add-hook 'dired-mode-hook #'simply-annotate-dired-mode)

All commands live in `simply-annotate-command-map', which you bind
to a prefix key of your choice.  With C-c a as the prefix:

1. Open any file
2. Select text and press C-c a j to create your first annotation
3. Navigate with M-n (next) and M-p (previous)

Keymap Configuration:

`simply-annotate-mode-map' is intentionally minimal (only M-n and
M-p for navigation).  All other commands are in
`simply-annotate-command-map':

  ;; Recommended: C-c a prefix (defers loading until first use)
  :bind-keymap ("C-c a" . simply-annotate-command-map)

  ;; Alternative: M-s prefix (replaces Emacs search-map)
  ;; Requires :demand t with global-set-key in :config
  ;; Do NOT use :bind-keymap with M-s (see docstring for details)
  :demand t
  :config (global-set-key (kbd "M-s") simply-annotate-command-map)

Threading & Collaboration:

All keybindings below use <prefix> to denote your chosen prefix
(e.g. C-c a j means press C-c a then j).

* Replies
- Press <prefix> r to add a reply to any annotation
- Creates threaded conversations for code reviews

* Status Management
- Press <prefix> s to set status (open, in-progress, resolved, closed)
- Press <prefix> p to set priority (low, normal, high, critical)
- Press <prefix> t to add tags for organization

* Author Management
- Configure team members: (setq simply-annotate-author-list '("John" "Jane" "Bob"))
- Set prompting behavior: (setq simply-annotate-prompt-for-author 'threads-only)
- Press <prefix> a to change annotation author

* Editing
- Press <prefix> e to edit the current annotation
- Edit in a sexp form and then C-c C-c to save
- Any data field can be edited

* Org-mode Integration
- Press <prefix> o to export annotations to org-mode files
- Each thread becomes a TODO item with replies as sub-entries

Configuration Examples:

;; Single user (default)
(setq simply-annotate-prompt-for-author nil)

;; Team collaboration
(setq simply-annotate-author-list '("John Doe" "Jane Smith" "Bob Wilson"))
(setq simply-annotate-prompt-for-author 'threads-only)
(setq simply-annotate-remember-author-per-file t)

Inline Pointer Styles:

When inline display is enabled, a pointer connects the annotation
box to the annotated text.  Customise via
`simply-annotate-inline-pointer-after' (box below text) and
`simply-annotate-inline-pointer-above' (box above text).  Strings
can be multiline (use \n).  Set to nil to disable.

;; Simple arrows (default)
(setq simply-annotate-inline-pointer-after "▴")
(setq simply-annotate-inline-pointer-above "▾")

;; Larger triangles
(setq simply-annotate-inline-pointer-after "▲")
(setq simply-annotate-inline-pointer-above "▼")

;; Tall stems
(setq simply-annotate-inline-pointer-after "  ║")
(setq simply-annotate-inline-pointer-above "  ║")

;; Speech bubble tails
(setq simply-annotate-inline-pointer-after " ╰┐")
(setq simply-annotate-inline-pointer-above " ╰┐")

;; L-bracket connectors
(setq simply-annotate-inline-pointer-after "│\n╰─")
(setq simply-annotate-inline-pointer-above "╭─\n│")

(setq simply-annotate-inline-pointer-after "│\n╰──▸")
(setq simply-annotate-inline-pointer-above "╭──▸\n│")

;; Heavy L-bracket
(setq simply-annotate-inline-pointer-after "┃\n┗━▶")
(setq simply-annotate-inline-pointer-above "┏━▶\n┃")

;; Decorative single char
(setq simply-annotate-inline-pointer-after "●")
(setq simply-annotate-inline-pointer-above "●")

(setq simply-annotate-inline-pointer-after "◆")
(setq simply-annotate-inline-pointer-above "◆")

(setq simply-annotate-inline-pointer-after "✦")
(setq simply-annotate-inline-pointer-above "✦")

(setq simply-annotate-inline-pointer-after "⟡")
(setq simply-annotate-inline-pointer-above "⟡")

;; Minimal / subtle
(setq simply-annotate-inline-pointer-after "·")
(setq simply-annotate-inline-pointer-above "·")

(setq simply-annotate-inline-pointer-after "┊")
(setq simply-annotate-inline-pointer-above "┊")

(setq simply-annotate-inline-pointer-after "╷")
(setq simply-annotate-inline-pointer-above "╵")

;; Bracket pairs
(setq simply-annotate-inline-pointer-after "╰─┤")
(setq simply-annotate-inline-pointer-above "╭─┤")

;; Fancy multiline
(setq simply-annotate-inline-pointer-after "│\n│\n╰──▸")
(setq simply-annotate-inline-pointer-above "╭──▸\n│\n│")

(setq simply-annotate-inline-pointer-after "┃\n┃\n┗━━▶")
(setq simply-annotate-inline-pointer-above "┏━━▶\n┃\n┃")
