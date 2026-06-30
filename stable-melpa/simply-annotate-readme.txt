
A lightweight annotation system for Emacs that allows you to add
persistent notes to any text file without modifying the original
content.  Enhanced with threading, collaboration, and org-mode
integration.  Requires Emacs 28.1+ (which bundles `transient').

Quick Start (use-package):

  (use-package simply-annotate
    :bind-keymap ("C-c a" . simply-annotate-command-map)
    :hook (find-file . simply-annotate-mode))

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
3. Navigate with the command prefix then `n` (next) and `p` (previous)

Keymap Configuration:

`simply-annotate-mode-map' is intentionally minimal and does not
install global `M-n`/`M-p` bindings.  All other commands are in
`simply-annotate-command-map':

  ;; Recommended: C-c a prefix (defers loading until first use)
  :bind-keymap ("C-c a" . simply-annotate-command-map)

  ;; Alternative: M-s prefix (replaces Emacs search-map)
  ;; Requires :demand t with global-set-key in :config
  ;; Do NOT use :bind-keymap with M-s (see docstring for details)
  ;; Call `simply-annotate-inherit-search-map' to keep the default
  ;; M-s bindings (occur, isearch-forward-symbol-at-point, etc.)
  ;; working via keymap inheritance.
  :demand t
  :config
  (global-set-key (kbd "M-s") simply-annotate-command-map)
  (simply-annotate-inherit-search-map)

Two features reduce prefix-typing for repeated commands:

- Transient menu: <prefix> ? (`simply-annotate-menu') opens a
  discoverable dispatcher; navigation and display toggles stay open
  so you can repeat them without re-opening the menu.
- `repeat_mode' (Emacs 28.1+): enable it with M-x repeat-mode (or
  (repeat-mode 1) in your init).  After one navigation/display
  command you can continue with the bare keys n p ' / [ ] g -- see
  `simply-annotate-repeat-map'.

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
- Press <prefix> d to toggle hiding of done/closed threads; customise
  `simply-annotate-hide-done-statuses' (e.g. '("resolved" "closed")) and
  `simply-annotate-hide-done-style' (`full' or `indicator')
- Press <prefix> c to collapse/expand the inline annotation thread at
  point (requires inline display to be on via <prefix> /)

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

Margin Inline Display:

Use `simply-annotate-inline-position' set to `margin-left' or
`margin-right' to show annotation boxes in the Emacs display margin
(not to be confused with text margins for filling).  Each line of the
annotation box appears in the margin next to the corresponding line
of the annotated region.  Wraps to `simply-annotate-margin-width'
columns (default 30).  If the annotation is longer than the annotated
region, extra lines are truncated with "... +N lines".  Requires the
base display style (fringe, bracket, etc.) to locate annotations in
the buffer since the margin alone provides no markers.

Press <prefix> ; to cycle `simply-annotate-inline-position' (after,
above, margin-left, margin-right) without leaving the transient menu.

Project-Aware Annotations:

By default, annotations are stored in a single global database.
Set `simply-annotate-database-strategy' to use per-project databases
that can be committed alongside your code:

;; Store annotations at the project root (.simply-annotations.el)
(setq simply-annotate-database-strategy 'project)

;; Or merge project and global databases (project wins on conflicts)
(setq simply-annotate-database-strategy 'both)

Project-scoped commands (require project.el):
- <prefix> P   show annotations for the current project (org listing)
- <prefix> C-t show annotations for the current project (sortable table)
- <prefix> f   jump to annotated file
- <prefix> A   cross-project overview of every project with annotations
               (sortable table with per-status counts).  Discovers both
               global-db entries and per-project `.simply-annotations.el'
               files via `project-known-project-roots'.  From the table,
               RET/L/K drill into the project's table/org/kanban view.

Dired-aware narrowing: when the four project commands above are
invoked from a `dired' buffer that lives under a project
subdirectory, they automatically narrow to that subdirectory --
useful for slicing large projects without any explicit selection
UI.  Prefix arguments escape this:

  no prefix  dired-aware project view (auto-narrow if applicable)
  C-u        whole project, ignoring any dired auto-narrow
  C-u C-u    every annotated file in the database (jump-to-file
             and `simply-annotate-show-project'); for the table and
             kanban this behaves the same as C-u

In the kanban buffer, a narrowed board can be widened with `d'
(clear directory filter) without leaving the buffer.  The currently
active directory is shown at the front of the kanban header line.

To migrate existing global annotations into a project database:
  M-x simply-annotate-migrate-to-project
