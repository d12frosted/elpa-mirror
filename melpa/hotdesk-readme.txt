
`hotdesk-mode' provides multiple buffer lists that adapt to your workflow.

This allows you to simply split Emacs monolithic buffer list into separate
buffer lists, creating distinct work surfaces.  Example use cases:

 Standalone Emacs (single frame):
   instantly change your active buffer-list to switch projects or tasks
   (see quickstart below)

 Client/Server Emacs (multi frame):
   maintain distinct workspaces with independent per-frame buffer-lists
   (by assigning a distinct label to each frame)

hotdesk is unopinionated and stays out the way, so doesn't interfere with
your workflow.

No configuration is required (apart from labelling your frame), and buffer
lists are built automatically based on your usage.  Emacs' built-in `desktop`
functions can save and restore your hotdesk sessions.

Quickstart:

 1.  (require 'hotdesk)
     (hotdesk-mode 1)

 2.  Demo the mode's behaviour (using default key bindings):

     `C-c C-d ! desk1`    label your frame 'desk1'
     `C-c C-d ?`          verify the label is 'desk1'
     <open some buffers>
     `C-x C-b`            show the 'desk1' buffer list

     `C-c C-d ! desk2`    label your frame 'desk2'
     `C-c C-d ?`          verify the label is 'desk2'
     <open some different buffers>
     `C-x C-b`            show the 'desk2' buffer list

     `C-c C-d ! desk1`    swap to 'desk1' buffer list
     `C-x C-b`            show the 'desk1' buffer list again

     `C-c C-d d`          show/adjust your label assignments

See README.md at project URL for more info, integration tips and advanced
features.

