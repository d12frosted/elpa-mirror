This module runs pydoc on an argument, inserts the output into a help buffer,
and then linkifies and colorizes the buffer. For example, some things are
linked to open the source code, or to run pydoc on them. Some things are
colorized for readability, e.g. environment variables and strings, function
names and arguments.

https://github.com/statmobile/pydoc

pydoc.el provides the following functions.
`pydoc' Run this anywhere, and enter the module/class/function you want documentation for
`pydoc-at-point' Run this in a Python script to see what doc jedi can find for the point
`pydoc-browse' Launches a web browser with documentation.
`pydoc-browse-kill' kills the pydoc web server.

`pydoc' renders some Sphinx markup as links. Images are shown as overlays.
 Most org-links should be active.

LaTeX fragments are shown with org-rendered overlays. ;; Note you need to
escape some things in the python docstrings, e.g. \\f, \\b, \\\\, \\r, \\n or
they will not render correctly.
