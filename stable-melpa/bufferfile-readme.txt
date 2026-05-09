The bufferfile package provides helper functions to delete, rename, or copy
buffer files:
- `bufferfile-rename': Renames the file visited by the current buffer,
  ensures that the destination directory exists, and updates the buffer name
  for all associated buffers, including clones/indirect buffers. It also
  ensures that buffer-local features referencing the file, such as Eglot,
  Dired buffers, or the `recentf' list, are correctly updated to reflect the
  new file name.
- `bufferfile-delete': Delete the file associated with a buffer and kill all
  buffers visiting the file, including clones/indirect buffers.
- `bufferfile-copy': Ensures that the destination directory exists and copies
  the file visited by the current buffer to a new file.

The bufferfile package overcomes limitations in Emacs' built-in functions:
- Emacs built-in renaming: While indirect buffers continue to reference the
  correct file path, their buffer names can become outdated.
- Emacs built-in deleting: Indirect buffers are not automatically removed
  when the base buffer or another indirect buffer is deleted.

The bufferfile package resolves these issues by updating buffer names when a
file is renamed and removing all related buffers, including indirect ones,
when a file is deleted.

(To make bufferfile use version control when renaming or deleting files, you
can set the variable `bufferfile-use-vc' to t. This ensures that file
operations within bufferfile interact with the version control system,
preserving history and tracking changes properly.)

Installation from MELPA
-----------------------
(use-package bufferfile
  :commands (bufferfile-copy
             bufferfile-rename
             bufferfile-delete)
  :custom
  ;; If non-nil, display messages during file renaming operations
  (bufferfile-verbose nil)

  ;; If non-nil, enable using version control (VC) when available
  (bufferfile-use-vc nil)

  ;; Specifies the action taken after deleting a file and killing its buffer.
  (bufferfile-delete-switch-to 'parent-directory))
