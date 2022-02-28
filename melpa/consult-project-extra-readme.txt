Creates an endpoint for accessing different project sources.  The consult view
can be narrowed to: (b) current project's buffers, (f) current project's files
and (p) to select from the list of known projects.

The buffer and project file sources are only enabled in case that the user is
in a project file/buffer.  See `project-current'.

A different action is issued depending on the source.  For both buffers and
project files, the default action is to visit the selected element.  When a
known project is selected, a list to select from is created with the selected
project's files.
