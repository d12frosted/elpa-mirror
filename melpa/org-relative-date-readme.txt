`org-relative-date-mode' paints a live "(N days away)" / "(N days ago)"
annotation *after* every Org timestamp in the buffer, without modifying the
file.  It is the spiritual successor to `time-uuid-mode': rather than
replacing text via a `display' property, it appends an `after-string' overlay,
so the raw `<2027-01-09 Sat .+6m>' stays visible and editable.

Overlays are painted lazily through `jit-lock' (only the visible region is
scanned, so large agenda/journal files stay responsive), and a daily timer
re-runs them so the counts do not go stale at midnight.

Usage:

  (add-hook 'org-mode-hook #'org-relative-date-mode)

or turn it on everywhere with `global-org-relative-date-mode'.
