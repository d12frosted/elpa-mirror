folgezett.el implements the Luhmann folgezettel system for org-roam.

When a new org-roam note is captured, the user is prompted to choose a
parent note.  A folgezettel ID is generated from the parent and stored in
the FOLGEZETTEL_ID property.  The parent relationship is recorded in
FOLGEZETTEL_PARENT_ID.

ID structure (alternating number/letter segments):

  New chains:         1.1, 2.1, 3.1, ...
  Same chain:         1.1, 1.2, 1.3, ...
  Branches of 1.1:    1.1a, 1.1b, 1.1c, ...
  Branches of 1.1a:   1.1a1, 1.1a2, 1.1a3, ...
  Branches of 1.1a1:  1.1a1a, 1.1a1b, ...

When picking an anchor note, you choose either to (b)ranch off it
(the new note becomes its child, e.g. 1.1 → 1.1a) or to (c)ontinue
its chain (the new note becomes its sibling, e.g. 1.1 → 1.2).

Quick start:

  (with-eval-after-load 'org-roam
    (require 'folgezett)
    (folgezett-setup))

Commands:

  folgezett-assign-id          Manually assign or reassign an ID
  folgezett-remove-id          Remove the ID and parent properties
  folgezett-reparent           Re-parent current note (ID only)
  folgezett-reparent-subtree   Re-parent + recursively update descendants
  folgezett-goto-parent        Jump to the parent note
  folgezett-list-children      Pick and jump to a direct child
  folgezett-show-tree          Display the full folgezettel tree

Evil users: RET in the tree buffer is bound for Emacs state only.
To use it in normal/motion state, add this to your configuration:

  (with-eval-after-load 'folgezett
    (with-eval-after-load 'evil
      (evil-define-key* '(normal motion) folgezett-tree-mode-map
        (kbd "RET") #'folgezett-tree-visit-node)))
