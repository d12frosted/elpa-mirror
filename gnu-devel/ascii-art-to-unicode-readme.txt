The command ‘aa2u’ converts simple ASCII art line drawings in
the {active,accessible} region of the current buffer to Unicode.
Command ‘aa2u-rectangle’ is like ‘aa2u’, but works on rectangles.

Example use case:
- M-x artist-mode RET
- C-c C-a r               ; artist-select-op-rectangle
- (draw two rectangles)

  +---------------+
  |               |
  |       +-------+--+
  |       |       |  |
  |       |       |  |
  |       |       |  |
  +-------+-------+  |
          |          |
          |          |
          |          |
          +----------+

- C-c C-c                 ; artist-mode-off (optional)
- C-x n n                 ; narrow-to-region
- M-x aa2u RET

  ┌───────────────┐
  │               │
  │       ┌───────┼──┐
  │       │       │  │
  │       │       │  │
  │       │       │  │
  └───────┼───────┘  │
          │          │
          │          │
          │          │
          └──────────┘

Much easier on the eyes now!

Normally, lines are drawn with the ‘LIGHT’ weight.  If you set var
‘aa2u-uniform-weight’ to symbol ‘HEAVY’, you will see, instead:

  ┏━━━━━━━━━━━━━━━┓
  ┃               ┃
  ┃       ┏━━━━━━━╋━━┓
  ┃       ┃       ┃  ┃
  ┃       ┃       ┃  ┃
  ┃       ┃       ┃  ┃
  ┗━━━━━━━╋━━━━━━━┛  ┃
          ┃          ┃
          ┃          ┃
          ┃          ┃
          ┗━━━━━━━━━━┛

To protect particular ‘|’, ‘-’ or ‘+’ characters from conversion,
you can set the property ‘aa2u-text’ on that text with command
‘aa2u-mark-as-text’.  A prefix arg clears the property, instead.
(You can use ‘describe-text-properties’ to check.)  For example:

     ┌───────────────────┐
     │                   │
     │ |\/|              │
     │ ‘Oo’   --Oop Ack! │
     │  ^&-MM.           │
     │                   │
     └─────────┬─────────┘
               │
           """""""""

Command ‘aa2u-mark-rectangle-as-text’ is similar, for rectangles.

Tip: For best results, you should make sure all the tab characters
are converted to spaces.  See: ‘untabify’, ‘indent-tabs-mode’.