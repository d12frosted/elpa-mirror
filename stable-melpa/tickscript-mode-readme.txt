Copyright Marc Sherry <msherry@gmail.com>

Provides Emacs font-lock, indentation, navigation, and utility functions for
working with TICKscript (https://docs.influxdata.com/kapacitor/v1.3/tick/),
a DSL for use with Kapacitor and InfluxDB.

Installation:

Available on MELPA (https://melpa.org/) and MELPA Stable
(https://stable.melpa.org/) -- installation from there is easiest:

`M-x package-install tickscript-mode'

Alternately, add the following to your .init.el:

    (add-to-list 'load-path "path-to-tickscript-mode")
    (require 'tickscript-mode)

Usage:

In addition to syntax highlighting and indentation support,
`tickscript-mode' provides a number of utility functions for working
directly with Kapacitor:

* `C-c C-c' -- `tickscript-define-task'

  Send the current task to Kapacitor via `kapacitor define'.

* `C-c C-v' -- `tickscript-show-task'

  View the current task's definition with `kapacitor show <task>'.  This
  will also render the DOT output inline, for easier visualization of the
  nodes involved.

* `C-c C-l p' -- `tickscript-list-replays'

* `C-c C-l r' -- `tickscript-list-recordings'

* `C-c C-l t' -- `tickscript-list-tasks'

  Query Kapacitor for information about the specified objects.


Support is also provided for looking up node and property definitions:

* `C-c C-d' -- `tickscript-get-help'

  Look up the node, and possibly property, currently under point online.
