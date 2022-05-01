Workroom provides named "workrooms" (or workspaces), somewhat similar to
multiple desktops in GNOME.

Each workroom has own set of buffers, allowing you to work on multiple
projects without getting lost in all buffers.

Each workroom also has its own set of views.  Views are just named
window configurations.  They allow you to switch to another window
configuration without losing your well-planned current window setup.

You can also bookmark a workroom or all your workrooms to restore them
at a later time, possibly in another Emacs session.

There is always a workroom named "master", which contains all live
buffers.  Removing any buffer from this workroom kills that buffer.  You
can't kill, rename or bookmark this workroom, but you can customize the
variable `workroom-default-room-name' to change its name.

All the useful commands can be called with following key sequences:

  Key        Command
  --------------------------------------
  C-x x s    `workroom-switch'
  C-x x d    `workroom-kill-view'
  C-x x D    `workroom-kill'
  C-x x r    `workroom-rename-view'
  C-x x R    `workroom-rename'
  C-x x c    `workroom-clone-view'
  C-x x C    `workroom-clone'
  C-x x m    `workroom-bookmark'
  C-x x M    `workroom-bookmark-all'
  C-x x b    `workroom-switch-to-buffer'
  C-x x a    `workroom-add-buffer'
  C-x x k    `workroom-remove-buffer'
  C-x x K    `workroom-kill-buffer'

Here the prefix key sequence is "C-x x", but you can customize
`workroom-command-map-prefix' to change it.

Adding and removing buffers to/from workrooms can become a burden.  You
can automate this process by setting `buffers' slot of `workroom' to a
function without arguments returning a list of live buffers.  That list
of buffer will be used as the list of buffers of that workroom.  The
default workroom is an example of this type of workroom, which uses
`buffer-list' for the list of buffers.
