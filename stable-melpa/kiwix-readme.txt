This currently only works for GNU/Linux, not tested for Mac OS X and Windows.

;; Kiwix installation

https://repo.or.cz/kiwix.el.git/README.org#install

;; Config:

(use-package kiwix
  :ensure t
  :after org
  :commands (kiwix-launch-server kiwix-at-point kiwix-search-at-library kiwix-search-full-context)
  :bind (:map document-prefix ("w" . kiwix-at-point))
  :custom ((kiwix-server-type 'docker-remote)
           (kiwix-server-url "http://192.168.31.251")
           (kiwix-server-port 8089))
  :hook (org-load . org-kiwix-setup-link)
  :init (require 'org-kiwix)
  :config (add-hook 'org-load-hook #'org-kiwix-setup-link))

;; Usage:

1. [M-x kiwix-launch-server] to launch Kiwix server.
2. [M-x kiwix-at-point] to search the word under point or the region selected string.
