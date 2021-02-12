You can setup this package globally with:

(when (and (executable-find "fish")
           (require 'fish-completion nil t))
  (global-fish-completion-mode))

Alternatively, you can call the `fish-completion-mode' manually or in shell /
Eshell mode hook.

The package `bash-completion' is an optional dependency: if available,
`fish-completion-complete' can be configured to fall back on bash to further
try completing.  See `fish-completion-fallback-on-bash-p'.
