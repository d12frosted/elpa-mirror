
  This package makes HOME/END keys smartly cycle to the beginning/end
  of a line, the beginning/end of the window, the beginning/end of
  the buffer, and back to POINT. With a prefix argument, behaves as
  functions `beginning-of-buffer'/`end-of-buffer'.

  A first keypress moves POINT to the beginning/end of a line, or if
  already there, to the beginning/end of the window, or if already
  there, to the beginning/end of the buffer. Subsequent keypresses
  cycle through those operations until returning POINT to its start
  position. Invoking a PREFIX ARGUMENT prior to the keypress moves
  POINT consistent with PREFIX ARG M-x beginning-of-buffer /
  end-of-buffer.

  Usage example:

    (global-set-key [home] 'home-end-home)
    (global-set-key [end]  'home-end-end)

  Note that some devices may define the HOME and END keys
  differently. For example, we have seen the END key defined as
  'select'.
