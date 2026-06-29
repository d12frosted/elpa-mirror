Buframe provides utilities to create, manage, and update local child
frames, associated with a single buffer, for previews or inline overlays.
By default, these child frames are:
- Minimal (no mode-line, tool-bar, tab-bar, etc.)
- Non-focusable, non-disruptive, and dedicated to a buffer
- Dynamically positioned relative to overlays or buffer positions
- Automatically updated or hidden depending on buffer selection

This package is designed to support UI components like popup
previews, completions, or inline annotations, without interfering
with normal Emacs windows or focus behaviour