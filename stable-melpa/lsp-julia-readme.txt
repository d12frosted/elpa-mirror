This version of lsp-julia requires julia 1.3 to run.
Manual installation:

(require 'julia-mode)
(push "/path/to/lsp-julia" load-path)
(require 'lsp-julia)
(require 'lsp-mode)
;; Configure lsp + julia
(add-hook 'julia-mode-hook #'lsp-mode)
(add-hook 'julia-mode-hook #'lsp)
