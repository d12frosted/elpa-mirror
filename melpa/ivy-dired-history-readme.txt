
use `ivy' to open recent directories.

it is integrated with `dired-do-copy' and `dired-do-rename'.
when you press C (copy) or R (rename) , it is excellent to
allow users to select a directory from the recent dired history .



; Installation:

(require 'savehist)
(add-to-list 'savehist-additional-variables 'ivy-dired-history-variable)
(savehist-mode 1)

or if you use desktop-save-mode
(add-to-list 'desktop-globals-to-save 'ivy-dired-history-variable)


(with-eval-after-load 'dired
  (require 'ivy-dired-history)
;; if you are using ido,you'd better disable ido for dired
;; (define-key (cdr ido-minor-mode-map-entry) [remap dired] nil) ;in ido-setup-hook
  (define-key dired-mode-map "," 'dired))
