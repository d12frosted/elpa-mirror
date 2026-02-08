auto-space-mode automatically adds spaces between CJK characters
(Chinese, Japanese, Korean) and ASCII words during input.  This behavior
ONLY occurs during input and does NOT modify other parts of your document.

To use auto-space-mode, add the following to your init file:

  (require 'auto-space-mode)
  (auto-space-mode 1)

The package provides two additional commands for working with regions:

- `auto-space-add-in-region': Add spaces between CJK and ASCII in region
- `auto-space-remove-in-region': Remove spaces between CJK and ASCII in region

The difference between auto-space-mode and pangu-spacing:

1. auto-space-mode ONLY adds spaces during input; it does NOT modify
   other parts of your document.
2. auto-space-mode adds ACTUAL spaces instead of using overlays.
3. You can FREELY add or remove those spaces.
