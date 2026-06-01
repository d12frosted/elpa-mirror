This package provides seamless integration with macOS native input methods
without applying any custom patches to Emacs.

It uses a dynamic module to hook into macOS key events, synchronizing
the system IME state with Emacs.  It also automatically deactivates the
IME when you press prefix keys (like C-x) or when Emacs prompts for input
(like `y-or-n-p' or `read-string'), ensuring a smooth editing experience.

Note that this package requires a dynamic module (`mac-ime-module.so`).
On the first activation, it will prompt you and download the module
from GitHub using `curl`.  Please ensure you are online for this step.

To use this package, add the following to your init file:

  (setq default-input-method "mac-ime")
  (mac-ime-enable)
