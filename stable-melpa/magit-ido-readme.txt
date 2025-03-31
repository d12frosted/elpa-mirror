This package adds support for using Ido in Magit.  For the most part
it was extracted from code that was previously part of Magit itself.

To enable Ido support, you need to add something like this to your
init file:

(with-eval-after-load 'magit
  (require 'magit-ido)
  (setq magit-completing-read-function
        'magit-ido-completing-read)
  ;; Optional:
  (keymap-set ido-common-completion-map
              "C-x g" 'magit-ido-enter-magit-status))
