
Usage:

There are three ways to use this package:

1. Enable ‘eldoc-box-hover-mode’. Emacs will show the documentation
of symbol at point in a children on the upper left or right corner.

2. Enable ‘eldoc-box-hover-at-point-mode’. Similar to
‘eldoc-box-hover-mode’, but displays the childframe at point. (This
mode feels slower comparing to ‘eldoc-box-hover-mode’.)

3. Bind ‘eldoc-box-help-at-point’ to a key and bring up the
documentation childframe on-demand. This command requires Emacs 28
to work.

Customization faces:

- ‘eldoc-box-border’
- ‘eldoc-box-body’

Hooks:

- ‘eldoc-box-buffer-hook’
- ‘eldoc-box-frame-hook’

Customize options:

- ‘eldoc-box-max-pixel-width’
- ‘eldoc-box-max-pixel-height’
- ‘eldoc-box-only-multi-line’
- ‘eldoc-box-cleanup-interval’
- ‘eldoc-box-fringe-use-same-bg’
- ‘eldoc-box-self-insert-command-list’
