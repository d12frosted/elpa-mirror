Provides a sidebar interface similar to `dired-sidebar', but for `ibuffer'.


(use-package ibuffer-sidebar
  :bind (("C-x C-b" . ibuffer-sidebar-toggle-sidebar))
  :ensure nil
  :commands (ibuffer-sidebar-toggle-sidebar))
