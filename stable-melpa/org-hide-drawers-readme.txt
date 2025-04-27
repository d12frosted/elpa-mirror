Hide drawers in org-mode buffers using overlays.  These overlays replace the
visual display of drawers using their "display" property.

Usage:
1. Open an org buffer.  (Indirect buffers are supported by org-hide-drawers.)
2. Enable `org-hide-drawers-mode'.  Drawers become "hidden": their displayed
text is changed to `org-hide-drawers-display-string'.
3. Un-hide drawers by calling `org-hide-drawers-toggle'.
4. Hide drawers by calling `org-hide-drawers-toggle' again, or
`org-hide-drawers-delete-overlays'.
