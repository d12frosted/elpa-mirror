This package provides the helm interface for smex.

Example config:

  (require 'helm-smex)
  (global-set-key [remap execute-extended-command] #'helm-smex)
  (global-set-key (kbd "M-X") #'helm-smex-major-mode-commands)
