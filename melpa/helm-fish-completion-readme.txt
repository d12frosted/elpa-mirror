
You can invoke Helm Fish completion with the ~helm-fish-completion~ command.

To replace completion in Eshell and =M-x shell=, simply rebind the TAB key:

(when (require 'helm-fish-completion nil 'noerror)
  (define-key shell-mode-map (kbd "<tab>") 'helm-fish-completion)
  (setq helm-esh-pcomplete-build-source-fn #'helm-fish-completion-make-eshell-source))

`fish-completion-mode' must be disabled.
