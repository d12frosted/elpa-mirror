`ligature-pragmatapro' provides pre-baked `ligature'[0] configuration
for the PragmataPro[1] programming font.

Support is configured for all programming modes by calling
`ligature-pragmatapro-setup', then enabling `ligature':

  (ligature-pragmatapro-setup)
  (global-ligature-mode)

To be more selective, just use mode hooks:

  (ligature-pragmatapro-setup)
  (add-hook 'haskell-mode-hook 'ligature-mode)

For even more advanced custom configuration, all PragmataPro
ligatures are available in `ligature-pragmatapro-ligatures' to be
used directly:

  (require 'ligature-pragmatapro)
  (ligature-set-ligatures 'prog-mode ligature-pragmatapro-ligatures)

[0] ligature: https://github.com/mickeynp/ligature.el
[1] PragmataPro: https://fsd.it/shop/fonts/pragmatapro/
