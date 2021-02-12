Allows switching between themes easily.

; Installation

In your Emacs config, define a list of themes you want to be
able to switch between.  Then, enable the global minor mode.

    (setq cycle-themes-theme-list
          '(leuven monokai solarized-dark))
    (require 'cycle-themes)
    (cycle-themes-mode)

`cycle-themes' is bound to 'C-c C-t' by default.

You can optionally add hooks to be run after switching themes:

(add-hook 'cycle-themes-after-cycle-hook
          #'(lambda () (Do-something-fn ...)))
