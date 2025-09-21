
Overview
--------
`volatile-highlights-mode' is a global minor mode that provides
transient, visual feedback for common editing operations.  After an
operation completes, the affected text is highlighted briefly and
cleared on the next user command.

Features (when the mode is enabled):
- undo: highlight the text restored by undo
- yank and yank-pop: highlight inserted text
- kill/delete: show where text used to be (optionally as a point)
- replacements: highlight results of `query-replace' and `replace-string'
- transposition commands: highlight swapped text from transpose-* and
  transpose-regions operations
- definitions: Emacs 25.1+ uses xref; older Emacs use find-tag
- occur: Emacs < 28 only (Emacs 28+ has built-in occur highlighting)
- non-incremental search commands
- hideshow: highlight shown blocks

Customization
------------
Customize the group `volatile-highlights' (M-x customize-group RET
volatile-highlights RET).
- vhl/animation-style (default: 'static): animation style
  for highlights.
  - 'static  : No animation.
  - 'fade-in : Fade in, then keep highlight until next command.
  - 'pulse   : Fade out, then clear automatically.
- vhl/highlight-zero-width-ranges (default: nil): also mark deletion
  points as a 1-character highlight.
- vhl/default-face: face used for highlights; adjust to match your theme.
Per-feature toggles are available via `vhl/use-<name>-extension-p'.
The xref integration is available but defaults to disabled.

Notes for developers
--------------------
- The public APIs `vhl/add-range' and `vhl/add-position' are
  mode-aware and act as no-ops when `volatile-highlights-mode' is
  disabled.
- To integrate with your own commands, compute the range to
  highlight and call these APIs.  See docs/extending.md for patterns
  and examples.

See README.md for installation and quick configuration, and
docs/extending.md for integration patterns and API reference.

INSTALLING
----------
Place this file on your `load-path', then enable the mode globally:

  (require 'volatile-highlights)
  (volatile-highlights-mode 1)

   - `vhl/animation-start-delay'
     Delay before the highlight animation begins in seconds.  For
     animated styles, this delay is counted after Emacs becomes idle
     (idle timer) to avoid interrupting rapid command sequences; set
     to 0 to start as soon as Emacs is idle.  For 'static, highlights
     appear immediately without waiting for idle.

     Default value is `0.15'.

   - `vhl/animation-frame-interval'
     Delay between animation ticks in seconds.

     Default value is `0.04'.

   - `vhl/highlight-zero-width-ranges'
     If `t', highlight the positions of zero-width ranges.

     For example, if a deletion is highlighted, then the position
     where the deleted text used to be would be highlighted.

     Default value is `nil'.

And you can change the color for volatile highlighting by editing the face:

   - `vhl/default-face'
     Face used for volatile highlights.

When you edit the face, make sure the background color does not overlap with
the default background color, otherwise the highlights will not be visible.


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
