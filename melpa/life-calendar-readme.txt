This package displays a "life in weeks" calendar --- a grid visualization
showing all weeks of a person's life, with past weeks, the current week,
and future weeks visually distinguished.

Usage:
  M-x life-calendar

On first use, you will be prompted to enter your birthday.
The birthday is saved and remembered for future sessions.

Navigation:
  f/b, C-f/C-b, arrows  -- move by week
  n/p, C-n/C-p, up/down -- move by row (multiple years in multi-column view)
  ]/[, M-f/M-b          -- move by year
  M-<, M->              -- first/last week
  C-a, C-e, Home/End    -- beginning/end of row
  .                     -- jump to current week

Life chapters (marking significant dates):
  +                     -- add a life chapter
  -                     -- remove a life chapter from current week

Other:
  g                     -- refresh
  ?                     -- help (show keybindings)
  q                     -- quit

Customization:
  M-x customize-group RET life-calendar RET
