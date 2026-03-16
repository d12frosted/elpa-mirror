The `buffer-guardian' package provides a global mode that automatically saves
buffers without requiring manual intervention.

By default, `buffer-guardian-mode' saves a buffer when the user:
- Switches to another buffer or window
- Emacs loses focus
- The minibuffer is opened

In addition to regular file-visiting buffers, `buffer-guardian' also handles
specialized editing buffers such as `org-src' and `edit-indirect'. (These
buffers are temporary editing environments that are linked to another
underlying buffer Saving them is important because the changes made in these
indirect editing contexts must be propagated back to the original buffer to
ensure that the modifications are not lost.)

Other features that are disabled by default:
- Saves all buffers on a periodic interval or when Emacs is idle.
- Excludes remote files, nonexistent files, or huge files.
- Allows custom exclusion rules using regular expressions or predicate
  functions.
