`jsonian' provides a fully featured `major-mode' to view, navigate and edit JSON files.
Notable features include:
- `jsonian-path': Display the path to the JSON object at point.
- `jsonian-edit-string': Edit the uninterned string at point cleanly in a separate buffer.
- `jsonian-enclosing-item': Move point to the beginning of the collection enclosing point.
- `jsonian-find': A `find-file' style interface to navigating a JSON document.
- Automatic indentation discovery via `jsonian-indent-line'.

When `jsonian' is loaded, it adds `jsonian-mode' and `jsonian-c-mode' to `auto-mode-alist'.
This will overwrite `javascript-mode' by default when opening a .json file.  It will
overwrite `fundamental-mode' when opening a .jsonc file

To have `jsonian-mode' activate when any JSON like buffer is opened,
regardless of the extension, add
 (add-to-list 'magic-fallback-mode-alist '("^[{[]$" . jsonian-mode))
to your config after loading `jsonian'.
