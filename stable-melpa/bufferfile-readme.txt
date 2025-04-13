This package provides helper functions to delete and rename buffer files:
- `bufferfile-rename': Renames the file visited by the current buffer and
  updates the buffer name for all associated buffers, including clones and
  indirect buffers.
- `bufferfile-delete': Delete the file associated with a buffer and kill all
  buffers visiting the file, including clones/indirect buffers.
