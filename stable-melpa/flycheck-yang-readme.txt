This package configures provides YANG syntax checking via flycheck
in Emacs using the pyang YANG parser[1].

[1] https://github.com/mbj4668/pyang

;; Setup

Add this to your Emacs configuration:

  ;; autoload yang-mode for .yang files
  (autoload 'yang-mode "yang-mode" "Major mode for editing YANG modules." t)
  (add-to-list 'auto-mode-alist '("\\.yang\\'" . yang-mode))

  ;; enable the YANG checker after flycheck loads
  (eval-after-load 'flycheck '(require 'flycheck-yang))

  ;; ensure flycheck-mode is enabled in yang mode
  (add-hook 'yang-mode-hook
    (lambda () (flycheck-mode)))
