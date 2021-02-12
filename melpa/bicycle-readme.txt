This package provides commands for cycling the visibility of
outline sections and code blocks.  These commands are intended to
be bound in `outline-minor-mode-map' and do most of the work using
functions provided by the `outline' package.

This package is named `bicycle' because it can additionally make
use of the `hideshow' package.

If `hs-minor-mode' is enabled and point is at the start of a code
block, then `hs-toggle-hiding' is used instead of some `outline'
function.  When you later cycle the visibility of a section that
contains code blocks (which is done using `outline' functions),
then code block that have been hidden using `hs-toggle-hiding',
are *not* extended.

A reasonable configuration could be:

  (use-package bicycle
    :after outline
    :bind (:map outline-minor-mode-map
                ([C-tab] . bicycle-cycle)
                ([S-tab] . bicycle-cycle-global)))

  (use-package prog-mode
    :config
    (add-hook 'prog-mode-hook 'outline-minor-mode)
    (add-hook 'prog-mode-hook 'hs-minor-mode))
