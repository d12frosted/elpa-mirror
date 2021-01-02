; To enable lsp-p4 include the following lisp code in init.el after
; loading lsp-mode
;
;    (with-eval-after-load 'lsp-mode
;      (require 'p4lang-mode)
;      (require 'lsp-p4)
;      (add-hook 'p4lang-mode-hook #'lsp)
;
; See `lsp-clients-p4lsd-executable' to customize the path to p4lsd.
