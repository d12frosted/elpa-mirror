This package extends Eglot to enable inactive code regions
detection and shading.

LSP servers provide information about currently disabled
preprocessor branches with knowledge about build-time options and
defines.

This mode provides visual feedback to quickly identify these disabled
code regions.  Supports three visualization styles:
 - `shadow-face' applies shadow face from current theme
 - `shade-background' makes the background slightly lighter or darker
 - `darken-foreground' dims foreground colors

Currently supported servers:
 - `clangd' with inactiveRegions extension (needs clangd-17+)
 - `ccls' with skippedRegions extension