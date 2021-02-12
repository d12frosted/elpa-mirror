
Overview
========
This library provides minor mode `volatile-highlights-mode', which
brings visual feedback to some operations by highlighting portions
relating to the operations.

All of highlights made by this library will be removed
when any new operation is executed.


INSTALLING
==========
To install this library, save this file to a directory in your
`load-path' (you can view the current `load-path' using "C-h v
load-path" within Emacs), then add the following line to your
.emacs start up file:

   (require 'volatile-highlights)
   (volatile-highlights-mode t)


USING
=====
To toggle volatile highlighting, type `M-x volatile-highlights-mode <RET>'.

While this minor mode is on, a string `VHL' will be displayed on the modeline.

Currently, operations listed below will be highlighted While the minor mode
`volatile-highlights-mode' is on:

   - `undo':
     Volatile highlights will be put on the text inserted by `undo'.

   - `yank' and `yank-pop':
     Volatile highlights will be put on the text inserted by `yank'
     or `yank-pop'.

   - `kill-region', `kill-line', any other killing function:
     Volatile highlights will be put at the positions where the
     killed text used to be.

   - `delete-region':
     Same as `kill-region', but not as reliable since
     `delete-region' is an inline function.

   - `find-tag':
     Volatile highlights will be put on the tag name which was found
     by `find-tag'.

   - `occur-mode-goto-occurrence' and `occur-mode-display-occurrence':
     Volatile highlights will be put on the occurrence which is selected
     by `occur-mode-goto-occurrence' or `occur-mode-display-occurrence'.

   - Non incremental search operations:
     Volatile highlights will be put on the the text found by
     commands listed below:

       `nonincremental-search-forward'
       `nonincremental-search-backward'
       `nonincremental-re-search-forward'
       `nonincremental-re-search-backward'
       `nonincremental-repeat-search-forward'
       `nonincremental-repeat-search-backwar'

Highlighting support for each operations can be turned on/off individually
via customization. Also check out the customization group

  `M-x customize-group RET volatile-highlights RET'


EXAMPLE SNIPPETS FOR USING VOLATILE HIGHLIGHTS WITH OTHER PACKAGES
==================================================================

- vip-mode

  (vhl/define-extension 'vip 'vip-yank)
  (vhl/install-extension 'vip)

- evil-mode

  (vhl/define-extension 'evil 'evil-paste-after 'evil-paste-before
                        'evil-paste-pop 'evil-move)
  (vhl/install-extension 'evil)

- undo-tree

  (vhl/define-extension 'undo-tree 'undo-tree-yank 'undo-tree-move)
  (vhl/install-extension 'undo-tree)
