This package integrates org-node, a note-taking package, with citar, a
popular bibliographic references management package.  To use, enable the
global minor mode, `citar-org-node-mode', and use citar as normal!

Org-node associates nodes to bibliographic references using the "ROAM_REFS"
property (stored in org-mode's property drawers).  With
`citar-org-node-mode', citar will become aware of org-node nodes with a
corresponding bibliographic reference.  Such nodes will become the associated
"note" for that reference.  (References can have multiple notes.)

For more information on the available features of this package, call

    M-x customize-group citar-org-node RET

For more information on how this package affects citar variables, read the
docstring of `citar-org-node-mode'.

If you would like to see a certain feature not already present in the package
or discover a bug, please open an issue in the project page or reach out to
the package author's email.
