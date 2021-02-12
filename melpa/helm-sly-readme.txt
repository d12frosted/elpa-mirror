
A Helm for using SLY.

The complete command list:

 `helm-sly-list-connections'
   Yet another Lisp connection list with `helm'.
 `helm-sly-apropos'
   Yet another `apropos' with `helm'.
 `helm-sly-mini'
   Like ~helm-sly-list-connections~, but include an extra source of
   Lisp-related buffers, like the events buffer or the scratch buffer.

; Installation:

Add helm-sly.el to your load-path.
Set up SLY properly.

To use Helm instead of the Xref buffer, enable `global-helm-sly-mode'.

To enable Helm for completion, two options:

- Without company:

  (add-hook 'sly-mrepl-hook #'helm-sly-disable-internal-completion)

  If you want fuzzy-matching:

  (setq helm-completion-in-region-fuzzy-match t)


- With company, install helm-company
  (https://github.com/Sodel-the-Vociferous/helm-company), then:

  (add-hook 'sly-mrepl-hook #'company-mode)
  (require 'helm-company)
  (define-key sly-mrepl-mode-map (kbd "<tab>") 'helm-company)
