countdown-modeline displays the soonest upcoming event from
`countdown-modeline-events' as a day countdown in the Emacs modeline.
Past events are skipped automatically, and the countdown refreshes at
local midnight via an internal timer (no external setup required).

Anniversaries (birthdays, wedding anniversaries, memorial dates,
etc.) are recurring events: the countdown advances to the next
annual occurrence rather than expiring.  An anniversary's stored
date may be a full YYYY-MM-DD (preserving the original year, e.g.
a birth year) or a yearless MM-DD.

Events may also be read from Org files.  When
`countdown-modeline-org-enabled' is non-nil, headlines matching
`countdown-modeline-org-match' (by default those tagged :countdown:)
are scanned out of the Org agenda files and merged into the event
list.  Org events are derived, not owned: they are never written to
`countdown-modeline-events-file', and are refreshed with
`countdown-modeline-org-refresh'.

The text color changes as the event approaches:

  - Green  : 10+ days remaining
  - Yellow : 5-9 days remaining
  - Red    : fewer than 5 days remaining

Usage:

  (require 'countdown-modeline)
  (setq countdown-modeline-events
        '(("Launch Day" "2026-12-25" "🚀")
          ("Vacation"   "2026-07-01" "🏖️")
          ("Standup"    "2026-05-10")            ; emoji is optional
          ("Mom's Birthday" "1955-06-15" "🎂" t) ; t = anniversary
          ("Wedding"        "06-15"      "💍" t)))
  (setq countdown-modeline-org-enabled t)        ; optional Org source
  (countdown-modeline-mode 1)

Run M-x countdown-modeline-list-events to discover the available
commands.  Works with doom-modeline and the default modeline.
