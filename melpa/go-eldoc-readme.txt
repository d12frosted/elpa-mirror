`go-eldoc.el' provides eldoc for Go language. `go-eldoc.el' shows type information
for variable, functions and current argument position of function.

To use this package, add these lines to your init.el file:

    (require 'go-eldoc)
    (add-hook 'go-mode-hook 'go-eldoc-setup)
