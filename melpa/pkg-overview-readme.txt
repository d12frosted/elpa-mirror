
This package parses an elisp file's comments, definitions,
docstrings, and other documentation into a hierarchical `org-mode'
buffer. It is intended to facilitate familiarization with a file's
contents and organization / structure. The viewer can quickly swoop
in and out and across the file structure using standard `org-mode'
commands and keybindings.


; Dependencies (all are already part of Emacs):

  org -- for `org-mode'


; Installation:

1) Evaluate or load this file.

2) I don't expect anyone who would want to define a global
   keybinding for this kind of function needs me to tell them how
   do so, but I'm mindlessly filling out my own template, so:

     (global-set-key (kbd "S-M-C F1 M-x butterfly C-c C-h ?") 'pkg-overview)

