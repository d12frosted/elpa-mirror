The package provides two interactive functions:
regswap-mark-region and regswap-cancel

If no region for swapping is defined,
regswap-mark-region defines it as current region.
If swap region is defined, regswap-mark-region swaps contents
of swap region and region and undefine swap region.

Either of current region and swap region can be empty.
In this case content of non-empty region is moved to position of empty.

If swap region and region are intersecting, no changes are made to buffer.

When regswap-highlight is non-nil,
swap region is highlighted with regswap-reg-face, when non-empty.
When swap region is empty, it's position is heighlighted by displaying
║ character in position of swap region, heighlighted with regswap-empty-face.
regswap-highlight value is t by default.

regswap-cancel undefines swap region and removes highlighting overlay.

If changes are made to the buffer, when swap region is defined:
- If changed area overlaps with swap region, swapping is cancelled
- If changes are inside of the swap region,
swap region is changed accordingly, modified text will be swapped.
- If changes are done before the swap region,
swap region is shifted by length difference of changed text.
- insertions at the borders of the swap region are treated as outside of
swap region (not modifying text for swapping)

Keybindings suggested by the package are "C-x w w" for regswap-mark-region
and "C-x w c" for regswap-cancel.
These keybindings can be set by placing (regswap-setup-default-keybindings)
in Emacs init script.

For setting other keybindings place
(global-set-key (kbd "xxx") 'regswap-mark-region)
(global-set-key (kbd "yyy") 'regswap-cancel)
where "xxx" and "yyy" are keybindings of your choice.
