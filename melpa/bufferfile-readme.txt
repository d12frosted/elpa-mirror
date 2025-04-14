This package provides helper functions to delete and rename buffer files:
- bufferfile-rename: Renames the file visited by the current buffer and
  updates the buffer name for all associated buffers, including clones and
  indirect buffers. It also ensures that buffer-local features referencing
  the file, such as Eglot, are correctly updated to reflect the new file
  name.
- bufferfile-delete: Delete the file associated with a buffer and kill all
  buffers visiting the file, including clones/indirect buffers.
- bufferfile-copy: Copies the file visited by the current buffer to a new
  file.

(The functions above also ensures that any modified buffers are saved prior
to executing operations like renaming, deleting, or copying.)

Installation from MELPA
-----------------------
(use-package bufferfile
  :ensure t)
