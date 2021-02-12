Add the following to your Emacs init file:

(require 'helm-git-grep) ;; Not necessary if installed by package.el
(global-set-key (kbd "C-c g") 'helm-git-grep)
;; Invoke `helm-git-grep' from isearch.
(define-key isearch-mode-map (kbd "C-c g") 'helm-git-grep-from-isearch)
;; Invoke `helm-git-grep' from other helm.
(eval-after-load 'helm
  '(define-key helm-map (kbd "C-c g") 'helm-git-grep-from-helm))

For more information, See the following URL:
https://github.com/yasuyk/helm-git-grep

Original version is anything-git-grep, and port to helm.
https://github.com/mechairoi/anything-git-grep
