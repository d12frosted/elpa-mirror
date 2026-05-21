This package provides commands for cycling preset window layouts
and rotating buffers across windows, inspired by tmux.

Main entry points:

  M-x rotate-layout  -- cycle through layouts in `rotate-functions'.
  M-x rotate-window  -- rotate buffers across the current windows.

Layout commands:

  `rotate-even-horizontal'  -- spread evenly left to right.
  `rotate-even-vertical'    -- spread evenly top to bottom.
  `rotate-main-horizontal'  -- one main window on top, others below.
  `rotate-main-vertical'    -- one main window on the left, others right.
  `rotate-tiled'            -- arrange in a tiled grid.
