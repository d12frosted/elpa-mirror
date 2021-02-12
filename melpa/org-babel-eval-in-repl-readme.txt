This package allows you to execute org-mode (babel) source code blocks with eval-in-repl.
## Features
- Async execution (because it uses an external process!)
- Babel execution without the output written in the buffer (Less visual distraction! Output is reproducible as long as the code is saved)

## Usage
(with-eval-after-load "ob"
  (require 'org-babel-eval-in-repl)
  (define-key org-mode-map (kbd "C-<return>") 'ober-eval-in-repl)
  (define-key org-mode-map (kbd "C-c C-c") 'ober-eval-block-in-repl))

## Recommended config (optional):
(with-eval-after-load "eval-in-repl"
  (setq eir-jump-after-eval nil))
