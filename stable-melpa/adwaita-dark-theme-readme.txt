
adwaita-dark is a dark color scheme that aims to replicate the
appearance and colors of GTK4 "libadwaita" applications.

Features offered:
* Beautiful dark color scheme inspired by Adwaita
* Automatic 256-color mode support
* Custom configurations for neotree and eldoc-frame
* Custom fringe bitmaps for line continuations, visual-line-mode, diff-hl, flycheck, and flymake
* Lightweight with no dependencies

To replace default line continuation/line wrap fringe bitmaps:
(adwaita-dark-theme-arrow-fringe-bmp-enable)

To enable custom configuration for `neotree':
(eval-after-load 'neotree #'adwaita-dark-theme-neotree-configuration-enable)

To enable custom configuration for `eldoc-frame':
(eval-after-load 'eldoc-frame #'adwaita-dark-theme-eldoc-frame-configuration-enable)

To enable custom fringe bitmaps for `diff-hl':
(eval-after-load 'diff-hl #'adwaita-dark-theme-diff-hl-fringe-bmp-enable)

To enable custom fringe bitmaps for `flycheck':
(eval-after-load 'flycheck #'adwaita-dark-theme-flycheck-fringe-bmp-enable)

To enable custom fringe bitmaps for `flymake':
(eval-after-load 'flymake #'adwaita-dark-theme-flymake-fringe-bmp-enable)
