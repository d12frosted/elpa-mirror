This package provides a configurable "fuzzy clock" for Emacs that displays
time in a human-friendly, approximate way, similar to the KDE fuzzy clock widget.

The clock supports adjustable fuzziness levels from precise to very fuzzy:
1. Every 5 minutes - "Quarter past three", "Twenty to four"
2. Every 15 minutes - "Quarter past three", "Half past three", "Quarter to four"
3. Half hour - "Half past three", "Four o'clock"
4. Hour - "Three o'clock", "Four o'clock"
5. Part of day - "Morning", "Afternoon", "Evening", "Night"
6. Day of week - "Monday", "Tuesday", "Wednesday"
7. Part of month - "Early October", "Middle October", "Late October"
8. Month - "January", "October", "December"
9. Part of season - "Early Fall", "Middle Fall", "Late Fall"
10. Part of year - "Early 2025", "Middle 2025", "Late 2025"
11. Year - "2025", "2026"

Usage:

Mode-line display (recommended):
  M-x fuzzy-clock-mode RET
  Enables a global minor mode that displays fuzzy time in the mode-line.
  The display updates automatically every minute (configurable).

Dedicated buffer display:
  M-x fuzzy-clock-display-buffer RET
  Opens a dedicated buffer showing the current fuzzy time.

Minibuffer display:
  M-x fuzzy-clock-show RET
  Shows the current fuzzy time in the minibuffer (one-time display).

Customization:
  M-x customize-group RET fuzzy-clock RET
  - fuzzy-clock-fuzziness: Set the fuzziness level (default: 'hour)
  - fuzzy-clock-update-interval: Set update interval in seconds (default: 60)
