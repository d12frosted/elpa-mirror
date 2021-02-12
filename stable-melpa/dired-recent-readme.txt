A simple history keeping for dired buffers.  All the visited
directories get saved for reuse later.  Works great with Ivy and
other `completing-read' replacements.

 HOW TO USE IT:

  (require 'dired-recent)
  (dired-recent-mode 1)

 C-x C-d (`dired-recent-open')
