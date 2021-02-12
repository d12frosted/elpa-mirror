This script is based on "traverselisp.el", originally authored by
Thierry Volpiatto.

Put this file in your load-path and load from init script,

  (require 'phi-grep)

then following commands are available:

  - phi-grep-in-file
  - phi-grep-in-directory

phi-grep can also invoked from dired buffers.

  - phi-grep-dired-in-dir-at-point
  - phi-grep-dired-in-file-at-point
  - phi-grep-dired-in-marked-files
  - phi-grep-dired-in-all-files
  - phi-grep-dired-dwim

You can optionally bind some keys.

  (global-set-key (kbd "<f6>") 'phi-grep-in-directory)
