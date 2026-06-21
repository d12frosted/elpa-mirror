mozc-modeless.el provides a modeless Japanese input interface using Mozc.

Usage:
  (require 'mozc-modeless)
  (global-mozc-modeless-mode 1)

By default, you type in alphanumeric mode.  When you want to convert
the preceding romaji to Japanese, press C-j.  The first candidate is
committed immediately and you stay in alphanumeric input (no candidate
window is shown).  If the first candidate is not what you wanted, press
C-j again on the just-converted text to reopen Mozc's candidate window
and select another candidate.  Text converted by mozc-modeless remembers
its reading (stored as a text property), so any such text can be
reconverted later in the same way, as long as the property is in memory.
