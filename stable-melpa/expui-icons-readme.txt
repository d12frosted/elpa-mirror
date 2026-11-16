SVG icons from IntelliJ's New UI, vendored unmodified in
icons.tar.gz (see icons/README.md in it for their origin and license).
The archive is read in memory the first time an icon is needed; no
file is extracted.

The API has two layers:

- Names: `expui-icons-name-for-file', `expui-icons-name-for-extension',
  `expui-icons-name-for-mode' and `expui-icons-name-for-buffer' return
  an icon name such as "python".  `expui-icons-names' lists every
  available name.

- Rendering: `expui-icons-image' returns an image descriptor, and
  `expui-icons-icon', `expui-icons-icon-for-file',
  `expui-icons-icon-for-dir', `expui-icons-icon-for-extension',
  `expui-icons-icon-for-mode' and `expui-icons-icon-for-buffer' return
  a string to `insert' or `concat':

    (insert (expui-icons-icon-for-file "init.el") " init.el")
    (expui-icons-icon-for-buffer (current-buffer) :face 'shadow)

  The icon-for functions match nerd-icons' and accept its arguments:
  `:face', a float `:height' relative to the default size, `:v-adjust'
  (ignored, since icons are centered) and nil values meaning "default".

Two styles are available through `expui-icons-style':

- `color' shows the original icons, using their dark variants on dark
  backgrounds (see `expui-icons-background').
- `mono' converts the icons while loading them: light fills are dropped
  and every other color becomes `currentColor', so an icon is drawn in
  the foreground of the face it is displayed with.  Solid badge icons,
  which would become plain blocks, are replaced as listed in
  `expui-icons-mono-substitutes'.

Icon names are paths in the archive without ".svg".  File-type icons have
plain names ("python", "anyType"); the rest of the New UI set mirrors
IntelliJ's directories: "nodes/folder", "nodes/class",
"general/chevronRight", "actions/search", and so on.

Icons are centered on the line.  File-type and node icons are 16x16
and shown exactly `expui-icons-height' pixels high, so they line up in
columns; icons of other design sizes (14px gutter icons, 28px dialog
icons, ...) are scaled by the same factor.
