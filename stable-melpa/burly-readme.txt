This package provides tools to save and restore frame and window
configurations in Emacs, including buffers that may not be live
anymore.  In this way, it's like a lightweight "workspace" manager,
allowing you to easily restore one or more frames, including their
windows, the windows' layout, and their buffers.

Internally it uses Emacs's bookmarks system to restore buffers to
their previous contents and location.  This provides power and
extensibility, since many major modes already integrate with
Emacs's bookmarks system.  However, in case a mode's bookmarking
function isn't satisfactory, Burly allows the user to customize
buffer-restoring functions for specific modes.

For Org mode, Burly provides such custom functions so that narrowed
and indirect Org buffers are properly restored, and headings are
located by outline path in case they've moved since a bookmark was
made (the org-bookmark-heading package also provides this through
the Emacs bookmark system, but users may not have it installed, and
the functionality is too useful to not include here by default).

Internally, buffers and window configurations are also encoded as
URLs, and users may also save and open those URLs instead of using
Emacs bookmarks.  (The name "Burly" comes from "buffer URL.")
