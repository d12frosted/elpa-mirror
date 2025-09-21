
double-press.el lets you bind two actions to the same key by timing:
a single press vs a quick double-press - no mode switch required.

Quick start:

  (require 'double-press)
  ;; Keep copy on M-w; open a small window prefix on M-w M-w
  (define-prefix-command 'my-window-map)
  (define-key my-window-map (kbd "s") 'split-window-below)
  (define-key my-window-map (kbd "v") 'split-window-right)
  (double-press-define-key global-map (kbd "M-w")
    :on-single-press 'copy-region-as-kill
    :on-double-press 'my-window-map)

Customization:
  - double-press-timeout              ;; maximum interval between presses (seconds)
  - double-press-use-prompt           ;; show a prompt when reading from a prefix map
  - double-press-use-where-is-helper  ;; keep `where-is' hints in sync (opt-in)
  - Press C-h/<f1> inside a double-press prefix to see its bindings.

See also: README.md (overview, setup) and docs/EXAMPLES.md (snippets).
