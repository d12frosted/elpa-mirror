
Configurations:
  Basic:
    (require 'helm-perspeen)

  Use `use-package.el':
    (use-package helm-perspeen :ensure t)

Dependencies:
  - perspeen
     - https://github.com/seudut/perspeen/blob/master/perspeen
  - helm
    - https://emacs-helm.github.io/helm/
  - (Optional) helm-projectile
    - https://github.com/bbatsov/helm-projectile

Commands:
  - M-x helm-perspeen

Helm Sources:
  - helm-source-perspeen-tabs
  - helm-source-perspeen-workspaces
  - helm-source-perspeen-create-workspace
