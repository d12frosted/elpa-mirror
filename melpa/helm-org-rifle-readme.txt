This is my rifle.  There are many like it, but this one is mine.
My rifle is my best friend. It is my life.  I must master it as I
must master my life.

What does my rifle do?  It searches rapidly through my Org files,
quickly bringing me the information I need to defeat the enemy.

This package is inspired by org-search-goto/org-search-goto-ml.  It
searches both headings and contents of entries in Org buffers, and
it displays entries that match all search terms, whether the terms
appear in the heading, the contents, or both.  Matching portions of
entries' contents are displayed with surrounding context to make it
easy to acquire your target.

Entries are fontified by default to match the appearance of an Org
buffer, and optionally the entire path can be displayed for each
entry, rather than just its own heading.

; Installation:

;; MELPA

If you installed from MELPA, your rifle is ready.  Just run one of
the commands below.

;; Manual

Install the Helm, dash.el, f.el, and s.el packages.  Then require
this package in your init file:

(require 'helm-org-rifle)
