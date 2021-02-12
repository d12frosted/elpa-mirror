`helm-gtags.el' is a `helm' interface of GNU Global.
`helm-gtags.el' is not compatible `anything-gtags.el', but `helm-gtags.el'
is designed for fast search.


To use this package, add these lines to your init.el or .emacs file:

    ;; Enable helm-gtags-mode
    (add-hook 'c-mode-hook 'helm-gtags-mode)
    (add-hook 'c++-mode-hook 'helm-gtags-mode)
    (add-hook 'asm-mode-hook 'helm-gtags-mode)

    ;; Set key bindings
    (eval-after-load "helm-gtags"
      '(progn
         (define-key helm-gtags-mode-map (kbd "M-t") 'helm-gtags-find-tag)
         (define-key helm-gtags-mode-map (kbd "M-r") 'helm-gtags-find-rtag)
         (define-key helm-gtags-mode-map (kbd "M-s") 'helm-gtags-find-symbol)
         (define-key helm-gtags-mode-map (kbd "M-g M-p") 'helm-gtags-parse-file)
         (define-key helm-gtags-mode-map (kbd "C-c <") 'helm-gtags-previous-history)
         (define-key helm-gtags-mode-map (kbd "C-c >") 'helm-gtags-next-history)
         (define-key helm-gtags-mode-map (kbd "M-,") 'helm-gtags-pop-stack)))
