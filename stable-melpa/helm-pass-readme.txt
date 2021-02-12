
Emacs Helm interface for pass, the standard Unix password manager

Users of helm-pass may also be interested in functionality provided by other
Emacs packages dealing with pass:

- password-store.el (which helm-pass relies on):
  https://git.zx2c4.com/password-store/tree/contrib/emacs/password-store.el

- pass.el (a major mode for pass): https://github.com/NicolasPetton/pass

- auth-source-pass.el (integration of Emacs' auth-source with pass, included
  in Emacs 26+): https://github.com/DamienCassou/auth-password-store

Usage:

(require 'helm-pass)
M-x helm-pass
