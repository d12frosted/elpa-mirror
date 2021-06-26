
Bitcoin donations gratefully accepted: 1AmWPmshr6i9gajMi1yqHgx7BYzpPKuzMz

;; Introduction:
This library is based on simple-call-tree.el by Alex Schroeder, but you
do not need that library to use it (this is a replacement).
It displays a buffer containing a call tree for functions in source
code files. You can easily & quickly navigate the call tree, displaying
the code in another window, and apply query-replace or other commands
to individual functions.

When the command `simple-call-tree-display-buffer' or `simple-call-tree-current-function'
is executed a call tree for the functions in the current buffer will be created,
and in the latter case the point in the call tree is placed on the header
closest to its position in the original buffer.
If called with a prefix arg the user is also prompted for other files to include
in the call tree.
The call tree is displayed in a buffer called *Simple Call Tree*,
which has a dedicated menu in the menu-bar showing various commands
and their keybindings. Most of these commands are self explanatory
so try them out.

;; Navigation:
You can navigate the call tree either by moving through consecutive
headers (n/p or N/P keys) or by jumping to main branches (j for branch
corresponding to function at point, and J to prompt for a function).
When you jump to a branch, it is added to `simple-call-tree-jump-ring',
and you can navigate your jump history using the </> keys.
You can also add the function under point to the jump-ring with the . key.
If you use a negative prefix (e.g. C--) before pressing j then the branch
jumped to will not be added to the jump-ring.
If you have fm.el (available here: http://www.damtp.cam.ac.uk/user/sje30/emacs/fm.el)
you can press f to toggle follow mode on/off.

;; Display
Normally child branches correspond to functions/variables called by the parent
branch. However, if you invert the tree by pressing i then the child branches
will correspond to functions that call the parent branch.
You can sort the tree in various different ways, and change the depth of the tree.
You can also narrow the tree to the function at point by pressing /
