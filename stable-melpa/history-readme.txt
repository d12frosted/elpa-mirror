
This tool is similar to `pop-global-mark' but more powerful. You can go
through the whole history without losing them. Actually, `pop-global-mark'
will use the latest record but also discard it. But this tool will preserve
all the history and smartly ignored killed buffers or invalid symbol string.

You'll feel the power and convenience of using `history-add-history',
`history-prev-history' and `history-next-history' instead of built-in old way.

Basic Concept
-------------
* Normal history database:
  (1) - (2) - (3) - (4) - (5)
                           ^ index
* Goto previous Nth history:
  (1) - (2) - (3) - (4) - (5)
               ^ index
* Add a new history into the database:
  (1) - (2) - (3) - (6)
                     ^ index, histories behind index will be discard, and new
                       one will be appended to the end.

Usage
-----
* M-x `history-mode'
  Add menu items and tool-bar items of history utility.
* (`history-add-history')
  Save current point and buffer as a history into the database.
* (`history-add-history' t)
  Like above, but also save symbol string at point. When navigating to the
  history, the tool compare the matched string so that it make sure the
  history is VALID.
* M-x `history-prev-history'
  Goto previous history.
* M-x `history-next-history'
  Goto new history.
* M-x `history-kill-histories'
  Discard whole history database.

Advanced Usage
--------------
* M-x `history-configuration'
  Add history for you automatically for specific functions!!!

Customization
-------------
* `history-history-max'
  The maximum length of the history database.
* `history-ignore-buffer-names'
  A REGEXP list to ignore specific buffers.
* `history-window-local-history'
  A boolean indicates the history is whether local to window or global to
  all buffers.
* `history-advised-after-functions' and `history-advised-after-functions'
  A functions list to be advised to call `history-add-history'.

TODO:
-----
n/a

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
