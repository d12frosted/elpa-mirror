vulpea-ui provides a customizable sidebar that displays contextual
information about the currently focused vulpea note, along with a
set of default widgets and an API for creating custom widgets.

Features:
- Per-frame sidebar with configurable position and size
- Widget system built on vui components
- Default widgets: outline, backlinks, unlinked mentions, forward
  links, stats
- Easy API for creating custom widgets
- Standalone views: schema dashboard, collection view (a sortable
  table over a filtered set of notes with marks and bulk actions)

Usage:
  (require 'vulpea-ui)
  (vulpea-ui-sidebar-open)

Or add to hooks:
  (add-hook 'org-mode-hook #'vulpea-ui-sidebar-open)
