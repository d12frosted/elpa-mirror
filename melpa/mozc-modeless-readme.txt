mozc-modeless.el provides a modeless Japanese input interface using Mozc.

Usage:
  (require 'mozc-modeless)
  (global-mozc-modeless-mode 1)

By default, you type in alphanumeric mode.  When you want to convert
the preceding romaji to Japanese, press C-j.  This will activate Mozc
conversion mode.  After you confirm the conversion, the mode automatically
returns to alphanumeric input.
