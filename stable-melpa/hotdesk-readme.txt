
`hotdesk-mode' lets you split your monolithic Emacs buffer list into
separate buffer lists, creating distinct work surfaces.

How it works:

  Buffer lists are identified by a label. By setting a frame label, you
  either create a new buffer list or switch to an existing one.  That's it.

Examples:

  Standalone Emacs (single frame):
  Flip between buffer-lists to simulate switching projects (see quickstart).

  Client/Server Emacs (multi frame):
  Assign each frame a different buffer-list to maintain separate workspaces.

The mode is unopinionated and doesn't interfere with your workflow. No
configuration is required (except assigning a label to begin), and buffer
lists behave normally.  Emacs' built-in `desktop` functions save and restore
your session of accumulated buffer lists.

Quickstart:

 1.  (require 'hotdesk)
     (hotdesk-mode 1)

 2.  Demo the mode's behaviour (using default key bindings):

     `C-c C-d ! desk1`    label your frame 'desk1'
     <open some buffers>
     `C-x C-b`            show your 'desk1' buffer list

     `C-c C-d ! desk2`    re-label your frame 'desk2'
     <open some different buffers>
     `C-x C-b`            show your 'desk2' buffer list

     `C-c C-d ! desk1`    switch to the 'desk1' buffer list
     `C-x C-b`            shows your 'desk1' buffers again

     `C-c C-d g`          show and edit your buffer assignments

See README.md at project URL for more info, integration tips and advanced
features.

