`dirvish' is a minimalistic file manager based on `dired-mode'.  It is
inspired by ranger (see https://github.com/ranger/ranger), which is a
terminal file manager that shows a stack of the parent directories, and
updates its parent buffers while navigating the file system with an optional
preview window at side showing the content of the selected file.

Unlike `ranger.el', which tries to become an all-around emulation of ranger,
dirvish.el is more bare-bone, meaning it does NOT try to port all "goodness"
from ranger, instead, it tries to:

  - provides a better Dired UI
  - make some Dired commands more intuitive
  - keep all your Dired key bindings

The name `dirvish' is a tribute to `vim-dirvish'.
