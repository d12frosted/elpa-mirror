Vundo (visual undo) displays the undo history as a tree and lets you
move in the tree to go back to previous buffer states. To use vundo,
type M-x vundo RET in the buffer you want to undo. An undo tree buffer
should pop up. To move around, type:

  f   to go forward
  b   to go backward

  n   to go to the node below when you at a branching point
  p   to go to the node above

  a   to go back to the last branching point
  e   to go forward to the end/tip of the branch
  l   to go to the last saved node
  r   to go to the next saved node

  m   to mark the current node for diff
  u   to unmark the marked node
  d   to show a diff between the marked (or parent) and current nodes

  q   to quit, you can also type C-g

n/p may need some more explanation. In the following tree, n/p can
move between A and B because they share a parent (thus at a branching
point), but not C and D.

         A  C
    ──○──○──○──○──○
      │  ↕
      └──○──○──○
         B  D

By default, you need to press RET to “commit” your change and if you
quit with q or C-g, the changes made by vundo are rolled back. You can
set `vundo-roll-back-on-quit' to nil to disable rolling back.

Note: vundo.el requires Emacs 28.

Customizable faces:

- vundo-default
- vundo-node
- vundo-stem
- vundo-highlight

If you want to use prettier Unicode characters to draw the tree like
this:

    ○──○──○
    │  └──●
    ├──○
    └──○

set vundo-glyph-alist by

    (setq vundo-glyph-alist vundo-unicode-symbols)

Your default font needs to contain these Unicode characters, otherwise
they look terrible and don’t align. You can find a font that covers
these characters (eg, Symbola, Unifont), and set `vundo-default' face
to use that font:

    (set-face-attribute 'vundo-default nil :family "Symbola")

Comparing to undo-tree:

Vundo doesn’t need to be turned on all the time nor replace the undo
commands like undo-tree does. Vundo displays the tree horizontally,
whereas undo-tree displays a tree vertically.