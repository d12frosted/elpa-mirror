
Someone like to reuse the current dired buffer to visit
another directory, so that you just need open one dired
buffer. but the bad point is ,you can't  easily go
forward and back in different dired directory. this file
can remember dired directory you have visited and list them
using `helm.el'.

integrating dired history feature into commands like
dired-do-copy and dired-do-rename. What I think of is that when
user press C (copy) or R (rename) mode, it is excellent to have
an option allowing users to select a directory from the history
list.

after integrated the initial-input of `dired' `dired-other-window'
and `dired-other-frame' are changed from default-directory to empty,
and the first element of history is default-directory,so you can
just press `RET' or `C-j' to select it.



; Installation:

(require 'savehist)
(add-to-list 'savehist-additional-variables 'helm-dired-history-variable)
(savehist-mode 1)

(with-eval-after-load 'dired
  (require 'helm-dired-history)
;; if you are using ido,you'd better disable ido for dired
;; (define-key (cdr ido-minor-mode-map-entry) [remap dired] nil) ;in ido-setup-hook
  (define-key dired-mode-map "," 'dired))
or
(with-eval-after-load 'dired
  (require 'helm-dired-history)
  (define-key dired-mode-map "," 'dired))
