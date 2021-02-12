This package provides a tree browser similar to `neotree' or `treemacs'
but leverages `dired' to do the job of display.

(use-package dired-sidebar
  :bind (("C-x C-n" . dired-sidebar-toggle-sidebar))
  :ensure nil
  :commands (dired-sidebar-toggle-sidebar))
