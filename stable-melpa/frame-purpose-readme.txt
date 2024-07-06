`frame-purpose' makes it easy to open purpose-specific frames that only show certain buffers,
e.g. by buffers' major mode, their filename or directory, etc, with custom frame/X-window
titles, icons, and other frame parameters.

Note that this does not lock buffers to certain frames, and it does not prevent frames from
showing any buffer.  It works by overriding the `buffer-list' function so that, within a
purpose-specific frame, any code that uses `buffer-list' (e.g. `list-buffers', `ibuffer', Helm
buffer-related commands) will only show buffers for that frame's purpose.  You could say that,
within a purpose-specific frame, you would have to "go out of your way" to show a buffer that's
not related to that frame's purpose.

;; Usage:

First, enable `frame-purpose-mode'.  This overrides `buffer-list' with a function that acts
appropriately on purpose-specific frames.  When the mode is disabled, `buffer-list' is returned
to its original definition, and purpose-specific frames will no longer act specially.

There are some built-in interactive commands:

+ `frame-purpose-make-directory-frame': Make a purpose-specific frame for buffers associated with
DIRECTORY.  DIRECTORY defaults to the current buffer's directory.

+ `frame-purpose-make-mode-frame': Make a purpose-specific frame for buffers in major MODE.  MODE
defaults to the current buffer's major mode.

 + `frame-purpose-show-sidebar': Show list of purpose-specific buffers on SIDE of this frame.
 When a buffer in the list is selected, the last-used window switches to that buffer.  Makes a
 new buffer if necessary.  SIDE is a symbol, one of left, right, top, or bottom.

For more fine-grained control, or for scripted use, the primary function is
`frame-purpose-make-frame'.  For example:

Make a frame to show only Org-mode buffers, with a custom frame (X window) title and icon:
(frame-purpose-make-frame :modes 'org-mode
                          :title "Org"
                          :icon-type "~/src/emacs/org-mode/logo.png")

Make a frame to show only `matrix-client' buffers, with a custom frame (X window) title and icon,
and showing a list of buffers in a sidebar window on the right side of the frame:
(frame-purpose-make-frame :modes 'matrix-client-mode
                          :title "Matrix"
                          :icon-type (expand-file-name "~/src/emacs/matrix-client-el/logo.png")
                          :sidebar 'right)
