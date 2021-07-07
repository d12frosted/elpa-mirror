`diff-hl-mode' highlights uncommitted changes on the side of the
window (using the fringe, by default), allows you to jump between
the hunks and revert them selectively.

Provided commands:

`diff-hl-diff-goto-hunk'  C-x v =
`diff-hl-revert-hunk'     C-x v n
`diff-hl-previous-hunk'   C-x v [
`diff-hl-next-hunk'       C-x v ]

The mode takes advantage of `smartrep' if it is installed.

Add either of the following to your init file.

To use it in all buffers:

(global-diff-hl-mode)

Only in `prog-mode' buffers, with `vc-dir' integration:

(add-hook 'prog-mode-hook 'turn-on-diff-hl-mode)
(add-hook 'vc-dir-mode-hook 'turn-on-diff-hl-mode)
