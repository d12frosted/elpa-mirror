After open Kubernetes file, you have to M-x k8s-mode to enable this major
Put # -*- mode: k8s -*- in first line of file, if you want to autoload.

If you're using yas-minor-mode and want to enable on k8s-mode
(add-hook 'k8s-mode-hook #'yas-minor-mode)

With use-package style
(use-package k8s-mode
 :ensure t
 :config
 (setq k8s-search-documentation-browser-function 'browse-url-firefox)
 :hook (k8s-mode . yas-minor-mode))
