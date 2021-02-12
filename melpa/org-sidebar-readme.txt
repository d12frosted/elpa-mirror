This package presents a helpful sidebar view for Org buffers.
Sidebars are customizable using `org-ql' queries and
`org-super-agenda' grouping.

The default view includes a chronological list of scheduled and
deadlined tasks in the current buffer (similar to the Org agenda
,but without all its features) at the top, and a list of all other
non-done to-do items below.  If the buffer is narrowed, the sidebar
only shows items in the narrowed portion; this allows seeing an
overview of tasks in a subtree.

;; Usage

Call these commands to display sidebars:

- `org-sidebar:' Display the default item sidebars for the current
                 Org buffer.
- `org-sidebar-tree:' Display tree-view sidebar for current Org
                      buffer.

Toggling versions of those commands are also available:

- `org-sidebar-toggle'
- `org-sidebar-tree-toggle'

Customization options are in the `org-sidebar' group.

The functions `org-sidebar-tree-view-buffer' and
`org-sidebar--subtree-buffer' return buffers.

To display custom-defined sidebars, call the function `org-sidebar'
with the arguments described in its docstring.  See examples in
documentation, as well as the definitions of functions
`org-sidebar--todo-items' and `org-sidebar--upcoming-items'.
