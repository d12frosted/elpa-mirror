This package provides a global minor mode, `electric-cursor-mode', which
automatically changes the cursor depending on the active mode(s).  The
precise modes and associated cursors can be customized with
`electric-cursor-alist', which maps modes with their respective cursors.
The default value of `electric-cursor-alist' maps `overwrite-mode' to 'block
and everything else to `bar'.
