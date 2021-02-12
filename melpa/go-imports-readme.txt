
Add something like below to `~/.emacs`:

(add-hook 'go-mode-hook
          #'(lambda()
              (require 'go-imports)
	          (define-key go-mode-map "\C-cI" 'go-imports-insert-import)
	          (define-key go-mode-map "\C-cR" go-imports-reload-packages-list)))

Say you have github.com/stretchr/testify/require in your GOPATH, and you want
to use this package in your go file.  Invoking

(go-imports-insert-import "require")

will insert the import line

import (
  "github.com/stretchr/testify/require"
)

in the file.  If invoked interactively, it will insert an import for the
symbol at point.

The mappings from the package name (e.g., "require") to thus package path
(e.g., "github.com/stretchr/testify/require") is discovered by scanning all
the *.go files under GOROOT and GOPATH when the go-imports-insert-import is
first called.

Calling go-imports-reload-packages-list will reload the package-name
mappings.
