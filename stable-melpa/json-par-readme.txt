Minor mode for structural editing of JSON, inspired by lispy.

Features:

- Ctrl-less, yet modeless:
  If the point is not in a string, each key is interpreted as a command like
  the vi editor.  If the point is in a string, keys are inserted as is.

- Structural movement:
  Moving to the next/previous member, parents, and others.

- dabbrev-like completion:
  Press `?' to insert a guessed value or key at the point.

- Converting single-line to/from multiline:
  [ 1, 2, 3 ]

  to/from

  [
    1,
    2,
    3
  ]

- Cloning members:
  Clone the current/parent/ancestor member with or without values.

- Marking/deleting various things:
  Mark or delete the current value, current member, parent, siblings, and
  others.

- And More!
