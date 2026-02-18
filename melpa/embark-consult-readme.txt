This package provides integration between Embark and Consult.  The package
will be loaded automatically by Embark.

- Support for consult-buffer, so that you get the correct actions
for each type of entry in consult-buffer's list.

- Support for consult-line, consult-outline, consult-mark and
consult-global-mark, so that the insert and save actions don't
include a weird unicode character at the start of the line, and so
you can export from them to an occur buffer (where occur-edit-mode
works!).

- Enabling Consult preview in `embark-live' buffers.
