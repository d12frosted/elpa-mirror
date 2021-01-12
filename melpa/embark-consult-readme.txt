This package provides integration between Embark and Consult.

For now, it only provides access to Consult preview from
auto-updating Embark Collect buffer that is associated to an active
minibuffer for a Consult command:

- `embark-consult-preview-at-point', a command to trigger Consult's
preview for the entry at point.

- `embark-consult-preview-minor-mode', a minor mode for Embark
Collect buffers that automatically previous the entry at point as
you move around.

Eventually all Consult-related functionality in Embark will be
moved to this package.
