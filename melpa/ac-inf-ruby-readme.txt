Provides an `auto-complete' source for use in `inf-ruby-mode' buffers,
which ties directly into the accurate inf-ruby completions mechanism.

Enable using:

    (require 'ac-inf-ruby) ;; when not installed via package.el
    (eval-after-load 'auto-complete
      '(add-to-list 'ac-modes 'inf-ruby-mode))
    (add-hook 'inf-ruby-mode-hook 'ac-inf-ruby-enable)

Optionally bind auto-complete to TAB in inf-ruby buffers:
    (eval-after-load 'inf-ruby '
      '(define-key inf-ruby-mode-map (kbd "TAB") 'auto-complete))
