
This global minor mode enhanced the user experience while controlling
through `ivy' interface during some previewable commands.

You can enable this minor mode by doing the following execution,

  `(ivy-file-preview-mode 1)`

Some previewable commands can be a file, path, or search restult.
The file and path can be either absolute/relative file path.  The
search result accepts cons cell for either (line . column) or a
integer (position).
