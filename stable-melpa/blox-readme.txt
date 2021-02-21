blox provides functions to run Roblox tooling such as Rojo (see
https://github.com/rojo-rbx/rojo) from Emacs.

blox doesn't bind any keys by itself; assuming `lua-mode' is
installed and loaded, a configuration might look something like
this:

(require 'blox)

(define-key lua-prefix-mode-map (kbd "s") #'blox-prompt-serve)
(define-key lua-prefix-mode-map (kbd "b") #'blox-prompt-build)
(define-key lua-prefix-mode-map (kbd "t") #'blox-test)

Or with `use-package':

(use-package blox
  :bind (:map lua-prefix-mode-map
              ("s" . blox-prompt-serve)
              ("b" . blox-prompt-build)
              ("t" . blox-test)))
