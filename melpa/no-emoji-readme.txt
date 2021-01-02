
Run M-x no-emoji-minor-mode to replace all emoji with :emoji-name: in the current buffer.

Run M-x global-no-emoji-minor-mode to replace all emoji with :emoji-name: in all buffers.

You can customize the `no-emoji' face to alter the appearance.

You can adapt the codepoint ranges in `no-emoji-codepoint-ranges' to customize which codepoints will be replaced.

You can redefine `no-emoji-displayable-unicode-name' to change the way the display names are generated.
Do this *before* enabling the minor mode.

This package sets buffer-display-table locally.
