Often times we find ourselves in a situation where a single file
or directory is nested in a chain of nested directories with no
other content.  This is sometimes due to various mandatory
layouts demanded by packaging tools or tools generating these
deeply-nested "unique" paths to disambiguate architectures or
versions (but we often use only one anyway).  If the user wants
to access these directories they have to quite needlessly
drill-down through varying number of "uninteresting" directories
to get to the content.

This minor mode is in main inspired by how GitHub renders these
paths: if there is a chain of directories where each one only has
one child, they are concatenated together and shown on the first
level in this collapsed form.  When the user clicks this
collapsed directory they are immediately brought to the deepest
directory with some actual content.

To enable or disable this functionality use `dired-collapse-mode'
to toggle it for the current dired buffer.  To enable the mode
globally in all dired buffers, use `global-dired-collapse-mode'.

If the deepest directory contains only a single file this file is
displayed instead of the last directory.  This way we can get
directly to the file itself.  This is often helpful with config
files which are stored in their own directories, for example in
`~/.config/foo/config' and similar situations.

The files or directories re-inserted in this manner will also
have updated permissions, file sizes and modification dates so
they truly correspond to the properties of the file being shown.

The path to the deepest file is dimmed with the
`dired-collapse-shadow' face so that it does not distract but at
the same time is still available for inspection.

The mode is integrated with `dired-rainbow' so the nested files
are properly colored according to user's rules.
