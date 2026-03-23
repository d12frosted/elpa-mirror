TILES (Tagged Instant Lightweight Emacs Snippets) is a note-taking
system where each note is a title-less, single paragraph stored
in its own file.  Notes are organized through tags and bold keywords
rather than hierarchies or titles.  A dashboard offers a bird's-eye
view of notes and allows note manipulation: create, edit, delete,
stitch view mode, and more.

Note file format (TYYYYMMDDHHMMSS.org):

  This is the paragraph.  *Bold words* are searchable keywords.
  /Italic/ and [[links]] are supported.  Inline footnotes[fn:: like
  this] are stripped from previews.  Org Mode format is recommended.

  && This is a private paragraph.  It is hidden from previews,
  stitched views, and dynamic blocks.  Only visible when expanding
  a note with TAB in the dashboard or editing the file directly.

  tag1/tag2/tag3

The last non-empty line is always the tag line; everything above it
(separated by a blank line) is content.  Multi-paragraph notes work,
but they are discouraged and not considered to be in the spirit of
TILES.  Paragraphs starting with && are private (hidden from all
views except TAB expansion and direct editing).

Features:
- Atomic notes: one paragraph per file, no titles required
- Timestamp naming: files named TYYYYMMDDHHMMSS.org
- Tag-based organization via slash-separated tag lines
- Keyword extraction: bold words (*word*) are searchable; hyphens
  are normalized to spaces for matching (e.g. *Falcon-9* and
  *Falcon 9* are the same keyword) but note content is unchanged
- Dashboard (tiles-show-notes): chronological listing with
  color-coded timestamps, inline org preview, editable split,
  tag/keyword filtering, tag exclusion, and date editing
- Moon phase in dashboard status line (days until next New/Full Moon)
- Tag search with AND/OR logic (/ = AND, space = OR)
- Keyword search with OR logic (space-separated terms)
- Two-panel search view with live preview
- Stitched view: search results as flowing text
- Quick capture via minibuffer (tiles-quick, tiles-yank)
- Touch command to bump a note's timestamp (tiles-touch)
- Private paragraphs: && prefix hides content from all views
  except TAB expansion and direct file editing
- Focus mode: distraction-free editing with centered ~80-char
  body, (tiles-focus-mode, enabled by default)
- Tag/keyword listing with occurrence counts, sorting, and keyword rename
- Tag-line fontification: tag line shown in red when editing notes
- Unicode box-drawing dashboard separators (tiles-fancy-separators)
- In-memory cache with mtime invalidation for fast repeated access
- Org dynamic blocks for embedding note lists/contents in org files

Global keybindings (under C-c m):
  C-c m m   - Dashboard (tiles-show-notes)
  C-c m n   - New note (tiles-new)
  C-c m q   - Quick capture via minibuffer (tiles-quick)
  C-c m y   - Quick capture from clipboard (tiles-yank)
  C-c m t   - Tag search (tiles-tag-search); insert tag at point in capture buffers
  C-c m k   - Keyword search (tiles-keyword-search)

Dashboard keybindings:
  n/p       - Navigate notes
  SPC       - Open editable preview split (updates on navigation)
  RET       - Open note file
  TAB       - Toggle expanded view (private &&, keywords, stats)
  M-up/down - Reorder notes
  d         - Change note date/timestamp
  u         - Touch (update timestamp to now)
  D         - Delete note (with confirmation)
  t         - Filter by tag
  k         - Filter by keyword
  T         - List all tags
  K         - List all keywords
  F         - Exclude tags (hide notes with specified tags)
  c         - Clear search filter (keeps exclusion)
  C         - Clear tag exclusion (keeps search filter)
  f         - Toggle raw preview (strip org formatting)
  +         - Load next batch of notes
  0         - Stitch displayed notes (respects reordering)
  l         - New note (same as C-c m n)
  g         - Refresh
  q         - Quit

Capture keybindings:
  C-c C-c   - Save note (prompts for tags if missing)
  C-c C-k   - Cancel and discard

Search view keybindings:
  n/p       - Navigate results
  RET       - Open note
  SPC       - Toggle to stitched view
  r         - Refine search
  t/k       - Switch to tag/keyword search
  q         - Quit

Stitched view keybindings:
  n/p       - Jump between note boundaries
  RET/e     - Open source file at point
  SPC       - Toggle back to two-panel view
  r         - Refine search
  q         - Quit

Tag search syntax:
  /         - AND (all tags in group must match)
  space     - OR (any group matches)
  Example: "b218/lx2026 misc" = (b218 AND lx2026) OR misc

Keyword search syntax:
  space     - OR (any term matches)
  Example: "emacs Lisp" = Emacs OR Lisp

Other commands (M-x):
  tiles-touch       - Update a note's timestamp to now (renames file)
  tiles-focus-mode  - Toggle distraction-free editing (~80-char centered)
  tiles-list-tags   - Browse all unique tags with occurrence counts
  tiles-list-keywords - Browse all unique keywords with occurrence counts
  tiles-list-rename - Rename keyword under cursor across all notes (R in keyword list)
  tiles-clear-cache - Force reload of all note data from disk
  tiles-show-notes  - Open the dashboard (also C-c m m)
  tiles-new         - Create a new note (also C-c m n)
  tiles-capture     - Alias for tiles-new
  tiles-quick       - Quick capture via minibuffer (also C-c m q)
  tiles-yank        - Quick capture from clipboard (also C-c m y)
  tiles-tag-search  - Search by tags (also C-c m t)
  tiles-keyword-search - Search by keywords (also C-c m k)

Org dynamic blocks:
  #+BEGIN: tiles-notes :tags "b218/lx2026" :sort "newest" :limit 10
  (generates a linked list of matching notes)
  #+END:

  #+BEGIN: tiles-files :tags "journal" :separator "\n-----\n"
  (embeds note contents directly)
  #+END:

Update blocks with C-c C-x C-u, insert with C-c C-x x.

Changelog:

  0.4   - First MELPA release;
  0.3.5 - Tag mode control: tiles-tag-mode can be `unrestricted' (default),
          `inhibit' (no tags, tag search/filter disabled), a list of allowed
          tag strings (completion-based, first element is default), or
          (required-one-of TAG...) where any tags are accepted but at least
          one from the list must be present.
          Fix: deleting the last note now refreshes the dashboard to an empty
          state instead of leaving the deleted note visible.
  0.3.4 - Keyword rename: R in keyword list renames a keyword across all notes.
  0.3.3 - Unicode box-drawing dashboard separators, tag-line fontification,
          focus mode from stitched view.
  0.3.2 - Focus mode for distraction-free editing (~80-char centered).
          Interactive tag/keyword lists with occurrence counts and
          sorting (alphabetical/occurrence, ascending/descending).
          Dashboard keybindings: T list tags, K list keywords,
          u touch, L new note with focus mode.  Stitch confirmation
          when no filter is active.
  0.3.1 - Red & indicator for notes with private paragraphs.
  0.3   - Private paragraphs: paragraphs starting with && are hidden
          from dashboard previews, stitched views, search panels, and
          dynamic blocks.  Only visible when expanding a note with TAB
          in the dashboard or editing the file directly.
  0.2   - Initial public release.
