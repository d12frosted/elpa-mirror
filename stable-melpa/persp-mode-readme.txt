Based on the perspective.el by Natalie Weizenbaum
 (http://github.com/nex3/perspective-el) but the perspectives are shared
  among the frames and could be saved/restored from/to a file.

Homepage: https://github.com/Bad-ptr/persp-mode.el

Installation:

From the MELPA: M-x package-install RET persp-mode RET
From a file: M-x package-install-file RET 'path to this file' RET
Or put this file into your load-path.

Configuration:

When installed through the package-install:
(with-eval-after-load "persp-mode-autoloads"
  (setq wg-morph-on nil)
  ;; switch off the animation of restoring window configuration
  (setq persp-autokill-buffer-on-remove 'kill-weak)
  (add-hook 'after-init-hook #'(lambda () (persp-mode 1))))

When installed without generating an autoloads file:
(with-eval-after-load "persp-mode"
  ;; .. all settings you want here
  (add-hook 'after-init-hook #'(lambda () (persp-mode 1))))
(require 'persp-mode)

Dependencies:

The ability to save/restore window configurations from/to a file
 depends on the workgroups.el(https://github.com/tlh/workgroups.el)
  for the emacs versions < 24.4

Customization:

M-x: customize-group RET persp-mode RET

You can read more in README.md
