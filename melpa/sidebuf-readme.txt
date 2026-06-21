Sidebuf displays a persistent, sorted buffer list in a side
window.  It provides a simple, zero-dependency alternative to
heavier buffer management packages.

Features:
 - Flat, sorted buffer list pinned to the left or right side
 - Alphabetical or most-recent sort order
 - Pin buffers to the top of the list
 - Toggle visibility of *special* and hidden buffers
 - Active-buffer tracking with fringe indicator
 - Smart window reuse when selecting buffers
 - Modified-buffer indicators
 - Kill buffers without leaving the sidebar
 - Jump into and back out of the panel with a single key

Usage:
  M-x sidebuf-toggle         Open or close the panel
  M-x sidebuf-open           Open the panel
  M-x sidebuf-close          Close the panel
  M-x sidebuf-select-window  Jump to the panel, or back out of it

`sidebuf-select-window' is not bound to any key by default; see
the README for how to bind it.

Press ? inside the panel to toggle a help window listing all
keybindings; press ? again or ESC to dismiss it.
