The `buffer-guardian' package provides a global mode that automatically saves
buffers without requiring manual intervention.

By default, `buffer-guardian-mode' saves file-visiting buffers when:
- Switching to another buffer.
- Switching to another window or frame.
- The window configuration changes (e.g., window splits).
- The minibuffer is opened.
- Emacs loses focus.

In addition to regular file-visiting buffers, `buffer-guardian-mode' also
handles specialized editing buffers used for inline code blocks, such as
`org-src' (for Org mode) and `edit-indirect' (commonly used for Markdown
source code blocks). These temporary buffers are linked to an underlying
parent buffer. Automatically saving them ensures that modifications made
within these isolated code environments are correctly propagated back to the
original Org or Markdown file.

Features disabled by default but can be enabled:
- Save the buffer even if a window change results in the same buffer being
  selected.
- Save all file-visiting buffers periodically at a specific interval.
- Save all file-visiting buffers after a period of user inactivity.
- Prevent auto-saving remote files.
- Prevent saving files that do not exist on disk.
- Set a maximum buffer size limit for auto-saving.
- Ignore buffers whose names match specific regular expressions.
- Use custom predicate functions to determine if a buffer should be saved.

(Buffer Guardian runs in the background without interrupting the workflow.
For example, the package safely aborts the auto-save process if the file is
read-only, if the file's parent directory does not exist, or if the file was
modified externally. Additionally, it gracefully catches and logs errors if a
third-party hook attempts to request user input, ensuring that the editor
never freezes during an automatic background save.)
