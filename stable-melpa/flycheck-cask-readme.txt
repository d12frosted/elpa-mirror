Add Cask support for Flycheck.

Configure Flycheck to initialize packages from Cask in Cask projects.

;; Setup

(add-hook 'flycheck-mode-hook #'flycheck-cask-setup)
