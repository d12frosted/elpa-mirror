The kirigami package offers a unified interface for text folding across a
diverse set of major and minor modes in Emacs, including `outline-mode',
`outline-minor-mode', `outline-indent-mode', `org-mode', `markdown-mode',
`vdiff-mode', `vdiff-3way-mode', `hs-minor-mode', `hide-ifdef-mode',
`origami-mode', `yafolding-mode', `folding-mode', and `treesit-fold-mode'.

With Kirigami, folding key bindings only need to be configured once. After
that, the same keys work consistently across all supported major and minor
modes, providing a unified and predictable folding experience. The available
commands include:

- `kirigami-open-fold': Open the fold at point.
- `kirigami-open-fold-rec': Open the fold at point recursively.
- `kirigami-close-fold': Close the fold at point.
- `kirigami-open-folds': Open all folds in the buffer.
- `kirigami-close-folds': Close all folds in the buffer.
- `kirigami-toggle-fold': Toggle the fold at point.

(In addition to unified interface, the kirigami package enhances folding
behavior in outline-mode, outline-minor-mode, markdown-mode, and
org-mode. It ensures that deep folds open reliably and allows folds to be
closed even when the cursor is positioned inside the content.)

Installation from MELPA
-----------------------
(use-package kirigami
  :ensure t)
