Extend M-x all (older than M-x occur-edit-mode) to be replacement of it.
  - Show line number before line content (using overlay)
  - Can navigate with M-x next-error / M-x previous-error
  - Use C-x h in *All* to get all matched lines.

Call M-x all from anything/helm:
  1. Call anything/helm command showing lineno and content
     such as M-x anything-occur / anything-browse-code /
             helm-occur / helm-swoop(RECOMMENDED!) etc
  2. Press C-c C-a to show anything/helm contents into *All* buffer
  3. You can edit *All* buffer!

Multiple-cursors in *All*:
  - Press C-c C-m sets one cursor to all lines in *All* buffer.
  - If you use helm-swoop, set multiple cursors at the first match!
    - Otherwise, they are at the beginning of line.  (limitation)

*All* is undo-able!
