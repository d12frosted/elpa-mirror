
Renders a live preview of whatever you are editing in a side
window.

You can give any shell command or Emacs Lisp function to render the
preview. The preview is rendered whenever you are idle for a few
seconds. Different buffers can have different preview commands.
There is only one global preview buffer; whenever you go idle in a
buffer that has a preview command, the preview buffer is updated
with a preview of that buffer.

This is useful for previewing e.g. manual pages or other
documentation while writing them. Instead of a preview, could also
run a validator or crunch some statistics.

Maybe in the future: graphics support (e.g. render HTML or TeX as
an image and show it in Emacs).
