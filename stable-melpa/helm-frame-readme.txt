to configure, (require 'helm-frame) and add lines like these to your init:

  (add-hook 'helm-after-action-hook 'helm-frame-delete)
  (add-hook 'helm-cleanup-hook 'helm-frame-delete)
  (setq helm-split-window-preferred-function 'helm-frame-window)
