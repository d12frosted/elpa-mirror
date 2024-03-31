other-frame-window provides prefix key sequences to control where a
new buffer is created by a subsequent command. With no prefix, the
buffer is created where the command decides (nominally the currently
selected window). Prefix C-x 7 causes the buffer to appear in
another window in the same frame; a window is created if necessary.
Prefix C-x 9 causes the buffer to appear in another frame; a frame
is created if necessary.

Some commands display new buffers in other than the currently
selected window, which defeats the purpose of ‘other-frame-window’ in
the absense of a prefix. To override that, customize
‘display-buffer-alist’ for those commands. For example, to override
‘gud-gdb’:

(add-to-list
 'display-buffer-alist
 (cons "\\*gud"
	 (cons 'display-buffer-same-window nil)))
)

Other key bindings provided by other-frame-window:

C-x W moves the current buffer to another window in the same frame.

C-x F moves the current buffer to another frame.


In addition, C-x 7 and C-x 9 can be followed by these keys:

0 - deletes the current window.

1 - deletes the other windows/frames.

2 - shows another view of the current buffer in a new
    window/frame.

a - creates a commit log entry for the current defun in
    another window/frame.

b - switches to another buffer in another window/frame.

d - start dired in another window/frame.

f - find-file in another window/frame.

m - compose mail in another window/frame.

o - select another window/frame.

r - find-file-read-only in another window/frame.

To extend this list, add key bindings to ‘ofw-transient-map’.


Usage:

Enable the minor mode with:

M-x other-frame-window-mode

or, in your ~/.emacs:

(other-frame-window-mode t)


Design:

This uses C-x 7, 9 prefix because those keys are undefined in core
Emacs.  It could eventually switch to 4, 5, since those are
currently used for -other-window, -other-frame bindings.

(info "(emacs) Pop Up Window") (info "(emacs) Creating Frames")

This adds advice to switch-to-buffer; eventually Emacs could
reimplement switch-to-buffer to do the same.

Todo:

- Pay attention to bindings added to ctl-x-4-map and ctl-x-5-map
- Should `C-x 7 C-h' display the transient map?
- `C-x 7 C-h k f' should show `find-file' rather than `self-insert-command'.
  This should probably be fixed in set-transient-map.