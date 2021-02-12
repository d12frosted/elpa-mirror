Show *Completions* buffer in child frame.

Basically it's the function for `display-buffer-alist` with some child
frame's position and size manipulation:
- Completions frame placed near the point;
- It is placed above or below point depending on completions frame height
  and available space around the point;
- Initial frame width is set to 1 so completion list is arranged in single
  column.  This behavior can be configured via `completions-frame-width`
  variable.
