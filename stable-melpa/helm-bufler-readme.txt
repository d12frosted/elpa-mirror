This file provides a source for Helm commands that shows buffers in
the frame's current Bufler workspace and allows them to be acted
upon using Helm's existing buffer actions list.  You could add it
to an existing Helm command, or use it like this:

  (helm :sources '(helm-bufler-source))
